//
//  LFHardwareVideoEncoder.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//
#import "LFHardwareVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

static int const kMaxAccVideoFrameBufferCount = 48;
static NSTimeInterval const kSessionLockDuration = 2.0f;

@interface LFHardwareVideoEncoder (){
    VTCompressionSessionRef compressionSession;
    NSInteger frameCount;
    NSData *sps;
    NSData *pps;
    FILE *fp;
    BOOL enabledWriteVideoFile;
    NSInteger accEncodedVideoFrameCount;
    NSInteger accVideoFrameBufferCount;
}

@property (nonatomic, strong) LFLiveVideoConfiguration *configuration;
@property (nonatomic, weak) id<LFVideoEncodingDelegate> h264Delegate;
@property (nonatomic) NSInteger currentVideoBitRate;

@property (nonatomic) BOOL isResetting;
@property (strong, nonatomic) dispatch_semaphore_t sessionLock;
@end

@implementation LFHardwareVideoEncoder

#pragma mark -- LifeCycle
- (instancetype)initWithVideoStreamConfiguration:(LFLiveVideoConfiguration *)configuration {
    if (self = [super init]) {
        NSLog(@"USE LFHardwareVideoEncoder");
        _sessionLock = dispatch_semaphore_create(1);
        _configuration = configuration;
        [self resetCompressionSession];
        frameCount = -1;
#ifdef DEBUG
        enabledWriteVideoFile = NO;
        [self initForFilePath];
#endif
        
    }
    return self;
}

- (void)resetCompressionSession {
    dispatch_semaphore_wait(self.sessionLock, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSessionLockDuration * NSEC_PER_SEC)));
    if (compressionSession) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    
    OSStatus status = VTCompressionSessionCreate(NULL, _configuration.videoSize.width, _configuration.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void *)self, &compressionSession);
    if (status != noErr) {
        dispatch_semaphore_signal(self.sessionLock);
        return;
    }
    
    _currentVideoBitRate = _configuration.videoBitRate;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval/_configuration.videoFrameRate));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_configuration.videoFrameRate));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_configuration.videoBitRate));
    NSArray *limit = @[@(_configuration.videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
    
    dispatch_semaphore_signal(self.sessionLock);
}

- (void)setVideoBitRate:(NSInteger)videoBitRate {
    if (_isResetting) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    NSArray *limit = @[@(videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    _currentVideoBitRate = videoBitRate;
}

- (NSInteger)videoBitRate {
    return _currentVideoBitRate;
}

- (void)dealloc {
    if (compressionSession != NULL) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- LFVideoEncoder
- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp {
    if (_isResetting) return;
    frameCount++;
    accVideoFrameBufferCount++;
    CMTime presentationTimeStamp = CMTimeMake(frameCount, (int32_t)_configuration.videoFrameRate);
    VTEncodeInfoFlags flags;
    CMTime duration = CMTimeMake(1, (int32_t)_configuration.videoFrameRate);
    
    NSDictionary *properties = nil;
    if (frameCount % (int32_t)_configuration.videoMaxKeyframeInterval == 0) {
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    NSNumber *timeNumber = @(timeStamp);
    
    if (accVideoFrameBufferCount >= kMaxAccVideoFrameBufferCount) {
        accVideoFrameBufferCount = 0;
        if (accEncodedVideoFrameCount == 0) {
            NSLog(@"reset VTCompressionSession cuz not receive encoded video frame for a period");
            [self resetCompressionSession];
        }
        accEncodedVideoFrameCount = 0;
    }
    
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
    if(status != noErr){
        [self resetCompressionSession];
    }
}

- (void)stopEncoder {
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeIndefinite);
}

- (void)setDelegate:(id<LFVideoEncodingDelegate>)delegate {
    _h264Delegate = delegate;
}

- (void)reset {
    _isResetting = YES;
    
    sps = nil;
    pps = nil;
    frameCount = -1;
    [self resetCompressionSession];
    
    _isResetting = NO;
}

#pragma mark -- VideoCallBack
static void VideoCompressonOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    if (!sampleBuffer) return;
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) return;
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) return;
    
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    uint64_t timeStamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    LFHardwareVideoEncoder *videoEncoder = (__bridge LFHardwareVideoEncoder *)VTref;
    if (status != noErr) {
        return;
    }
    
    videoEncoder->accEncodedVideoFrameCount++;
    
    BOOL spsAdded = NO;
    if (keyframe && !videoEncoder->sps) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusCode == noErr) {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusCode == noErr) {
                spsAdded = YES;
                videoEncoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                videoEncoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                
                if (videoEncoder->enabledWriteVideoFile) {
                    NSMutableData *data = [[NSMutableData alloc] init];
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->sps];
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->pps];
                    fwrite(data.bytes, 1, data.length, videoEncoder->fp);
                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            LFVideoFrame *videoFrame = [LFVideoFrame new];
            videoFrame.timestamp = timeStamp;
            videoFrame.data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            videoFrame.isKeyFrame = keyframe;
            videoFrame.sps = videoEncoder->sps;
            videoFrame.pps = videoEncoder->pps;
            if (spsAdded) {
                videoFrame.formatChanged = YES;
                spsAdded = NO;
            }
            
            if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)]) {
                [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoFrame];
            }
            
            if (videoEncoder->enabledWriteVideoFile) {
                NSMutableData *data = [[NSMutableData alloc] init];
                if (keyframe) {
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                } else {
                    uint8_t header[] = {0x00, 0x00, 0x01};
                    [data appendBytes:header length:3];
                }
                [data appendData:videoFrame.data];
                
                fwrite(data.bytes, 1, data.length, videoEncoder->fp);
            }
            
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo.h264"];
    NSLog(@"%@", path);
    self->fp = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
}

- (NSString *)GetFilePathByfileName:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return writablePath;
}

@end
