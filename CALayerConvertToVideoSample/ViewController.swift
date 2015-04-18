//
//  ViewController.swift
//  CALayerConvertToVideoSample
//
//  Created by ennrd on 4/18/15.
//  Copyright (c) 2015 ws. All rights reserved.
//

import UIKit
import MediaPlayer
import PKHUD

class ViewController: UIViewController {

    @IBOutlet weak var moviePlayerContainerView: UIView!
    let player = MPMoviePlayerController()
    override func viewDidLoad() {
        
        
    }

    @IBAction func createVideo() {
        
        let videoURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("baseVideo", ofType: "m4v")!)
        let renderLayerSize = VideoManipulateUtil.sharedInstance.querySizeWithAssetURL(videoURL: videoURL!)
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        VideoManipulateUtil.sharedInstance.createDynamicAlbum(videoURL: videoURL!, renderLayer: self.createCALayer(renderLayerSize), duration: 10) { (assetURL, error) -> Void in
            PKHUD.sharedHUD.hide(animated: true)
            println("export done")
            if let err = error {
                println("export error")
            } else {
                self.playVideo(assetURL!)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        player.view.frame = CGRectMake(0, 0, self.moviePlayerContainerView.frame.size.width, self.moviePlayerContainerView.frame.size.height)
        player.scalingMode = .AspectFit
        player.fullscreen = false
        player.controlStyle = MPMovieControlStyle.Embedded
        player.shouldAutoplay = false
        self.moviePlayerContainerView.addSubview(player.view)
        
    }
    
    private func playVideo (url: NSURL) {
        
        player.contentURL = url
        player.prepareToPlay()
    }
    
    private func createCALayer (size: CGSize) -> CALayer {
    
        let canvasLayer = CALayer()
        canvasLayer.frame = CGRectMake(0, 0, size.width, size.height)
        canvasLayer.backgroundColor = UIColor.blackColor().CGColor
        
        let lennaLayer = CALayer()
        lennaLayer.frame = CGRectMake(0, 0, size.width, size.height)
        lennaLayer.contents = UIImage(named: "lenna")?.CGImage
        lennaLayer.backgroundColor = UIColor.lightGrayColor().CGColor
        lennaLayer.opacity = 0
        
        let lennaLayerAnimate = CABasicAnimation(keyPath: "opacity")
        lennaLayerAnimate.fromValue = 0
        lennaLayerAnimate.toValue = 1
        lennaLayerAnimate.duration = 2
        lennaLayerAnimate.fillMode = kCAFillModeForwards
        lennaLayerAnimate.removedOnCompletion = false
        lennaLayerAnimate.beginTime = VideoManipulateUtil.sharedInstance.getCoreAnimationBeginTimeAtZero() + 2
        lennaLayer.addAnimation(lennaLayerAnimate, forKey: "opacityChange")
        
        
        
        let marioLayer = CALayer()
        marioLayer.frame = CGRectMake(0, 0, size.width, size.height)
        marioLayer.contents = UIImage(named: "mario")?.CGImage
        marioLayer.backgroundColor = UIColor.lightGrayColor().CGColor
        marioLayer.opacity = 0
        
        let marioLayerAnimate = CABasicAnimation(keyPath: "opacity")
        marioLayerAnimate.fromValue = 0
        marioLayerAnimate.toValue = 1
        marioLayerAnimate.duration = 2
        marioLayerAnimate.fillMode = kCAFillModeForwards
        marioLayerAnimate.removedOnCompletion = false
        marioLayerAnimate.beginTime = VideoManipulateUtil.sharedInstance.getCoreAnimationBeginTimeAtZero() + 6
        marioLayer.addAnimation(marioLayerAnimate, forKey: "opacityChange")
        
        canvasLayer.addSublayer(lennaLayer)
        canvasLayer.addSublayer(marioLayer)
        
        return canvasLayer
    }
}

