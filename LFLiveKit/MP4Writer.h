//
//  MP4Writer.h
//  SDKSampleApp
//
//  This code and all components © 2015 – 2019 Wowza Media Systems, LLC. All rights reserved.
//  This code is licensed pursuant to the BSD 3-Clause License.
//


#import <Foundation/Foundation.h>
#import "LFLiveVideoConfiguration.h"

@interface MP4Writer : NSObject

@property (nonatomic, assign, readonly) BOOL writing;
 
- (BOOL) prepareWithConfig:(LFLiveVideoConfiguration *)config;
- (void) startWriting;
- (void) stopWriting;
- (void) appendVideoSample:(CMSampleBufferRef)videoSample;
- (void) appendAudioSample:(CMSampleBufferRef)audioSample;

@end
