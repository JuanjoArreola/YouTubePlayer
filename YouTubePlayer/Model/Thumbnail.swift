//
//  Thumbnail.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class Thumbnails: AbstractModel {
    open var `default`: Thumbnail?
    open var medium: Thumbnail?
    open var high: Thumbnail?
    open var standard: Thumbnail?
    open var maxres: Thumbnail?
    
    override open static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    open var bestResolutionThumbnail: Thumbnail? {
        return maxres ?? standard ?? high ?? medium ?? `default`
    }
}

open class Thumbnail: AbstractModel {
    open var url: URL!
    open var width: Int = 0
    open var height: Int = 0
    
    open override func shouldFail(withInvalidValue value: Any?, forProperty property: String) -> Bool {
        return true
    }
    
    open override var debugDescription: String {
        return "Thumbnail(\(width)x\(height)): \(url)"
    }
}

