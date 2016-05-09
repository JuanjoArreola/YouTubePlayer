//
//  ViewController.swift
//  YouTubeDemo
//
//  Created by Juan Jose Arreola Simon on 5/5/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import YouTubePlayer

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func play(sender: AnyObject) {
        let controller = YouTubeVideoPlayerController(videoIdentifier: "SfjLRuE1CLw")
        controller.modalTransitionStyle = .CoverVertical
        controller.modalPresentationStyle = .FullScreen
        controller.showsPlaybackControls = false
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        presentViewController(controller, animated: true) {
            controller.startPlaying()
            dispatch_async(dispatch_get_main_queue(), { 
//                controller.showsPlaybackControls = true
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "YouTubeSegue" {
            let controller = segue.destinationViewController as! AVPlayerViewController
            VideoOperation.createWithVideoIdentifier("SfjLRuE1CLw", languageIdentifier: "en", completion: { (getOperation) in
                do {
                    let operation = try getOperation()
                    let video = operation.video
                    let videoQualities: [VideoQuality] = [VideoQuality.LiveStreaming, VideoQuality.HD_720, VideoQuality.Medium_360, VideoQuality.Small_240]
                    for quality in videoQualities {
                        if let url = video?.streamURLs[quality] {
                            controller.player = AVPlayer(URL: url)
                            controller.showsPlaybackControls = true
                            controller.player?.play()
                            break
                        }
                    }
                    
                } catch {
//                    Log.error(error)
                }
            })
        }
    }
    
}

