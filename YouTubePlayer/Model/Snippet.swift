//
//  Snippet.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class Snippet: AbstractModel {
    public var publishedAt: NSDate!
    public var channelId: String!
    public var title: String!
    public var _description: String!
    public var thumbnails: Thumbnails!
    public var channelTitle: String?
    public var tags: [String]!
    public var categoryId: String!
    public var liveBroadcastContent: String?
    public var defaultAudioLanguage: String?
    public var localized: LocalizedVideoInfo?
    
    override public static var descriptionProperty: String { return "_description" }
    override public static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    override public static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    
    override public func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return ["channelId", "title", "thumbnails", "tags", "categoryId", "publishedAt"].contains(property)
    }
}
