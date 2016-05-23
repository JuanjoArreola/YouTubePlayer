//
//  YouTubeDataRepository.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/18/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

public class YouTubeDataRepository: AbstractRepository<String> {
    
    var key: String
    
    override private init(objectKey: String?, objectsKey: String?, statusKey: String?, statusOk: String?, errorDescriptionKey: String?, errorCodeKey: String?) {
        self.key = ""
        super.init()
    }
    
    public required init(key: String) {
        self.key = key
    }
    
    public func requestVideoInfo(videoId: String, completion: (getSnippet: () throws -> Snippet) -> Void) -> ApicRequest<Snippet> {
        let request = ApicRequest<Snippet>(completionHandler: completion)
        let params: [String: AnyObject] = ["id": videoId, "key": key, "part": "snippet"]
        request.subrequest = requestObject(.GET, url: "https://www.googleapis.com/youtube/v3/videos", params: params) { (getObject: () throws -> InfoWrapper) -> Void in
            do {
                let infoWrapper = try getObject()
                guard let snippet = infoWrapper.items.first?.snippet else { throw YouTubeError.InvalidResponse }
                request.completeWithObject(snippet)
            } catch {
                request.completeWithError(error)
            }
        }
        return request
    }
}
