//
//  YouTubeVideoPlayerController.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/28/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

protocol YouTubeVideoPlayerControllerDelegate: class {
    func youTubeVideoPlayerController(controller: YouTubeVideoPlayerController, didFailWithError: ErrorType)
}

public class YouTubeVideoPlayerController: AVPlayerViewController {
    
    weak var youtubeDelegate: YouTubeVideoPlayerController?
    
    var request: YouTubeInfoRequest?
    
    public var preferredQualities = [VideoQuality.LiveStreaming, VideoQuality.HD_720, VideoQuality.Medium_360, VideoQuality.Small_240]
    public var youTubeVideo: YouTubeVideo?
    
    public required convenience init(youTubeVideo: YouTubeVideo) throws {
        self.init()
        try setYouTubeVideo(youTubeVideo)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setYouTubeVideo(video: YouTubeVideo) throws {
        self.youTubeVideo = video
        for quality in preferredQualities {
            if let url = video.streamURLs[quality] {
                self.player = AVPlayer(URL: url)
                return
            }
        }
        throw YouTubeError.InvalidQuality
    }
    
    public func play() {
        self.player?.play()
    }
    
}