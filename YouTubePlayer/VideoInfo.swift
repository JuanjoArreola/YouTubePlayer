//
//  VideoInfo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/19/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation
import Apic

class VideoInfo: AbstractModel {
    var id: String!
    var snippet: Snippet!
}

class Snippet: AbstractModel {
    var publishedAt: NSDate!
    var channelId: String!
    var title: String!
    var _description: String!
    var thumbnails: Thumbnails!
    var channelTitle: String?
    var tags: [String]!
    var categoryId: String!
    var liveBroadcastContent: String?
    var defaultAudioLanguage: String!
    var localized: LocalizedVideoInfo?
    
    override static var descriptionProperty: String { return "_description" }
    override static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    override func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return ["publishedAt", "channelId", "title", "thumbnails", "tags", "categoryId", "defaultAudioLanguage"].contains(property)
    }
}

class Thumbnails: AbstractModel {
    var `default`: Thumbnail?
    var medium: Thumbnail?
    var high: Thumbnail?
    var standard: Thumbnail?
    var maxres: Thumbnail?
    
    override static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
}

class Thumbnail: AbstractModel {
    var url: NSURL!
    var width: Int = 0
    var height: Int = 0
    
    override func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
}

class LocalizedVideoInfo: AbstractModel {
    var title: String!
    var _description: String!
    
    override func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
}

class DefaultResolver: TypeResolver {
    
    static var sharedResolver = DefaultResolver()
    
    func resolveType(type: Any) -> Any? {
        if type is Thumbnails?.Type { return Thumbnails.self }
        if type is Thumbnail?.Type { return Thumbnail.self }
        if type is LocalizedVideoInfo?.Type { return LocalizedVideoInfo.self }
        return nil
    }
}