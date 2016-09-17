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
    func youTubeVideoPlayerController(_ controller: YouTubeVideoPlayerController, didFailWithError: Error)
}

open class YouTubeVideoPlayerController: AVPlayerViewController {
    
    weak var youtubeDelegate: YouTubeVideoPlayerController?
    
    var request: YouTubeInfoRequest?
    var previousStatusBarStyle = UIApplication.shared.statusBarStyle
    
    open var preferredQualities = [VideoQuality.liveStreaming, VideoQuality.hd_720, VideoQuality.medium_360, VideoQuality.small_240]
    open var youTubeVideo: YouTubeVideo?
    
    public required convenience init(youTubeVideo: YouTubeVideo) throws {
        self.init()
        try setYouTubeVideo(youTubeVideo)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if previousStatusBarStyle == .lightContent {
            UIApplication.shared.setStatusBarStyle(.default, animated: animated)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if previousStatusBarStyle == .lightContent {
            UIApplication.shared.setStatusBarStyle(previousStatusBarStyle, animated: animated)
        }
    }
    
    open func setYouTubeVideo(_ video: YouTubeVideo) throws {
        self.youTubeVideo = video
        for quality in preferredQualities {
            if let url = video.streamURLs[quality] {
                self.player = AVPlayer(url: url)
                return
            }
        }
        throw YouTubeError.invalidQuality
    }
    
    open func play() {
        self.player?.play()
    }
    
}
