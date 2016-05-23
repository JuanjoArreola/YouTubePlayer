//
//  VideoInfo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/19/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class VideoInfo: AbstractModel {
    var id: String!
    public var snippet: Snippet!
    
    override public static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    override public static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    override public func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
}

class DefaultResolver: TypeResolver {
    
    static var sharedResolver = DefaultResolver()
    
    func resolveType(type: Any) -> Any? {
        if type is Thumbnails?.Type { return Thumbnails.self }
        if type is Thumbnail?.Type { return Thumbnail.self }
        if type is LocalizedVideoInfo?.Type { return LocalizedVideoInfo.self }
        if type is [VideoInfo]?.Type { return VideoInfo.self }
        if type is Snippet?.Type { return Snippet.self }
        return nil
    }
}
