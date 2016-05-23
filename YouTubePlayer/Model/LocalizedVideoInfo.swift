//
//  LocalizedVideoInfo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class LocalizedVideoInfo: AbstractModel {
    public var title: String!
    public var _description: String!
    
    override public static var descriptionProperty: String { return "_description" }
    
    override public func shouldFailWithInvalidValue(value: AnyObject?, forProperty property: String) -> Bool {
        return true
    }
}
