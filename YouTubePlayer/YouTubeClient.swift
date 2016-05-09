//
//  YouTubeClient.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/16/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

public class YouTubeClient {
    
    var operationQueue: NSOperationQueue?
    public private(set) var languageIdentifier: String!
    
    public static var defaultClient = YouTubeClient()
    
    init() {
        
    }
    
    init(languageIdentifier identifier: String) {
        
    }
    
    func getVideoWithIdentifier(identifier: String, completion: (getVideo: () throws -> Video) -> Void) {
        let operation = VideoOperation(videoIdentifier: identifier, languageIdentifier: languageIdentifier)
    }
    
//    func getVideoWithURL(url: NSURL, completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
//        let operation = YouTubeVideoOperation(videoIdentifier: identifier, languageIdentifier: languageIdentifier)
//        
//    }
}