//
//  YouTubeDataRepository.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/18/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Apic

open class YouTubeDataRepository: AbstractRepository {
    
    var key: String
    
    public init(key: String) {
        self.key = key
        super.init(responseParser: DefaultResponseParser<String>())
        
        DefaultTypeResolver.shared.register(types: LocalizedVideoInfo.self,
                                            Thumbnail.self,
                                            Thumbnails.self,
                                            VideoInfo.self,
                                            Snippet.self)
    }
    
    
    open func requestVideoInfo(videoId: String, completion: @escaping (_ getSnippet: () throws -> Snippet) -> Void) -> ApicRequest<Snippet> {
        let request = ApicRequest<Snippet>(completionHandler: completion)
        let params: [String: Any] = ["id": videoId, "key": key, "part": "snippet"]
        request.subrequest = requestObject(method: .GET, url: "https://www.googleapis.com/youtube/v3/videos", params: params) { (getObject: () throws -> InfoWrapper) -> Void in
            do {
                let infoWrapper = try getObject()
                guard let snippet = infoWrapper.items.first?.snippet else { throw YouTubeError.invalidResponse }
                request.complete(with: snippet)
            } catch {
                request.complete(with: error)
            }
        }
        return request
    }
}
