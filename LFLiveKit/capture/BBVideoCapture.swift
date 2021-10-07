//
//  BBVideoCapture.swift
//  LFLiveKit
//
//  Created by finn on 2021/10/6.
//

import Foundation
import BBMetalImage

@objcMembers
public class BBVideoCapture: NSObject, LFVideoCaptureInterface {
    public var running: Bool = true
    public var delegate: LFVideoCaptureInterfaceDelegate?

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
//
    private let configuration: LFLiveVideoConfiguration?
    private let camera: BBMetalCamera
    private let beautyFilter: BBMetalBeautyFilter = BBMetalBeautyFilter()
    private let metalView: BBMetalView
    private let output: BBOutput

//    private var camera: BBMetalCamera!
    
    @objc
    public required init?(videoConfiguration configuration: LFLiveVideoConfiguration?) {
        metalView = BBMetalView(frame: .zero)
        self.configuration = configuration
        camera = BBMetalCamera(sessionPreset: .hd1280x720, position: .front)!
        beautyFilter.smoothDegree = 1.0
//        camera.add(consumer: metalView)
        camera.add(consumer: beautyFilter).add(consumer: metalView)
        output = BBOutput()
        beautyFilter.add(consumer: output)


//        self.videoCamera = try? Camera(sessionPreset: .hd1920x1080, location: .frontFacing)
//        self.renderView = RenderView(frame: CGRect(origin: .zero, size: CGSize(width: 1920, height: 1080)))
//        beautyFilter.beautyLevel = 1.0

        super.init()
//        self.setupFilter()
//
//        videoCamera?.delegate = self

        output.output = { [weak self] (maybeBuffer, maybeCMTime) in
            guard let me = self else { return }
            guard let buffer = maybeBuffer, let time = maybeCMTime else {
                print("buffer: \(maybeBuffer), time: \(maybeCMTime)")
                return
            }
            me.delegate?.captureOutput?(self, pixelBuffer: buffer, at: time, didUpdateVideoConfiguration: false)
            
        }
        camera.start()
    }
    
    public func previousColorFilter() {
        
    }
    
    public func nextColorFilter() {
        
    }
    
    public func setTargetColorFilter(_ targetIndex: Int) {
        
    }

}

extension BBVideoCapture {
    public var preView: UIView! {
        @objc(preView) get {
            return metalView.superview
        }
        set {
            if metalView.superview != nil {
                metalView.removeFromSuperview()
            }
            metalView.frame = newValue.frame
            newValue.insertSubview(metalView, at: 0)
        }
    }
//
//    private func setupFilter() {
//        guard let camera = videoCamera else { return }
//        camera --> beautyFilter --> renderView
//        camera.startCapture()
//    }
}


//extension BBVideoCapture: CameraDelegate {
//    public func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
////        renderView.
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//        //CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        delegate?.captureOutput?(self, pixelBuffer: pixelBuffer, at: time)
//
//    }
//
//}
