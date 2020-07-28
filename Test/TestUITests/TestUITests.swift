//
//  TestUITests.swift
//  TestUITests
//
//  Created by 庄黛淳华 on 2020/7/25.
//

import XCTest
@testable import ConfigableCollectionView

class TestUITests: XCTestCase {
	override class func setUp() {
		ConfigableCollectionView.isUnitTesting = false
	}
	
    func test() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
		
		let helloWorldStaticText = XCUIApplication().collectionViews/*@START_MENU_TOKEN@*/.staticTexts["Hello World ~ ! ! !"]/*[[".cells.staticTexts[\"Hello World ~ ! ! !\"]",".staticTexts[\"Hello World ~ ! ! !\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		helloWorldStaticText.tap()
		helloWorldStaticText/*@START_MENU_TOKEN@*/.press(forDuration: 1.9);/*[[".tap()",".press(forDuration: 1.9);"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
    }
}
