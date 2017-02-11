//
//  VideoInfo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/19/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class VideoInfo: AbstractModel {
    var id: String!
    open var snippet: Snippet!
    
    override open static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    override open static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    open override func shouldFail(withInvalidValue value: Any?, forProperty property: String) -> Bool {
        return true
    }
}

class DefaultResolver: TypeResolver {
    
    static var sharedResolver = DefaultResolver()
    
    public func resolve(type: Any) -> Any? {
        if type is Thumbnails?.Type || type is ImplicitlyUnwrappedOptional<Thumbnails>.Type { return Thumbnails.self }
        if type is Thumbnail?.Type || type is ImplicitlyUnwrappedOptional<Thumbnail>.Type { return Thumbnail.self }
        if type is LocalizedVideoInfo?.Type { return LocalizedVideoInfo.self }
        if type is [VideoInfo]?.Type || type is ImplicitlyUnwrappedOptional<[VideoInfo]>.Type { return VideoInfo.self }
        if type is Snippet?.Type || type is ImplicitlyUnwrappedOptional<Snippet>.Type { return Snippet.self }
        return nil
    }

    func resolve(typeForName typeName: String) -> Any? {
        return nil
    }
    
    public func resolveDictionary(type: Any) -> Any? {
        return nil
    }
}
