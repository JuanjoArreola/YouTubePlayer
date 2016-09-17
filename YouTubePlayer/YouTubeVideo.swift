//
//  YouTubeVideo.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/16/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

public enum VideoQuality {
    case liveStreaming
    case small_240
    case medium_360
    case hd_720
    
    func value() -> AnyObject {
        switch self {
        case .liveStreaming: return "HTTPLiveStreaming" as AnyObject
        case .small_240: return 36 as AnyObject
        case .medium_360: return 18 as AnyObject
        case .hd_720: return 22 as AnyObject
        }
    }
    
    static func qualityFromString(_ string: String) -> VideoQuality? {
        switch string {
        case "36": return .small_240
        case "18": return .medium_360
        case "22": return .hd_720
        case "HTTPLiveStreaming": return .liveStreaming
        default:
            return nil
        }
    }
}

open class YouTubeVideo {
    let identifier: String
    var title: String?
    open let streamURLs: [VideoQuality: URL]
    
    var duration: Int = 0
    var thumbnailSmall: URL?
    var thumbnailMedium: URL?
    var thumbnailLarge: URL?
    var expirationDate: Date?
    
    init(identifier: String, info: [String: String], playerScript: PlayerScript?) throws {
        self.identifier = identifier
        
        let streamMap = info["url_encoded_fmt_stream_map"]
        let httpLiveStream = info["hlsvp"]
        let adaptiveFormats = info["adaptive_fmts"]
        if (streamMap?.isEmpty ?? true) && (httpLiveStream?.isEmpty ?? true) {
            throw YouTubeError.noStreamAvailable(reason: info["reason"])
        }
        var streamQueries = streamMap?.components(separatedBy: ",") ?? [String]()
        if let formats = adaptiveFormats {
            streamQueries += formats.components(separatedBy: ",")
        }
        var streamURLs = [VideoQuality: URL]()
        if let liveStream = httpLiveStream, let url = URL(string: liveStream) {
            streamURLs[.liveStreaming] = url
        }
        
        for streamQuery in streamQueries {
            let stream = dictionary(fromResponse: streamQuery)
            
            var signature: String?
            if let scrambledSignature = stream["s"] {
                if playerScript == nil {
                    throw YouTubeError.signatureError
                }
                signature = playerScript?.unscrambleSignature(scrambledSignature)
                if signature == nil {
                    continue
                }
            }
            if let urlString = stream["url"], let itag = stream["itag"], let url = URL(string: urlString) {
                if expirationDate == nil {
                    expirationDate = expiration(from: url)
                }
                guard let quality = VideoQuality.qualityFromString(itag) else {
                    continue
                }
                if let signature = signature {
                    let escapedSignature = signature.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    components?.queryItems?.append(URLQueryItem(name: "signature", value: escapedSignature))
                    if let url = components?.url {
                        streamURLs[quality] = url
                    }
                } else {
                    streamURLs[quality] = url
                }
            }
        }
        if streamURLs.isEmpty {
            throw YouTubeError.noStreamAvailable(reason: nil)
        }
        self.streamURLs = streamURLs
        
        title = info["title"]
        if let duration = info["length_seconds"] {
            self.duration = Int(duration) ?? 0
        }
        if let thumbnail = info["thumbnail_url"] ?? info["iurl"] {
            thumbnailSmall = URL(string: thumbnail)
        }
        if let thumbnail = info["iurlsd"] ?? info["iurlhq"] ?? info["iurlmq"] {
            thumbnailMedium = URL(string: thumbnail)
        }
        if let thumbnail = info["iurlmaxres"] {
            thumbnailLarge = URL(string: thumbnail)
        }
    }
}

func expiration(from url: URL) -> Date? {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    for query in components?.queryItems ?? [] {
        if query.name == "expire" {
            if let stringTime = query.value, let time = Double(stringTime) {
                return Date(timeIntervalSince1970: time)
            }
            break
        }
    }
    return nil
}
