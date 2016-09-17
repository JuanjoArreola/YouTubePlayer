//
//  YouTubeInfoRequest.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 5/9/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

enum YouTubeError: Error {
    case invalidURL
    case encodingError
    case noStreamAvailable(reason: String?)
    case signatureError
    case ageRestricted
    case webPageError
    case invalidWebpage
    case notImplemented
    case invalidQuality
    case invalidResponse
}

private let processQueue = DispatchQueue(label: "com.youtubeplayer.ProcessQueue", attributes: DispatchQueue.Attributes.concurrent)

open class YouTubeInfoRequest: Request<YouTubeVideo> {
    
    var videoIdentifier: String
    var languageIdentifier: String
    
    var playerScript: PlayerScript?
    var noStreamVideo: YouTubeVideo?
    
    var webpage: VideoWebpage?
    var embedWebpage: VideoWebpage?
    
    public convenience init(url: URL, languageIdentifier: String? = nil, completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) throws {
        try validate(url: url)
        let identifier = try getVideoIdentifier(from: url)
        self.init(videoIdentifier: identifier, languageIdentifier: languageIdentifier, completion: completion)
    }
    
    public required init(videoIdentifier: String, languageIdentifier: String? = nil, completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        self.videoIdentifier = videoIdentifier
        self.languageIdentifier = languageIdentifier ?? Locale.current.languageCode ?? "en"
        
        super.init()
        completionHandlers!.append(completion)
        processQueue.async { 
            self.start()
        }
    }
    
    // MARK: - 
    
    func start() {
        startInfoRequest(withLabel: "embedded") { (getVideo) in
            do {
                let video = try getVideo()
                DispatchQueue.main.async(execute: { self.complete(withObject: video) })
            }
            catch YouTubeError.encodingError {
                DispatchQueue.main.async(execute: { self.complete(withError: YouTubeError.encodingError) })
            }
            catch {
                self.startInfoRequest(withLabel: "detailpage", completion: { (getVideo) in
                    do {
                        let video = try getVideo()
                        DispatchQueue.main.async(execute: { self.complete(withObject: video) })
                    } catch {
                        self.startWatchPageRequest(completion: { (getVideo) in
                            do {
                                let video = try getVideo()
                                DispatchQueue.main.async(execute: { self.complete(withObject: video) })
                            } catch {
                                DispatchQueue.main.async(execute: { self.complete(withError: error) })
                            }
                        })
                    }
                })
            }
        }
    }
    
