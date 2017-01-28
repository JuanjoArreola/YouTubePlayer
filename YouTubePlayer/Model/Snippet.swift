//
//  Snippet.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class Snippet: AbstractModel {
    open var publishedAt: Date!
    open var channelId: String!
    open var title: String!
    open var _description: String!
    open var thumbnails: Thumbnails!
    open var channelTitle: String?
    open var tags: [String]?
    open var categoryId: String!
    open var liveBroadcastContent: String?
    open var defaultAudioLanguage: String?
    open var localized: LocalizedVideoInfo?
    
    open override static var propertyKeys: [String: String] { return ["_description": "description"]}
    override open static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    override open static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    
    open override func shouldFail(withInvalidValue value: Any?, forProperty property: String) -> Bool {
        return ["channelId", "title", "thumbnails", "categoryId", "publishedAt"].contains(property)
    }
}
