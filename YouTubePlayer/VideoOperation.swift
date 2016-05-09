//
//  YouTubeVideoOperation.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/16/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

enum YouTubeRequestType: Int {
    case GetVideoInfo = 1
    case WatchPage
    case EmbedPage
    case JavaScriptPlayer
}

enum YouTubeError: ErrorType {
    case InvalidURL
    case MaxRequestsReached
    case EncodingError
    case NoStreamAvailable(reason: String?)
    case SignatureError
    case AgeRestricted
    case WebPageError
    case InvalidWebpage
    case NotImplemented
}

private let processQueue = dispatch_queue_create("com.apic.ProcessQueue", DISPATCH_QUEUE_CONCURRENT)

public class VideoOperation {
    
    var videoIdentifier: String
    var languageIdentifier: String
    
    var requestCount = 0
    var session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    var queue = dispatch_get_main_queue()
    
    var requestType: YouTubeRequestType?
    var eventLabels = [String]()
    var webpage: VideoWebpage?
    var embedWebpage: VideoWebpage?
    var playerScript: PlayerScript?
    public var video: Video?
    var noStreamVideo: Video?
    
    // MARK: - Init
    
    public class func createWithVideoIdentifier(identifier: String, languageIdentifier: String = "en", completion: (getOperation: () throws -> VideoOperation) -> Void) -> Request<VideoOperation> {
        let request = Request<VideoOperation>(completionHandler: completion)
        let operation = VideoOperation(videoIdentifier: identifier, languageIdentifier: languageIdentifier)
        dispatch_async(processQueue) { 
            operation.startWithRequest(request)
        }
        return request
    }
    
    convenience init(url: NSURL, languageIdentifier: String = "en") throws {
        try validateURL(url)
        self.init(videoIdentifier: try getVideoIdentifierFromURL(url), languageIdentifier: languageIdentifier)
    }
    
    public required init(videoIdentifier: String, languageIdentifier: String = "en") {
        self.videoIdentifier = videoIdentifier
        self.languageIdentifier = languageIdentifier
    }
    
    // MARK: - Start
    
