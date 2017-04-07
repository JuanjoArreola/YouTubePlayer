//
//  YouTubePlayerTests.swift
//  YouTubePlayerTests
//
//  Created by Juan Jose Arreola Simon on 5/1/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import XCTest
import YouTubePlayer

class YouTubePlayerTests: XCTestCase {
    
    let dataRepository = YouTubeDataRepository(key: "")
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testGetYouTubeVideo() {
//        let expectation = expectationWithDescription("video")
//        VideoOperation.createWithVideoIdentifier("SfjLRuE1CLw", languageIdentifier: "en") { (getOperation) in
//            do {
//                let operation = try getOperation()
//                Log.debug(operation)
//                expectation.fulfill()
//            } catch {
//                Log.error(error)
//            }
//        }
//        waitForExpectationsWithTimeout(2, handler: nil)
//    }
    
    func testGetVideoInfo() {
        let exp = expectation(description: "info")
        _ = dataRepository.requestVideoInfo(videoId: "SfjLRuE1CLw") { (getSnippet) in
            do {
                let snippet = try getSnippet()
                Log.debug(snippet.thumbnails.`default`?.description ?? "")
                exp.fulfill()
            } catch {
                Log.error(error)
            }
        }
        waitForExpectations(timeout: 12, handler: nil)
    }
    
}
