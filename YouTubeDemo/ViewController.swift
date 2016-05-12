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
        _ = YouTubeInfoRequest(videoIdentifier: "SfjLRuE1CLw") { [weak self] (getVideo) in
            do {
                let video = try getVideo()
                let controller = YouTubeVideoPlayerController()
                controller.youTubeVideo = video
                self?.presentViewController(controller, animated: true, completion: { 
                    controller.player?.play()
                })
            } catch {
                
            }
        }
    }
    
}

