//
//  DataManager_SectionType_ItemType_Hashable.swift
//  TestTests
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import XCTest
@testable import ConfigableCollectionView

private typealias CType = CollectionView<Int, String>
private var collectionView: CType!

private typealias ItemType = String
private var manager: CType.DataManager<Int, ItemType> {
	collectionView.dataManager
}

private typealias SectionType = CType.SectionData<ItemType>
private var sections = [SectionType]()

class DataManager_SectionType_ItemType_Hashable: XCTestCase {
	override class func setUp() {
		ConfigableCollectionView.isUnitTesting = true
	}
	
	func exclusiveDiffTest() {
		XCTAssert(manager.diffableDataSource == manager.diffDataSource)
	}
	func exclusiveBaseTest() {
		
	}
	
	func exclusiveCollectionViewRegisterTest() {
		manager.deleteAllItems()
		// MARK: - register
		collectionView.register(
			view: {
				UILabel()
			},
			.config {
				$0.view.text = $0.data
			},
			.tap {
				$0.view.backgroundColor = .red
			},
			.when {
				$0.data == "a"
			},
			.flowLayoutSize { _ in
				CGSize(width: 10, height: 10)
			},
			.willDisplay {
				$0.view.backgroundColor = .gray
			},
			.didEndDisplay {
				$0.view.backgroundColor = .clear
			}
		)
		
		collectionView.register(
			view: {
				UILabel()
			},
			.config(map: {
				$0 + "abc"
			}) {
				XCTAssert($0.data == "babc")
				$0.view.text = $0.data
			},
			.when {
				$0.data == "b"
			}
		)
		let notCollectionViewCell = (876876..<9767318269132).randomElement()!
		collectionView.register(
			view: {
				UICollectionViewCell()
			},
			.config(compactMap: {
				Int($0)
			}) {
				XCTAssert($0.data == notCollectionViewCell)
				$0.view.tag = $0.data
			},
			.when {
				$0.data == "\(notCollectionViewCell)"
			}
		)
		manager.applyItems(["a", "b"], updatedSection: 0)
		XCTAssertNotNil(collectionView.registeredView(for: IndexPath(item: 0, section: 0), item: "a"))
		XCTAssertNotNil(collectionView.registeredView(for: IndexPath(item: 0, section: 0), item: nil))
		XCTAssertNil(collectionView.registeredView(for: IndexPath(item: .max, section: 0), item: nil))
		collectionView.register(
			view: {
				UILabel()
			}
		)
		XCTAssert(collectionView.cell(at: IndexPath(item: 0, section: 0), item: "a") is CollectionViewCell)
		manager.applyItems(["\(notCollectionViewCell)"], updatedSection: notCollectionViewCell)
		XCTAssertFalse(collectionView.cell(at: manager.lastIndexPath!, item: "\(notCollectionViewCell)") is CollectionViewCell)
		manager.appendChildItems(["child"], to: "\(notCollectionViewCell)")
		XCTAssertFalse(collectionView.cell(at: manager.lastIndexPath!, item: "\(notCollectionViewCell)") is CollectionViewCell)
		
		XCTAssert((collectionView.cell(at: IndexPath(item: -1, section: 0), item: nil) as? CollectionViewCell)?.reuseIdentifier == ConfigableCollectionView.emptyCellIdentifier)
	}
	
	func test_diff() {
		collectionView = .init(layout: UICollectionViewLayout())
		collectionView.collectionDatasource = manager.prepareDatasource()
		collectionView.set(uiCollectionViewDataSource: manager.prepareDatasource())
		sections = []
		common()
		exclusiveDiffTest()
		exclusiveCollectionViewRegisterTest()
	}
	func test_base() {
		collectionView = .init(layout: UICollectionViewLayout())
		manager._diffDataSource = nil
		collectionView.collectionDatasource = manager.prepareBaseDataSource()
		collectionView.set(uiCollectionViewDataSource: collectionView.collectionDatasource)
		sections = []
		common()
		exclusiveBaseTest()
		exclusiveCollectionViewRegisterTest()
		collectionViewTest() // 这个会测datasource, 有破坏性改动, 得最后测
	}
	
