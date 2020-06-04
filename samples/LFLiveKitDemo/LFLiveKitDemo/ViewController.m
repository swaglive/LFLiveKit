//
//  ViewController.m
//  LFLiveKitDemo
//
//  Created by admin on 16/8/30.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "ViewController.h"
#import "LFLivePreview.h"

@interface ViewController ()
@property (nonatomic, strong) LFLivePreview *preview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.preview];
    [self.preview requestAccessForAudio];
    [self.preview requestAccessForVideo];
}

- (LFLivePreview *)preview {
    if (!_preview) {
        _preview = [[LFLivePreview alloc] initWithFrame:self.view.bounds];
    }
    return _preview;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
