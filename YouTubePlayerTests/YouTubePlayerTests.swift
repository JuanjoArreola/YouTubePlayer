//
//  YouTubePlayerTests.swift
//  YouTubePlayerTests
//
//  Created by Juan Jose Arreola Simon on 5/1/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import XCTest
@testable import YouTubePlayer

class YouTubePlayerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let expectation = expectationWithDescription("video")
        VideoOperation.createWithVideoIdentifier("SfjLRuE1CLw", languageIdentifier: "en") { (getOperation) in
            do {
                let operation = try getOperation()
                Log.debug(operation)
                expectation.fulfill()
            } catch {
                Log.error(error)
            }
        }
        waitForExpectationsWithTimeout(200, handler: nil)
    }
    
}
