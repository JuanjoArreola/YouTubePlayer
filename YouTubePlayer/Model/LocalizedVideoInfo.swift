//
//  LocalizedVideoInfo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class LocalizedVideoInfo: AbstractModel {
    open var title: String!
    open var _description: String!
    
    open override static var propertyKeys: [String: String] {
        return ["_description": "description"]
    }
}
