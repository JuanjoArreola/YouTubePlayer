//
//  InfoWrapper.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/22/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class InfoWrapper: AbstractModel {
    open var items: [VideoInfo]!
    
    override open static var dateFormats: [String] { return ["y-MM-dd'T'HH:mm:ss.SSSZ"] }
    override open static var resolver: TypeResolver? { return DefaultResolver.sharedResolver }
    
    open override func shouldFail(withInvalidValue value: Any?, forProperty property: String) -> Bool {
        return true
    }
}
