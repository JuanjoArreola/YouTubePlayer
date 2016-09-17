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
    
    override open static var descriptionProperty: String { return "_description" }
    
    open override func shouldFail(withInvalidValue value: Any?, forProperty property: String) -> Bool {
        return true
    }
}