    func startWithRequest(request: Request<VideoOperation>) {
        if request.cancelled { return }
        
        Log.debug("Starting video operation")
        request.subrequest = requestInfoWithLabel("embedded") { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                let info = dictionaryFromResponse(response)
                try self.handleVideoInfo(info)
                dispatch_async(dispatch_get_main_queue(), { request.completeWithObject(self) })
            }
            catch YouTubeError.EncodingError {
                dispatch_async(dispatch_get_main_queue(), { request.completeWithError(YouTubeError.EncodingError) })
            }
            catch YouTubeError.SignatureError {
                if request.cancelled { return }
                self.startWatchPageWithRequest(request)
            }
            catch {
                if request.cancelled { return }
                request.subrequest = self.requestInfoWithLabel("detailpage", completion: { (getResult) in
                    do {
                        let result = try getResult()
                        let response = try self.getResponseStringFromData(result.data, response: result.response)
                        let info = dictionaryFromResponse(response)
                        try self.handleVideoInfo(info)
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithObject(self) })
                    }
                    catch YouTubeError.EncodingError {
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithError(YouTubeError.EncodingError) })
                    }
                    catch {
                        if request.cancelled { return }
                        self.startWatchPageWithRequest(request)
                    }
                })
            }
        }
    }
    
    func startWatchPageWithRequest(request: Request<VideoOperation>) {
        if request.cancelled { return }
        
        Log.debug("Starting watch page")
        request.subrequest = self.requestWatchPage({ (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
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
                dispatch_async(dispatch_get_main_queue(), { request.completeWithError(error) })
            }
        })
    }
    
    func startEmbedRequest(request: Request<VideoOperation>) {
        if request.cancelled { return }
        
        let url = NSURL(string: "https://www.youtube.com/embed/\(videoIdentifier)")!
        request.subrequest = startRequestWithURL(url) { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                self.embedWebpage = VideoWebpage(htmlString: response)
                guard let javascriptPlayerURL = self.embedWebpage?.javascriptPlayerURL else {
                    throw YouTubeError.InvalidURL
                }
                startRequestWithURL(javascriptPlayerURL, completion: { (getResult) in
                    do {
                        let result = try getResult()
                        let response = try self.getResponseStringFromData(result.data, response: result.response)
                        let _ = try self.handleJavaScriptString(response)
                        guard let info = self.webpage?.videoInfo as? [String: String] else { throw YouTubeError.InvalidWebpage }
                        try self.handleVideoInfo(info)
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithObject(self) })
                    } catch YouTubeError.AgeRestricted {
                        
                    } catch {
                        dispatch_async(dispatch_get_main_queue(), { request.completeWithError(error) })
                    }
                })
            } catch {
                request.completeWithError(error)
            }
        }
    }
    
    func startGoogleAPIRequest(request: Request<VideoOperation>) {
        if request.cancelled { return }
        
        dispatch_async(dispatch_get_main_queue(), { request.completeWithError(YouTubeError.NotImplemented) })
    }
    
    // MARK: - Requests
    
    func requestInfoWithLabel(label: String, completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable? {
        let components = NSURLComponents(string: "https://youtube.com/get_video_info")
        components?.queryItems = [NSURLQueryItem(name: "video_id", value: videoIdentifier),
                                  NSURLQueryItem(name: "hl", value: languageIdentifier),
                                  NSURLQueryItem(name: "el", value: label),
                                  NSURLQueryItem(name: "ps", value: "default")]
        guard let url = components?.URL else { return nil }
        return startRequestWithURL(url, completion: completion)
    }
    
    func requestWatchPage(completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable? {
        let components = NSURLComponents(string: "https://youtube.com/watch")
        components!.queryItems = [NSURLQueryItem(name: "v", value: videoIdentifier),
                                  NSURLQueryItem(name: "ln", value: languageIdentifier),
                                  NSURLQueryItem(name: "has_verified", value: "true")]
        guard let url = components?.URL else { return nil }
        return startRequestWithURL(url, completion: completion)
    }
    
    // MARK: - Handlers
    
    func handleVideoInfo(info: [String: String]) throws {
        let video = try Video(identifier: videoIdentifier, info: info, playerScript: playerScript)
        if let otherVideo = noStreamVideo {
            video.mergeVideo(otherVideo)
        }
        self.video = video
    }
    
    func handleWatchPageHTMLString(html: String, completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) throws -> Cancellable? {
        self.webpage = VideoWebpage(htmlString: html)
        if let javascriptPlayerURL = self.webpage?.javascriptPlayerURL {
            return startRequestWithURL(javascriptPlayerURL, completion: completion)
        } else {
            if self.webpage!.isAgeRestricted {
                throw YouTubeError.AgeRestricted
            } else {
                throw YouTubeError.WebPageError
            }
        }
    }
    
    func handleJavaScriptString(string: String) throws -> PlayerScript {
        playerScript = PlayerScript(script: string)
        if webpage?.isAgeRestricted ?? false {
            throw YouTubeError.AgeRestricted
        } else {
            return playerScript!
        }
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
}

func dictionaryFromResponse(response: String) -> [String: String] {
    var dictionary = [String: String]()
    let fields = response.componentsSeparatedByString("&")
    for field in fields {
        let keyvalue = field.componentsSeparatedByString("=")
        if keyvalue.count == 2 {
            let value = keyvalue[1].stringByRemovingPercentEncoding?.stringByReplacingOccurrencesOfString("+", withString: " ")
            dictionary[keyvalue[0]] = value
        }
    }
    return dictionary
}

private func validateURL(url: NSURL) throws {
    guard let host = url.host else {
        throw YouTubeError.InvalidURL
    }
    if host != "www.youtube.com" {
        throw YouTubeError.InvalidURL
    }
    guard let lastPathComponent = url.lastPathComponent else {
        throw YouTubeError.InvalidURL
    }
    if lastPathComponent != "watch" {
        throw YouTubeError.InvalidURL
    }
}

private func getVideoIdentifierFromURL(url: NSURL) throws -> String {
    guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
        throw YouTubeError.InvalidURL
    }
    for query in components.queryItems ?? [] {
        if query.name == "v" {
            if let identifier = query.value {
                return identifier
            }
            break
        }
    }
    throw YouTubeError.InvalidURL
}
