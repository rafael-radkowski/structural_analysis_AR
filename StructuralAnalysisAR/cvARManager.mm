//
//  cvARManager.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/16/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//


#include "cvARManager.h"

#import <GLKit/GLKMatrix4.h>
// TODO: Take these out of global, put them into CvCameraDelegateObj class
cv::Mat video_img;
id<MTLTexture> videoTexture;


@implementation CvCameraDelegateObj
- (id)initWithCallback:(std::function<void(cv::Mat&)>)callback {
    callbackFunc = callback;
    return self;
}
- (id)init {
    callbackFunc = [](cv::Mat&){}; // empty callback
    return self;
}

- (void)processImage:(cv::Mat &)image {
    callbackFunc(image);
}
@end

cvARManager::cvARManager(UIView* view, SCNScene* scene) {
    camera = [[CvVideoCamera alloc] initWithParentView:nil];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    camera.defaultFPS = 30;
    // Make lambda for calling this->processImage(). Lets the callback not have to worry that its a member function
    auto this_processImage = [this](cv::Mat& img) {processImage(img);};
    camDelegate = [[CvCameraDelegateObj alloc] initWithCallback:this_processImage];
    camera.delegate = camDelegate;
    [camera start];
    
    video_width = 1280;
    video_height = 720;
    video_img = cv::Mat(video_height, video_width, CV_8UC4);
    
    
    // Create texture for holding video
    MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:video_width height:video_height mipmapped:NO];
    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    videoTexture = [gpu newTextureWithDescriptor:texDescription];
    scene.background.contents = videoTexture;
    
    
    float aspectVideo = (float)video_width / video_height;
    CGSize viewSize = view.frame.size;
    float aspectScreen = (float)viewSize.width / viewSize.height;
    float xScale, yScale;
    xScale = yScale = 1;
    if (aspectVideo > aspectScreen) {
        xScale = aspectScreen / aspectVideo;
    }
    else {
        yScale = aspectVideo / aspectScreen;
    }
    GLKMatrix4 bgImgScale = GLKMatrix4MakeScale(xScale, yScale, 1);
    
    scene.background.contentsTransform = SCNMatrix4FromGLKMatrix4(bgImgScale);
}

void cvARManager::initAR() {
    
}

bool cvARManager::startAR() {
    return false;
}

size_t cvARManager::stopAR() {
    return 0;
}

void cvARManager::pauseAR() {
    
}

GLKMatrix4 cvARManager::getCameraMatrix() {
    //UIImage* image = imageView.image;
    return GLKMatrix4Identity;
}

GLKMatrix4 cvARManager::getProjectionMatrix() {
    return GLKMatrix4Identity;
}

id<MTLTexture> cvARManager::getBgTexture() {
    return nil;
}

GLKMatrix4 cvARManager::getBgMatrix() {
    return GLKMatrix4Identity;
}

void cvARManager::processImage(cv::Mat& image) {
    cv::flip(image, image, -1); // Positive value means flip around y-axis

    static MTLRegion region = MTLRegionMake2D(0, 0, 1280, 720);
    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:image.data bytesPerRow:(1280*4)];
}
