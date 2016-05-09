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
    
    var request: Request<VideoOperation>?
    
    var videoOperation: VideoOperation?
    public var videoIdentifier: String!
    
    public required init(videoURL: NSURL) {
        self.init()
    }
    
    public required init(videoIdentifier: String) {
        self.init()
        self.videoIdentifier = videoIdentifier
//        self.showsPlaybackControls = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public override func viewDidLayoutSubviews() {
//        showsPlaybackControls = true
    }
    
    public func startPlaying() {
        request?.cancel()
        request = VideoOperation.createWithVideoIdentifier(videoIdentifier, languageIdentifier: "en", completion: { (getOperation) in
            do {
                self.videoOperation = try getOperation()
                self.playVideo(self.videoOperation!.video!)
            } catch {
                Log.error(error)
            }
        })
    }
    
    private func playVideo(video: Video) {
        let videoQualities: [VideoQuality] = [VideoQuality.LiveStreaming, VideoQuality.HD_720, VideoQuality.Medium_360, VideoQuality.Small_240]
        for quality in videoQualities {
            if let url = video.streamURLs[quality] {
                self.showsPlaybackControls = true
                self.player = AVPlayer(URL: url)
//                self.showsPlaybackControls = true
                self.player?.play()
                break
            }
        }
        
    }
    
}