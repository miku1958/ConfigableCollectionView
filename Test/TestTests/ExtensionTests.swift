//
//  Extension.swift
//  TestTests
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import XCTest
@testable import ConfigableCollectionView

class ExtensionTests: XCTestCase {
	override class func setUp() {
		ConfigableCollectionView.isUnitTesting = true
	}
	
	// MARK: - Array
	func test_Array_unique() throws {
		XCTAssertTrue([1, 2, 1].unique().array == [1, 2])
	}
	func test_Array_call() throws {
		var count = 0
		Array(repeating: {
			count += 1
		}, count: 2).call()
		XCTAssertTrue(count == 2)
	}
	
	// MARK: - NSObject
	func test_NSObject_map() throws {
		struct Package {
			let obj: NSObject
		}
		let obj = NSObject()
		let pack = obj.map {
			Package(obj: $0)
		}
		XCTAssertTrue(pack.obj == obj)
	}
}
