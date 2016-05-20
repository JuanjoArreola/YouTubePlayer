//
//  YouTubeDataRepository.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/18/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

class YouTubeDataRepository: AbstractRepository<String> {
    
    static var sharedInstance = YouTubeDataRepository()
    
    private init() {
        
    }
    
    func requestVideoInfo(videoId: String) {
        
    }
}
