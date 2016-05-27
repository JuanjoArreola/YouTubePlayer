//
//  YouTubeVideoWebPage.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/20/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

private let playerConfigRegularExpression = try! NSRegularExpression(pattern: "ytplayer.config\\s*=\\s*(\\{.*?\\});|\\(\\s*'PLAYER_CONFIG',\\s*(\\{.*?\\})\\s*\\)", options: [.CaseInsensitive])
private let regionsRegex = try! NSRegularExpression(pattern: "meta\\s+itemprop=\"regionsAllowed\"\\s+content=\"(.*)\"", options: [])

class VideoWebpage {
    
    var html: String!
    var htmlRange: NSRange!
    var playerConfiguration: [String: AnyObject]?
    var videoInfo: [String: AnyObject]?
    var javascriptPlayerURL: NSURL?
    var isAgeRestricted: Bool = false
    var regionsAllowed = Set<String>()
    
    init?(htmlString: String) {
        html = htmlString
        htmlRange = NSMakeRange(0, html.characters.count)
        playerConfiguration = getPlayerConfigurationFromHtml(htmlString)
        
        if let configuration = playerConfiguration {
            videoInfo = getVideoInfoWithConfiguration(configuration)
        }
        if let jsAssets = playerConfiguration?["assets.js"] as? String {
            if jsAssets.hasPrefix("//") {
                javascriptPlayerURL = NSURL(string: "https:\(jsAssets)")
            }
        }
        isAgeRestricted = htmlString.rangeOfString("og:restrictions:age") != nil
        
        let match = regionsRegex.firstMatchInString(htmlString, options: [], range: htmlRange)
        if match?.numberOfRanges > 1 {
            let regions = html.substringWithNSRange(match!.rangeAtIndex(1))
            regionsAllowed = Set<String>(regions.componentsSeparatedByString(","))
        }
        
    }
    
    private func getPlayerConfigurationFromHtml(html: String) -> [String: AnyObject]? {
        let results = playerConfigRegularExpression.matchesInString(html, options: [], range: htmlRange)
        for result in results {
            do {
                if result.range.length == 0 { continue }
                let configString = html.substringWithNSRange(result.range)
                let configData = configString.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
                let playerConfiguration = try NSJSONSerialization.JSONObjectWithData(configData, options: [])
                if playerConfiguration is [String: AnyObject] {
                    return playerConfiguration as? [String: AnyObject]
                }
            } catch { }
        }
        return nil
    }
    
    private func getVideoInfoWithConfiguration(configuration: [String: AnyObject]) -> [String: AnyObject]? {
        if let args = configuration["args"] as? [String: AnyObject] {
            return args
        }
        return nil
    }
    
}

extension String {
    func substringWithNSRange(range: NSRange) -> String {
        let start = self.startIndex.advancedBy(range.location)
        return self.substringWithRange(start...start.advancedBy(range.length))
    }
}