    func startInfoRequest(withLabel label: String, completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        Log.debug("Starting info request with label: \(label)")
        subrequest = infoURLRequest(withLabel: label) { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseString(from: result.data, response: result.response)
                let video = try self.getVideo(withInfo: dictionary(fromResponse: response))
                completion({ return video })
            }
            catch YouTubeError.signatureError {
                self.startWatchPageRequest(completion: completion)
            }
            catch {
                completion({ throw error })
            }
        }
    }
    
    func startWatchPageRequest(completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        if let _ = webpage {
            completion({ throw YouTubeError.webPageError })
        }
        
        Log.debug("Starting watch page request")
        subrequest = self.requestWatchPage(completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseString(from: result.data, response: result.response)
                self.webpage = VideoWebpage(htmlString: response)
                if let url = self.webpage?.javascriptPlayerURL {
                    self.startJavaScriptPlayerRequest(with: url as URL, completion: completion)
                } else {
                    if self.webpage?.isAgeRestricted ?? false {
                        self.startEmbedWebPageRequest(completion: completion)
                    } else {
                        completion({ throw YouTubeError.webPageError })
                    }
                }
            }
            catch {
                completion({ throw error })
            }
        })
    }
    
    func startEmbedWebPageRequest(completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        let url = URL(string: "https://www.youtube.com/embed/\(videoIdentifier)")!
        subrequest = startRequest(with: url, completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseString(from: result.data, response: result.response)
                self.embedWebpage = VideoWebpage(htmlString: response)
                if let url = self.embedWebpage?.javascriptPlayerURL {
                    self.startJavaScriptPlayerRequest(with: url, completion: completion)
                } else {
                    completion({ throw YouTubeError.webPageError })
                }
            } catch {
                completion({ throw error })
            }
        })
    }
    
    func startJavaScriptPlayerRequest(with url: URL, completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        
        subrequest = startRequest(with: url, completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseString(from: result.data, response: result.response)
                self.playerScript = PlayerScript(script: response)
                if self.webpage?.isAgeRestricted ?? false {
                    self.startAPIRequest(completion: completion)
                } else {
                    guard let info = self.webpage?.videoInfo as? [String: String] else { throw YouTubeError.webPageError }
                    let video = try self.getVideo(withInfo: info)
                    completion({ return video })
                }
            } catch {
                completion({ throw error })
            }
        })
    }
    
    func startAPIRequest(completion: @escaping (_ getVideo: () throws -> YouTubeVideo) -> Void) {
        if cancelled { return }
        subrequest = APIRequest(completion: { (getResult) in
            do {
                let result = try getResult()
                let response = try self.getResponseString(from: result.data, response: result.response)
                let video = try self.getVideo(withInfo: dictionary(fromResponse: response))
                completion({ return video })
            } catch {
                completion({ throw error })
            }
        })
    }
    
    // MARK: - Requests
    
    func infoURLRequest(withLabel label: String, completion: @escaping (_ getResult: () throws -> (data: Data, response: URLResponse?)) -> Void) -> Cancellable {
        var components = URLComponents(string: "https://youtube.com/get_video_info")!
        components.queryItems = [URLQueryItem(name: "video_id", value: videoIdentifier),
                                 URLQueryItem(name: "hl", value: languageIdentifier),
                                 URLQueryItem(name: "el", value: label),
                                 URLQueryItem(name: "ps", value: "default")]
        return startRequest(with: components.url!, completion: completion)
    }
    
    func requestWatchPage(completion: @escaping (_ getResult: () throws -> (data: Data, response: URLResponse?)) -> Void) -> Cancellable? {
        var components = URLComponents(string: "https://youtube.com/watch")!
        components.queryItems = [URLQueryItem(name: "v", value: videoIdentifier),
                                 URLQueryItem(name: "ln", value: languageIdentifier),
                                 URLQueryItem(name: "has_verified", value: "true")]
        return startRequest(with: components.url!, completion: completion)
    }
    
    func APIRequest(completion: @escaping (_ getResult: () throws -> (data: Data, response: URLResponse?)) -> Void) -> Cancellable {
        let sts = embedWebpage?.playerConfiguration?["sts"] as? String ?? webpage?.playerConfiguration?["sts"] as? String ?? ""
        let eurl = "https://youtube.googleapis.com/v/\(videoIdentifier)"
        var components = URLComponents(string: "https://www.youtube.com/get_video_info")!
        components.queryItems = [URLQueryItem(name: "video_id", value: videoIdentifier),
                                 URLQueryItem(name: "hl", value: languageIdentifier),
                                 URLQueryItem(name: "eurl", value: eurl),
                                 URLQueryItem(name: "sts", value: sts)]
        return startRequest(with: components.url!, completion: completion)
    }
    
    // MARK: - Util
    
    func getResponseString(from data: Data, response: URLResponse?) throws -> String {
        guard let responseString = String(data: data, encoding: String.Encoding.utf8) else {
            throw YouTubeError.encodingError
        }
        if responseString.isEmpty {
            throw YouTubeError.encodingError
        }
        return responseString
    }
    
    func getVideo(withInfo info: [String: String]) throws -> YouTubeVideo {
        return try YouTubeVideo(identifier: videoIdentifier, info: info, playerScript: playerScript)
    }
    
}

private func getVideoIdentifier(from url: URL) throws -> String {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        throw YouTubeError.invalidURL
    }
    for query in components.queryItems ?? [] {
        if query.name == "v" {
            if let identifier = query.value {
                return identifier
            }
            break
        }
    }
    throw YouTubeError.invalidURL
}

private func validate(url: URL) throws {
    guard let host = url.host else {
        throw YouTubeError.invalidURL
    }
    if host != "www.youtube.com" {
        throw YouTubeError.invalidURL
    }
    if url.lastPathComponent != "watch" {
        throw YouTubeError.invalidURL
    }
}

func dictionary(fromResponse response: String) -> [String: String] {
    var dictionary = [String: String]()
    let fields = response.components(separatedBy: "&")
    for field in fields {
        let keyvalue = field.components(separatedBy: "=")
        if keyvalue.count == 2 {
            let value = keyvalue[1].removingPercentEncoding?.replacingOccurrences(of: "+", with: " ")
            dictionary[keyvalue[0]] = value
        }
    }
    return dictionary
}
