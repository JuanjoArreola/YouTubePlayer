//
//  YouTubeVideoWebPage.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/20/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

private let playerConfigRegularExpression = try! NSRegularExpression(pattern: "ytplayer.config\\s*=\\s*(\\{.*?\\});|\\(\\s*'PLAYER_CONFIG',\\s*(\\{.*?\\})\\s*\\)", options: [.caseInsensitive])
private let regionsRegex = try! NSRegularExpression(pattern: "meta\\s+itemprop=\"regionsAllowed\"\\s+content=\"(.*)\"", options: [])

class VideoWebpage {
    
    var html: String!
    var htmlRange: NSRange!
    var playerConfiguration: [String: AnyObject]?
    var videoInfo: [String: AnyObject]?
    var javascriptPlayerURL: URL?
    var isAgeRestricted: Bool = false
    var regionsAllowed = Set<String>()
    
    init?(htmlString: String) {
        html = htmlString
        htmlRange = NSMakeRange(0, html.characters.count)
        playerConfiguration = getPlayerConfiguration(fromHtml: htmlString)
        
        if let configuration = playerConfiguration {
            videoInfo = getVideoInfo(withConfiguration: configuration)
        }
        if let jsAssets = playerConfiguration?["assets.js"] as? String {
            if jsAssets.hasPrefix("//") {
                javascriptPlayerURL = URL(string: "https:\(jsAssets)")
            }
        }
        isAgeRestricted = htmlString.range(of: "og:restrictions:age") != nil
        
        let match = regionsRegex.firstMatch(in: htmlString, options: [], range: htmlRange)
        if match?.numberOfRanges ?? 0 > 1 {
            let regions = html.substring(with: match!.rangeAt(1))
            regionsAllowed = Set<String>(regions.components(separatedBy: ","))
        }
        
    }
    
    fileprivate func getPlayerConfiguration(fromHtml html: String) -> [String: AnyObject]? {
        let results = playerConfigRegularExpression.matches(in: html, options: [], range: htmlRange)
        for result in results {
            do {
                if result.range.length == 0 { continue }
                let configString = html.substring(with: result.range)
                let configData = configString.data(using: String.Encoding.utf8) ?? Data()
                let playerConfiguration = try JSONSerialization.jsonObject(with: configData, options: [])
                if playerConfiguration is [String: AnyObject] {
                    return playerConfiguration as? [String: AnyObject]
                }
            } catch { }
        }
        return nil
    }
    
    fileprivate func getVideoInfo(withConfiguration configuration: [String: AnyObject]) -> [String: AnyObject]? {
        if let args = configuration["args"] as? [String: AnyObject] {
            return args
        }
        return nil
    }
    
}

extension String {
    func substring(with range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let range = start..<self.index(start, offsetBy: range.length)

        return self.substring(with: range)
    }
}
