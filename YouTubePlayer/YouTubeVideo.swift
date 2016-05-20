//
//  YouTubeVideo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/16/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

public enum VideoQuality {
    case LiveStreaming
    case Small_240
    case Medium_360
    case HD_720
    
    func value() -> AnyObject {
        switch self {
        case .LiveStreaming: return "HTTPLiveStreaming"
        case .Small_240: return 36
        case .Medium_360: return 18
        case .HD_720: return 22
        }
    }
    
    static func qualityFromString(string: String) -> VideoQuality? {
        switch string {
        case "36": return .Small_240
        case "18": return .Medium_360
        case "22": return .HD_720
        case "HTTPLiveStreaming": return .LiveStreaming
        default:
            return nil
        }
    }
}

public class YouTubeVideo {
    let identifier: String
    var title: String?
    public let streamURLs: [VideoQuality: NSURL]
    
    var duration: Int = 0
    var thumbnailSmall: NSURL?
    var thumbnailMedium: NSURL?
    var thumbnailLarge: NSURL?
    var expirationDate: NSDate?
    
    init(identifier: String, info: [String: String], playerScript: PlayerScript?) throws {
        self.identifier = identifier
        
        let streamMap = info["url_encoded_fmt_stream_map"]
        let httpLiveStream = info["hlsvp"]
        let adaptiveFormats = info["adaptive_fmts"]
        if (streamMap?.isEmpty ?? true) && (httpLiveStream?.isEmpty ?? true) {
            throw YouTubeError.NoStreamAvailable(reason: info["reason"])
        }
        var streamQueries = streamMap?.componentsSeparatedByString(",") ?? [String]()
        if let formats = adaptiveFormats {
            streamQueries += formats.componentsSeparatedByString(",")
        }
        var streamURLs = [VideoQuality: NSURL]()
        if let liveStream = httpLiveStream, url = NSURL(string: liveStream) {
            streamURLs[.LiveStreaming] = url
        }
        
        for streamQuery in streamQueries {
            let stream = dictionaryFromResponse(streamQuery)
            
            var signature: String?
            if let scrambledSignature = stream["s"] {
                if playerScript == nil {
                    throw YouTubeError.SignatureError
                }
                signature = playerScript?.unscrambleSignature(scrambledSignature)
                if signature == nil {
                    continue
                }
            }
            if let urlString = stream["url"], itag = stream["itag"], url = NSURL(string: urlString) {
                if expirationDate == nil {
                    expirationDate = expirationFromURL(url)
                }
                guard let quality = VideoQuality.qualityFromString(itag) else {
                    continue
                }
                if let signature = signature {
                    let escapedSignature = signature.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
                    components?.queryItems?.append(NSURLQueryItem(name: "signature", value: escapedSignature))
                    if let url = components?.URL {
                        streamURLs[quality] = url
                    }
                } else {
                    streamURLs[quality] = url
                }
            }
        }
        if streamURLs.isEmpty {
            throw YouTubeError.NoStreamAvailable(reason: nil)
        }
        self.streamURLs = streamURLs
        
        title = info["title"]
        if let duration = info["length_seconds"] {
            self.duration = Int(duration) ?? 0
        }
        if let thumbnail = info["thumbnail_url"] ?? info["iurl"] {
            thumbnailSmall = NSURL(string: thumbnail)
        }
        if let thumbnail = info["iurlsd"] ?? info["iurlhq"] ?? info["iurlmq"] {
            thumbnailMedium = NSURL(string: thumbnail)
        }
        if let thumbnail = info["iurlmaxres"] {
            thumbnailLarge = NSURL(string: thumbnail)
        }
    }
}

func expirationFromURL(url: NSURL) -> NSDate? {
    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    for query in components?.queryItems ?? [] {
        if query.name == "expire" {
            if let stringTime = query.value, time = Double(stringTime) {
                return NSDate(timeIntervalSince1970: time)
            }
            break
        }
    }
    return nil
}