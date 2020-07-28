//
//  DataSource.swift
//  TestTests
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import XCTest
@testable import ConfigableCollectionView

// MARK: - ItemData
class ItemDataTests: XCTestCase {
	override class func setUp() {
		ConfigableCollectionView.isUnitTesting = true
	}
	
	func test_ItemData() throws {
		typealias Module = CollectionView<Any, Any>
		do {
			let words = "abcdefghijklmnopqrstuvwxyz".map {
				String($0)
			}
			let item1 = Module.ItemData("1")
			XCTAssert(item1.tryBase() == "1")
			item1.subItems.append(contentsOf: words.map {
				.init($0)
			})
			let item2 = Module.ItemData("2")
			let item3 = Module.ItemData("3")
			item1.subItems.append(item2)
			item2.subItems.append(item3)
			XCTAssertTrue(item1.allItems() == ["1"] + words + ["2", "3"])
			XCTAssertTrue(item1.contains("v"))
			XCTAssertTrue(item1.contains("1"))
			XCTAssertTrue(item1.contains("2"))
			XCTAssertTrue(item1.contains("3"))
			item1.removeAllSubItems("2")
			XCTAssertFalse(item1.contains("2"))
			XCTAssertFalse(item1.contains("3"))
		}
		do {
			let words = "abcdefghijklmnopqrstuvwxyz".map {
				String($0)
			}
			let item1 = Module.ItemData(Module.AnyHashable.package("1"))
			XCTAssert(item1.tryBase() == "1")
			item1.subItems.append(contentsOf: words.map {
				.init(Module.AnyHashable.package($0))
			})
			let item2 = Module.ItemData(Module.AnyHashable.package("2"))
			let item3 = Module.ItemData(Module.AnyHashable.package("3"))
			item1.subItems.append(item2)
			item2.subItems.append(item3)
			XCTAssertTrue(item1.allItems() == (["1"] + words + ["2", "3"]).map {
				Module.AnyHashable.package($0)
			})
			XCTAssertTrue(item1.contains("v"))
			XCTAssertTrue(item1.contains("1"))
			XCTAssertTrue(item1.contains("2"))
			XCTAssertTrue(item1.contains("3"))
			item1.removeAllSubItems("2")
			XCTAssertFalse(item1.contains("2"))
			XCTAssertFalse(item1.contains("3"))
		}
	}
}
// MARK: - SectionData
class SectionDataTests: XCTestCase {
	func test_SectionData() throws {
		typealias Module = CollectionView<Any, Any>
		let items = [1, 2, 3]
		let section1 = Module.SectionData(sectionIdentifier: "1", items: items.map {
			.init($0)
		})
		let section2 = Module.SectionData<String>(anySectionIdentifier: .package("1"))
		XCTAssertTrue((section1.section() as String) == section2.section())
		XCTAssertTrue((section1.section() as String) == section2.trySection())
		XCTAssertTrue(section1.items.map {
			$0.base
		} == items)
		let section3 = Module.SectionData<String>(sectionIdentifier: Module.AnyHashable.package("1"))
		let _: Module.AnyHashable = section3.section()
		let trySection: Module.AnyHashable? = section3.trySection()
		XCTAssertNil(trySection)
	}
}

// MARK: - DataSourceBase
class DataSourceBaseTests: XCTestCase {
	func test_DataSourceBase() throws {
		typealias Module = CollectionView<Any, Any>
		let collectionView = Module(layout: UICollectionViewFlowLayout())
		let datasource = Module.BaseDataSource<Module.AnyHashable, Module.AnyHashable>(collectionView: collectionView)
		let sectionCount = (1..<100).randomElement() ?? 3
		let itemCount = (1..<100).randomElement() ?? 7
		for index in 0..<sectionCount {
			collectionView.dataManager.applyItems(Array(repeating: "item\(UUID())", count: itemCount), updatedSection: "section\(index)")
		}
		
		XCTAssertEqual(datasource.sections.count, sectionCount)
		XCTAssertEqual(datasource.numberOfSections(in: collectionView), sectionCount)
		
		XCTAssertEqual(datasource.sections[0].items.count, itemCount)
		XCTAssertEqual(datasource.collectionView(collectionView, numberOfItemsInSection: 0), itemCount)
	}
}

// MARK: - AnyHashable
class AnyHashableTests: XCTestCase {
	func test_AnyHashable() throws {
		typealias Module = CollectionView<Any, Any>
		let any = Module.AnyHashable.package(123)
		
		XCTAssertTrue(any == 123)
		XCTAssertTrue(Module.AnyHashable.package(any) == any)
		
		XCTAssertFalse(any == 234)
		XCTAssertFalse(any == UInt(123))
		XCTAssertFalse(Module.AnyHashable.package(234) == any)
	}
}
