//
//  InfoWrapper.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class InfoWrapper: AbstractModel {
    public var items: [VideoInfo]!
    
    override public static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    override public static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    override public func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
}
