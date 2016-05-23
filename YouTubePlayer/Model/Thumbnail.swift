//
//  Thumbnail.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class Thumbnails: AbstractModel {
    public var `default`: Thumbnail?
    public var medium: Thumbnail?
    public var high: Thumbnail?
    public var standard: Thumbnail?
    public var maxres: Thumbnail?
    
    override public static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    public var bestResolutionThumbnail: Thumbnail? {
        return maxres ?? standard ?? high ?? medium ?? `default`
    }
}

public class Thumbnail: AbstractModel {
    public var url: NSURL!
    public var width: Int = 0
    public var height: Int = 0
    
    override public func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
    
    public override var debugDescription: String {
        return "Thumbnail(\(width)x\(height)): \(url)"
    }
}