	func collectionViewTest() {
		// MARK: - Delegate
		class TestDelegate: NSObject, UICollectionViewDelegate { }
		let expection = XCTestExpectation()
		guard let currentDelegate = collectionView.delegate else {
			XCTFail()
			return
		}
		collectionView.delegate = TestDelegate()
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			XCTAssert(!collectionView.collectionDelegate.isEqual(currentDelegate))
			XCTAssert(collectionView.delegate?.isEqual(collectionView.collectionDelegate) ?? false)
			expection.fulfill()
		}
		// MARK: - DataSource
		collectionView.dataSource = manager.prepareBaseDataSource()
		XCTAssert(collectionView.dataSource?.isEqual(collectionView.collectionDatasource) ?? false)
	}
	
	// MARK: - common test @begin
	func common() {
		XCTAssert(manager.lastIndexPath == nil)
		manager.appendSections([1, 2])
		XCTAssert(manager.lastIndexPath == nil)
		manager.appendItems(["a"], toSection: 1)
		XCTAssert(manager.lastIndexPath == IndexPath(item: 0, section: 0))
		manager.deleteAllItems()
		// MARK: - apply
		// 1
		manager.applyItems(["a", "b", "c"], updatedSection: 45096)
		XCTAssert(manager.sections[0].items == [.init("a"), .init("b"), .init("c")])
		XCTAssert(manager.sections[0].items != [.init("a"), .init("b")])
		
		// 2
		manager.applyItems(["e"], atSectionIndex: 0)
		XCTAssert(manager.sections[0].items == [.init("e")])
		XCTAssert(manager.sections[0].items != [.init("f")])
		
		// 3
		manager.applySections([["a", "c"], ["e", "f"]])
		XCTAssert(manager.sections[0].items == [.init("a"), .init("c")])
		XCTAssert(manager.sections[1].items == [.init("e"), .init("f")])
		XCTAssert(manager.sections[0].items != [.init("e"), .init("f")])
		
		// 4 注意, 下面所有操作以这两个个为开始, 其他apply都得在前面测试
		manager.applySections([
			(1, ["1"]),
			(23, ["2", "3"])
		])
		XCTAssert(manager.sections != sections)
		sections = [
			SectionType(sectionIdentifier: 1, items: [.init("1")]),
			SectionType(sectionIdentifier: 23, items: [.init("2"), .init("3")])
		]
		XCTAssert(manager.sections == sections)
		
		// 5 注意, 下面所有操作以这两个个为开始, 其他apply都得在前面测试
		manager.applyItems(["4", "5", "6"], updatedSection: 1)
		XCTAssert(manager.sections != sections)
		sections[0] = SectionType(sectionIdentifier: 1, items: [.init("4"), .init("5"), .init("6")])
		XCTAssert(manager.sections == sections)
		
		// MARK: - itemIdentifier
		XCTAssert(manager.itemIdentifier(for: IndexPath(item: 1, section: 0)) == "5")
		
		// MARK: - appendItems
		// 1
		manager.appendItems(["7", "after 7"], toSection: 23)
		XCTAssert(manager.sections != sections)
		sections[1].items.append(contentsOf: [.init("7"), .init("after 7")])
		XCTAssert(manager.sections == sections)
		
		manager.appendItems(["7"], toSection: 23)
		XCTAssert(manager.sections != sections)
		sections[1].items.remove(at: sections[1].items.count-2)
		sections[1].items.append(.init("7"))
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.appendItems(["8"])
		XCTAssert(manager.sections != sections)
		sections[sections.count-1].items.append(.init("8"))
		XCTAssert(manager.sections == sections)
		
		// MARK: - appendSections
		// 1
		manager.appendSections([4])
		XCTAssert(manager.sections != sections)
		sections.append(.init(sectionIdentifier: 4))
		XCTAssert(manager.sections == sections)
		
		// MARK: - insertSections
		// 1
		manager.insertSections([3], beforeSection: 4)
		XCTAssert(manager.sections != sections)
		sections.insert(.init(sectionIdentifier: 3), at: 2)
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.insertSections([5], afterSection: 4)
		XCTAssert(manager.sections != sections)
		sections.insert(.init(sectionIdentifier: 5), at: 4)
		XCTAssert(manager.sections == sections)
		
		// MARK: - number
		// 1
		XCTAssert(manager.numberOfRootItems == sections.reduce(0, {
			$0 + $1.items.reduce(0, {
				$0 + ($1.allItems() as [ItemType]).count
			})
		}))
		
		// 2
		XCTAssert(manager.numberOfRootItems(inSection: 1) == sections[0].items.reduce(0, {
			$0 + ($1.allItems() as [ItemType]).count
		}))
		
		// 3
		XCTAssert(manager.numberOfRootItems(atSectionIndex: .min) == 0)
		XCTAssert(manager.numberOfRootItems(atSectionIndex: .max) == 0)
		XCTAssert(manager.numberOfRootItems(atSectionIndex: 1) == sections[1].items.reduce(0, {
			$0 + ($1.allItems() as [ItemType]).count
		}))
		
		// MARK: - index
		// 1
		XCTAssert(manager.indexOfSection(1) == 0)
		
		// 2
		XCTAssert(manager.indexPath(for: "2") == IndexPath(item: 0, section: 1))
		
		// MARK: - allItems
		// 1
		XCTAssert((manager.allItems() as [ItemType]) == sections.flatMap {
			$0.items.flatMap {
				$0.allItems()
			}
		})
		
		// 2
		XCTAssert(manager.allItems(inSection: 1) == sections[0].items.flatMap {
			$0.allItems() as [ItemType]
		})
		
		// 3
		XCTAssert(manager.allItems(atSectionIndex: .min) as [ItemType]? == nil)
		XCTAssert(manager.allItems(atSectionIndex: .max) as [ItemType]? == nil)
		XCTAssert(manager.allItems(atSectionIndex: 1) as [ItemType]? == sections[1].items.flatMap {
			$0.allItems()
		})
		
		// MARK: - sectionIdentifier
		// 1
		XCTAssert(manager.sectionIdentifiers() == sections.map {
			$0.anySection.base as! Int
		})
		
		// 2
		XCTAssert(manager.sectionIdentifier(containingItem: "8") == sections[1].anySection.base as? Int)
		
		
		#if swift(>=5.3)
		if manager._diffDataSource != nil {
			// MARK: - visibleItems
			// 1
			do {
				XCTAssert(manager.visibleItems() as [String] == sections.flatMap {
					$0.items.map {
						$0.tryBase()
					}
				})
			}
			
			// 2
			XCTAssert(manager.visibleItems(inSection: 1) as [String]? == sections[0].items.map {
				$0.tryBase()
			})
			
			XCTAssert(manager.visibleItems(atSectionIndex: .min) as [String]? == nil)
			XCTAssert(manager.visibleItems(atSectionIndex: .max) as [String]? == nil)
			XCTAssert(manager.visibleItems(atSectionIndex: 1) as [String]? == sections[1].items.map {
				$0.tryBase()
			})
		}
		
		// MARK: - rootItems
		// 1
		XCTAssert(manager.rootItems() == sections.flatMap {
			$0.items.map {
				$0.base
			}
		})
		
		// 2
		XCTAssert(manager.rootItems(inSection: 1) == sections[0].items.map {
			$0.base
		})
		
		do {
			XCTAssert(manager.rootItems(atSectionIndex: .min) as [ItemType]? == nil)
			XCTAssert(manager.rootItems(atSectionIndex: .max) as [ItemType]? == nil)
			XCTAssert(manager.rootItems(atSectionIndex: 1) as [ItemType]? == sections[1].items.map {
				$0.tryBase()
			})
		}
		#endif
		
		// MARK: - move
		// 1
		manager.moveItem("2", beforeItem: "4")
		XCTAssert(manager.sections != sections)
		sections[0].items.insert(sections[1].items.remove(at: 0), at: 0)
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.moveItem("3", afterItem: "5")
		XCTAssert(manager.sections != sections)
		sections[0].items.insert(sections[1].items.remove(at: 0), at: 3)
		XCTAssert(manager.sections == sections)
		
		// 3
		manager.moveSection(5, beforeSection: 4)
		XCTAssert(manager.sections != sections)
		sections.insert(sections.remove(at: 4), at: 3)
		XCTAssert(manager.sections == sections)
		// 4
		manager.moveSection(3, afterSection: 4)
		XCTAssert(manager.sections != sections)
		sections.insert(sections.remove(at: 2), at: 4)
		XCTAssert(manager.sections == sections)
		
		// MARK: - delete
		// 1
		manager.deleteItems(["5"])
		XCTAssert(manager.sections != sections);
		{
			for section in 0..<sections.count {
				for item in 0..<sections[section].items.count {
					if sections[section].items[item].base == "5" {
						sections[section].items.remove(at: item)
						return
					}
				}
			}
		}()
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.deleteSections([3])
		XCTAssert(manager.sections != sections);
		{
			for section in 0..<sections.count {
				if sections[section].anySection == 3 {
					sections.remove(at: section)
					return
				}
			}
		}()
		XCTAssert(manager.sections == sections)
		
		// MARK: - reverse
		// 1
		manager.reverseRootItems(inSection: 1)
		manager.reverseRootItems(inSection: -1)
		XCTAssert(manager.sections != sections)
		sections[0].items.reverse()
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.reverseRootItems(atSectionIndex: .min)
		manager.reverseRootItems(atSectionIndex: .max)
		manager.reverseRootItems(atSectionIndex: 1)
		XCTAssert(manager.sections != sections)
		sections[1].items.reverse()
		XCTAssert(manager.sections == sections)
		
		// 3
		manager.reverseSections()
		XCTAssert(manager.sections != sections)
		sections.reverse()
		XCTAssert(manager.sections == sections)
		
		// MARK: - insertItems
		manager.appendItems(["insert"])
		XCTAssert(manager.sections != sections)
		sections[sections.count-1].items.append(.init("insert"))
		XCTAssert(manager.sections == sections)
		
		// 1
		manager.insertItems(["insertAfter"], afterItem: "insert")
		XCTAssert(manager.sections != sections)
		sections[sections.count-1].items.append(.init("insertAfter"))
		XCTAssert(manager.sections == sections)
		
		// 2
		manager.insertItems(["insertBefore"], beforeItem: "insert")
		XCTAssert(manager.sections != sections)
		sections[sections.count-1].items.insert(.init("insertBefore"), at: sections[sections.count-1].items.count-2)
		XCTAssert(manager.sections == sections)
		
		// MARK: - appendChildItems
		manager.appendChildItems(["c1", "c2"], to: "insert")
		XCTAssert(manager.sections != sections)
		sections[sections.count-1].items[sections[sections.count-1].items.count-2].subItems.append(contentsOf: [.init("c1"), .init("c2")])
		XCTAssert(manager.sections == sections)
		
		
		// MARK: - contains
		XCTAssertTrue(manager.contains("insert"))
		XCTAssertTrue(manager.contains("c2"))
		XCTAssertFalse(manager.contains("notInsert"))
		
		// MARK: - reload
		manager.reloadItems(["c2", "insert", "notInsert"])
		
		manager.reloadSections([1, 10])
		
		
		// MARK: - iOS 14
		manager.appendChildItems(["c11"], to: "c1")
		XCTAssert(manager.level(of: "insert") == 0)
		XCTAssert(manager.level(of: "c1") == 1)
		XCTAssert(manager.level(of: "c11") == 2)
		XCTAssert(manager.parent(of: "c1") == "insert")
		manager.deleteItems(["c11"])
		
		XCTAssert(manager.lastIndexPath == IndexPath(item: sections.last!.items.count-1, section: sections.count-1))
		if manager._diffDataSource != nil {
			XCTAssertFalse(manager.isExpanded("insert"))
			XCTAssertFalse(manager.isVisible("c1"))
			manager.expand(parents: ["insert"])
			
			XCTAssertTrue(manager.isExpanded("insert"))
			XCTAssertTrue(manager.isVisible("c1"))
			manager.collapse(parents: ["insert"])
			
			XCTAssertFalse(manager.isExpanded("insert"))
			XCTAssertFalse(manager.isVisible("c1"))
			
			manager.appendSections([1000])
			manager.appendItems(["1000-1"])
			manager.appendChildItems(["1000-2", "1000-3"], to: "1000-1")
			
			
			XCTAssert(manager.lastIndexPath == IndexPath(item: 0, section: manager.sections.count-1))
			manager.expand(parents: ["1000-1"])
			
			XCTAssert(manager.lastIndexPath == IndexPath(item: 2, section: manager.sections.count-1))
			manager.deleteSections([1000])
			XCTAssert(manager.sections == sections)
		}
		
		// MARK: - non generic functions
		XCTAssertFalse(manager.isEmpty)
		XCTAssert(manager.numberOfSections == sections.count)
		
		XCTAssert(manager.numberOfRootItems == sections.reduce(0, {
			$0 + $1.items.count
		}))
		
		
		// MARK: - common test @end
		manager.deleteAllItems()
			.reloadImmediately()
		XCTAssertTrue(manager.isEmpty)
		if manager.diffDataSource != nil {
			XCTAssertTrue(manager.diffDataSource?.snapshot().itemIdentifiers.isEmpty ?? false)
		}
	}
}
