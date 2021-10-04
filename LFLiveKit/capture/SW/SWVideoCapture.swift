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
    private let videoCamera: Camera?
//    private let beautyFilter: Beauty = Beauty()
    private let renderView: RenderView

    
    @objc
    public required init?(videoConfiguration configuration: LFLiveVideoConfiguration?) {
        self.configuration = configuration
        self.videoCamera = try? Camera(sessionPreset: .hd1920x1080, location: .frontFacing)
        self.renderView = RenderView(frame: CGRect(origin: .zero, size: CGSize(width: 1920, height: 1080)))
//        beautyFilter.beautyLevel = 1.0

        super.init()
        self.setupFilter()
        
        videoCamera?.delegate = self

    }
    
    public func previousColorFilter() {
        
    }
    
    public func nextColorFilter() {
        
    }
    
    public func setTargetColorFilter(_ targetIndex: Int) {
        
    }

}

extension SWVideoCapture {
    public var preView: UIView! {
        @objc(preView) get {
            return renderView.superview
        }
        set {
            if renderView.superview != nil {
                renderView.removeFromSuperview()
            }
            renderView.frame = newValue.frame
            newValue.insertSubview(renderView, at: 0)
        }
    }
    
    private func setupFilter() {
        guard let camera = videoCamera else { return }
        camera --> renderView
//        camera --> beautyFilter --> renderView
        camera.startCapture()
    }
}


extension SWVideoCapture: CameraDelegate {
    public func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
//        renderView.
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        //CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        delegate?.captureOutput?(self, pixelBuffer: pixelBuffer, at: time)

    }

}
