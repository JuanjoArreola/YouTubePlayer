//
//  YouTubeInfoRequest.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/9/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

enum YouTubeError: ErrorType {
    case InvalidURL
    case EncodingError
    case NoStreamAvailable(reason: String?)
    case SignatureError
    case AgeRestricted
    case WebPageError
    case InvalidWebpage
    case NotImplemented
    case InvalidQuality
}

private let processQueue = dispatch_queue_create("com.youtubeplayer.ProcessQueue", DISPATCH_QUEUE_CONCURRENT)

public class YouTubeInfoRequest: Request<YouTubeVideo> {
    
    var videoIdentifier: String
    var languageIdentifier: String
    
    var playerScript: PlayerScript?
    var noStreamVideo: YouTubeVideo?
    
    var webpage: VideoWebpage?
    var embedWebpage: VideoWebpage?
    
    public convenience init(url: NSURL, languageIdentifier: String? = nil, completion: (getVideo: () throws -> YouTubeVideo) -> Void) throws {
        try validateURL(url)
        let identifier = try getVideoIdentifierFromURL(url)
        self.init(videoIdentifier: identifier, languageIdentifier: languageIdentifier, completion: completion)
    }
    
    public required init(videoIdentifier: String, languageIdentifier: String? = nil, completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        self.videoIdentifier = videoIdentifier
        self.languageIdentifier = languageIdentifier ?? NSLocale.componentsFromLocaleIdentifier(NSLocale.currentLocale().localeIdentifier)[NSLocaleLanguageCode] ?? "en"
        
        super.init()
        completionHandlers!.append(completion)
        dispatch_async(processQueue) { 
            self.start()
        }
    }
    
    // MARK: - 
    
    func start() {
        startInfoRequestWithLabel("embedded") { (getVideo) in
            do {
                let video = try getVideo()
                dispatch_async(dispatch_get_main_queue(), { self.completeWithObject(video) })
            }
            catch YouTubeError.EncodingError {
                dispatch_async(dispatch_get_main_queue(), { self.completeWithError(YouTubeError.EncodingError) })
            }
            catch {
                self.startInfoRequestWithLabel("detailpage", completion: { (getVideo) in
                    do {
                        let video = try getVideo()
                        dispatch_async(dispatch_get_main_queue(), { self.completeWithObject(video) })
                    } catch {
                        self.startWatchPageRequest({ (getVideo) in
                            do {
                                let video = try getVideo()
                                dispatch_async(dispatch_get_main_queue(), { self.completeWithObject(video) })
                            } catch {
                                dispatch_async(dispatch_get_main_queue(), { self.completeWithError(error) })
                            }
                        })
                    }
                })
            }
        }
    }
    
    func startInfoRequestWithLabel(label: String, completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        Log.debug("Starting info request with label: \(label)")
        subrequest = infoURLRequestWithLabel(label) { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                let video = try self.getVideoWithInfo(dictionaryFromResponse(response))
                completion(getVideo: { return video })
            }
            catch YouTubeError.SignatureError {
                self.startWatchPageRequest(completion)
            }
            catch {
                completion(getVideo: { throw error })
            }
        }
    }
    
    func startWatchPageRequest(completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        if let _ = webpage {
            completion(getVideo: { throw YouTubeError.WebPageError })
        }
        
        Log.debug("Starting watch page request")
        subrequest = self.requestWatchPage({ (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                self.webpage = VideoWebpage(htmlString: response)
                if let url = self.webpage?.javascriptPlayerURL {
                    self.startJavaScriptPlayerRequestWithURL(url, completion: completion)
                } else {
                    if self.webpage?.isAgeRestricted ?? false {
                        self.startEmbedWebPageRequest(completion)
                    } else {
                        completion(getVideo: { throw YouTubeError.WebPageError })
                    }
                }
            }
            catch {
                completion(getVideo: { throw error })
            }
        })
    }
    
    func startEmbedWebPageRequest(completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        let url = NSURL(string: "https://www.youtube.com/embed/\(videoIdentifier)")!
        subrequest = startRequestWithURL(url, completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                self.embedWebpage = VideoWebpage(htmlString: response)
                if let url = self.embedWebpage?.javascriptPlayerURL {
                    self.startJavaScriptPlayerRequestWithURL(url, completion: completion)
                } else {
                    completion(getVideo: { throw YouTubeError.WebPageError })
                }
            } catch {
                completion(getVideo: { throw error })
            }
        })
    }
    
    func startJavaScriptPlayerRequestWithURL(url: NSURL, completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        subrequest = startRequestWithURL(url, completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                self.playerScript = PlayerScript(script: response)
                if self.webpage?.isAgeRestricted ?? false {
                    self.startAPIRequest(completion)
                } else {
                    guard let info = self.webpage?.videoInfo as? [String: String] else { throw YouTubeError.WebPageError }
                    let video = try self.getVideoWithInfo(info)
                    completion(getVideo: { return video })
                }
            } catch {
                completion(getVideo: { throw error })
            }
        })
    }
    
    func startAPIRequest(completion: (getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        subrequest = APIRequest({ (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseStringFromData(result.data, response: result.response)
                let video = try self.getVideoWithInfo(dictionaryFromResponse(response))
                completion(getVideo: { return video })
            } catch {
                completion(getVideo: { throw error })
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
    
    func APIRequest(completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable {
        let sts = embedWebpage?.playerConfiguration?["sts"] as? String ?? webpage?.playerConfiguration?["sts"] as? String ?? ""
        let eurl = "https://youtube.googleapis.com/v/\(videoIdentifier)"
        let components = NSURLComponents(string: "https://www.youtube.com/get_video_info")!
        components.queryItems = [NSURLQueryItem(name: "video_id", value: videoIdentifier),
                                 NSURLQueryItem(name: "hl", value: languageIdentifier),
                                 NSURLQueryItem(name: "eurl", value: eurl),
                                 NSURLQueryItem(name: "sts", value: sts)]
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
        return try YouTubeVideo(identifier: videoIdentifier, info: info, playerScript: playerScript)
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