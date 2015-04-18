//
//  VideoManipulateUtil.swift
//  EnnPhotoPub
//
//  Created by ennrd on 4/17/15.
//  Copyright (c) 2015 enn. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import AssetsLibrary


public typealias VideoManipulateUtilExportCompletionBlock = (NSURL!, NSError!) -> Void

public class VideoManipulateUtil {
    
    
    public class var sharedInstance: VideoManipulateUtil {
        struct Static {
            static let instance: VideoManipulateUtil = VideoManipulateUtil()
        }
        return Static.instance
    }
    
    
    public func getCoreAnimationBeginTimeAtZero() -> CFTimeInterval {
        return AVCoreAnimationBeginTimeAtZero
    }
    
    public func querySizeWithAssetURL(#videoURL: NSURL) -> CGSize {
        let videoAsset = AVURLAsset(URL: videoURL, options: nil)
        return self.querySize(video: videoAsset)
    }
    
    
    public func createDynamicAlbum (#videoURL: NSURL, renderLayer:CALayer, duration: Float, completionBlock: VideoManipulateUtilExportCompletionBlock!) {
        self.createDynamicAlbum(videoURL: videoURL, audioURL: nil, renderLayer: renderLayer, duration: duration, completionBlock: completionBlock, isSaveToPhotosAlbum: false)
    }
    
    
    public func createDynamicAlbum (#videoURL: NSURL, audioURL: NSURL!, renderLayer:CALayer, duration: Float, completionBlock: VideoManipulateUtilExportCompletionBlock!) {
        self.createDynamicAlbum(videoURL: videoURL, audioURL: audioURL, renderLayer: renderLayer, duration: duration, completionBlock: completionBlock, isSaveToPhotosAlbum: false)
    }
    
    

    public func createDynamicAlbum (#videoURL: NSURL, audioURL: NSURL!, renderLayer:CALayer, duration: Float, completionBlock: VideoManipulateUtilExportCompletionBlock!, isSaveToPhotosAlbum: Bool) {
    
        
        // 0 - Get AVAsset from NSURL
        let videoAsset = AVURLAsset(URL: videoURL, options: nil)
        
        
        // 1 - Prepare VideoAssetTrack and DurationTimeRange for further use
        let videoAssetTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo).first as AVAssetTrack
       
        let durationCMTime = CMTimeMakeWithSeconds(Float64(duration), 30)
        let durationTimeRange = CMTimeRangeMake(kCMTimeZero, durationCMTime)
        
        
        // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        
        // 3 - Get Video track
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        videoTrack.insertTimeRange(durationTimeRange, ofTrack: videoAssetTrack, atTime: kCMTimeZero, error: nil)
        
        
        // 3.0 - Handle Audio asset 
        if let audiourl_ = audioURL {
            let audioAsset = AVURLAsset(URL: audiourl_, options: nil)
            let audioAssetTrack = audioAsset.tracksWithMediaType(AVMediaTypeAudio).first as AVAssetTrack
            let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
            audioTrack.insertTimeRange(durationTimeRange, ofTrack: audioAssetTrack, atTime: kCMTimeZero, error: nil)
        }
        
        
        // 3.1 - Create AVMutableVideoCompositionInstruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = durationTimeRange
        
        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        videolayerInstruction.setTransform(videoAssetTrack.preferredTransform, atTime: kCMTimeZero)
        videolayerInstruction.setOpacity(0.0, atTime: videoAsset.duration)
        
        // 3.3 - Add instructions
        mainInstruction.layerInstructions = [videolayerInstruction]
        
        let mainCompositionInst = AVMutableVideoComposition()
        
        let naturalSize = self.querySize(video: videoAsset)
        
        let renderWidth = naturalSize.width
        let renderHeight = naturalSize.height
        
        mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(1, 30)
        
        self.applyVideoEffectsToComposition(mainCompositionInst, size: naturalSize, overlayLayer: renderLayer)
        
        
        // 4 - Get path
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectory = paths.first as String
        let randomInt = arc4random() % 1000
        let fullPathDocs = documentDirectory.stringByAppendingPathComponent("CreatedVideo-\(randomInt).mov")
        
        let createdVideoURL = NSURL.fileURLWithPath(fullPathDocs)
        
        
        // 5 - Create exporter
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter.outputURL = createdVideoURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainCompositionInst
        exporter.exportAsynchronouslyWithCompletionHandler {
            
            if exporter.status == AVAssetExportSessionStatus.Completed {
                
                let outputURL = exporter.outputURL
                
                if !isSaveToPhotosAlbum {
                    dispatch_async(dispatch_get_main_queue(), {
                        completionBlock(outputURL, nil)
                    })
                    return
                }
                
                
                let library = ALAssetsLibrary()
                if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
                    library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: { (assetURL, error) -> Void in
                        NSFileManager.defaultManager().removeItemAtURL(createdVideoURL!, error: nil)
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            completionBlock(assetURL, error)
                        })
                    })
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    completionBlock(nil, NSError(domain: "Video Export", code: -1, userInfo: nil))
                })
            }
        }
    }
    
    
    private func querySize(#video: AVAsset) -> CGSize {
        
        let videoAssetTrack = video.tracksWithMediaType(AVMediaTypeVideo).first as AVAssetTrack
        let videoTransform = videoAssetTrack.preferredTransform
        
        var isVideoAssetPortrait = false
        
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            isVideoAssetPortrait = true
        }
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            isVideoAssetPortrait = true
        }
        
        var natureSize = CGSizeZero
        if isVideoAssetPortrait {
            natureSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width)
        } else {
            natureSize = videoAssetTrack.naturalSize
        }
        
        return natureSize
    }
    
    
    private func applyVideoEffectsToComposition(composition: AVMutableVideoComposition, size:CGSize, overlayLayer: CALayer) {
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        
        parentLayer.frame = CGRectMake(0, 0, size.width, size.height)
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
    }
}