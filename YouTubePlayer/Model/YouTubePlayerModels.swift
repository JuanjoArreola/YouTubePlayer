//
//  YouTubePlayerModels.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola on 03/04/17.
//  Copyright © 2017 juanjo. All rights reserved.
//

import Foundation
import Apic

public class YouTubePlayerModels {
    public static var shared = YouTubePlayerModels()
    
    func register() {
        DefaultTypeResolver.shared.register(types: LocalizedVideoInfo.self,
                                            Thumbnail.self,
                                            Thumbnails.self,
                                            VideoInfo.self,
                                            Snippet.self)
    }
}
