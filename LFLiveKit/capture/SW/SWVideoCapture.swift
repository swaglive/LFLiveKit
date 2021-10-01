//
//  SWVideoCapture.swift
//  LFLiveKit
//
//  Created by finn on 2021/10/1.
//

import Foundation

@objcMembers
public class SWVideoCapture: NSObject, LFVideoCaptureInterface {
    public var running: Bool = true
    public var delegate: LFVideoCaptureInterfaceDelegate?
    public var preView: UIView!
    public var captureDevicePosition: AVCaptureDevice.Position = .front
    public var beautyFace: Bool = true
    public var torch: Bool = false
    public var mirror: Bool = true
    public var zoomScale: CGFloat = 1.0
    public var videoFrameRate: Int = 60
    public var watermarkView: UIView? = nil
    public var currentImage: UIImage? = nil
    public var saveLocalVideo: Bool = false
    public var saveLocalVideoPath: URL? = nil
    public var currentColorFilterName: String? = nil
    public var currentColorFilterIndex: Int = 0
    public var colorFilterNames: [String]? = nil
    public var mirrorOutput: Bool = true
    private let configuration: LFLiveVideoConfiguration?
    
    @objc
    public required init?(videoConfiguration configuration: LFLiveVideoConfiguration?) {
        self.configuration = configuration
    }
    
    public func previousColorFilter() {
        
    }
    
    public func nextColorFilter() {
        
    }
    
    public func setTargetColorFilter(_ targetIndex: Int) {
        
    }

}
