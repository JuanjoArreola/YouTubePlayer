//
//  YouTubeInfoRequest.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/9/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation


class YouTubeInfoRequest: Request<YouTubeVideo> {
    
    var videoIdentifier: String
    var languageIdentifier: String
    
    var playerScript: PlayerScript?
    var noStreamVideo: YouTubeVideo?
    
    var webpage: VideoWebpage?
    
    required init(videoIdentifier: String, languageIdentifier: String? = nil, completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        super.init()
        self.videoIdentifier = videoIdentifier
        self.languageIdentifier = languageIdentifier ?? NSLocale.componentsFromLocaleIdentifier(NSLocale.currentLocale().localeIdentifier)[NSLocaleLanguageCode] ?? "en"
        completionHandlers!.append(completion)
    }
    
    func startInfoRequestWithLabel(label: String) {
        if cancelled { return }
        
        Log.debug("Starting info request with label: \(label)")
        subrequest = infoURLRequestWithLabel(label) { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                let video = try self.getVideoWithInfo(dictionaryFromResponse(response))
                dispatch_async(dispatch_get_main_queue(), { self.completeWithObject(video) })
            }
            catch YouTubeError.EncodingError {
                dispatch_async(dispatch_get_main_queue(), { self.completeWithError(YouTubeError.EncodingError) })
            }
            catch YouTubeError.SignatureError {
                if self.cancelled { return }
                self.startWatchPageRequestWithLabel(label)
            }
            catch {
                if label == "detailpage" {
                    self.startWatchPageRequestWithLabel(label)
                } else {
                    self.startInfoRequestWithLabel("detailpage")
                }
            }
        }
    }
    
    func startWatchPageRequestWithLabel(label: String) {
        if cancelled { return }
        
        Log.debug("Starting watch page request")
        subrequest = self.requestWatchPage({ (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                self.webpage = VideoWebpage(htmlString: response)
                if let url = self.webpage?.javascriptPlayerURL {
                    
                } else {
                    
                }
                
                try self.handleWatchPageHTMLString(response, completion: { (getResult) in
                    do {
                        let result = try getResult()
                        let response = try self.getResponseStringFromData(result.data, response: result.response)
                        let _ = try self.handleJavaScriptString(response)
                        guard let info = self.webpage?.videoInfo as? [String: String] else { throw YouTubeError.InvalidWebpage }
                        try self.handleVideoInfo(info)
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithObject(self) })
                    }
                    catch YouTubeError.AgeRestricted {
                        //                        TODO: youtube.googleapis.com
                    }
                    catch {
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithError(error) })
                    }
                })
            }
            catch YouTubeError.AgeRestricted {
                self.startEmbedRequest(request)
            }
            catch {
                dispatch_async(dispatch_get_main_queue(), { self.completeWithError(error) })
            }
        })
    }

    // MARK: - Requests
    
    func infoURLRequestWithLabel(label: String, completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable {
        let components = NSURLComponents(string: "https://youtube.com/get_video_info")!
        components.queryItems = [NSURLQueryItem(name: "video_id", value: videoIdentifier),
                                  NSURLQueryItem(name: "hl", value: languageIdentifier),
                                  NSURLQueryItem(name: "el", value: label),
                                  NSURLQueryItem(name: "ps", value: "default")]
        return startRequestWithURL(components.URL!, completion: completion)
    }
    
    func requestWatchPage(completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable? {
        let components = NSURLComponents(string: "https://youtube.com/watch")!
        components.queryItems = [NSURLQueryItem(name: "v", value: videoIdentifier),
                                  NSURLQueryItem(name: "ln", value: languageIdentifier),
                                  NSURLQueryItem(name: "has_verified", value: "true")]
        return startRequestWithURL(components.URL!, completion: completion)
    }
    
    // MARK: - Util
    
    func getResponseStringFromData(data: NSData, response: NSURLResponse?) throws -> String {
        guard let responseString = String(data: data, encoding: NSUTF8StringEncoding) else {
            throw YouTubeError.EncodingError
        }
        if responseString.isEmpty {
            throw YouTubeError.EncodingError
        }
        return responseString
    }
    
    func getVideoWithInfo(info: [String: String]) throws -> YouTubeVideo {
        let video = try YouTubeVideo(identifier: videoIdentifier, info: info, playerScript: playerScript)
        if let otherVideo = noStreamVideo {
            video.mergeVideo(otherVideo)
        }
        return video
    }
}