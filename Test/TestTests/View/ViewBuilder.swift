//
//  ViewBuilder.swift
//  TestTests
//
//  Created by 庄黛淳华 on 2020/7/28.
//

import XCTest
@testable import ConfigableCollectionView

class ViewBuilder: XCTestCase {
	override class func setUp() {
		ConfigableCollectionView.isUnitTesting = true
	}
	
	func build(@ConfigableCollectionView.ViewBuilder view: @escaping () -> UILabel?) -> UILabel? {
		view()
	}
	func test() {
		func _test(canbuild: Bool) {
			let label = build {
				if canbuild {
					UILabel()
				}
			}
			if canbuild {
				XCTAssertNotNil(label)
			} else {
				XCTAssertNil(label)
			}
		}
		_test(canbuild: false)
		_test(canbuild: true)
	}
}
