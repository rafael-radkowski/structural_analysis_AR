//
//  cvARManager.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/16/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef cvARManager_hpp
#define cvARManager_hpp

// Apparently include this before any other iOS-specific headers
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>

#include <stdio.h>
#include <functional>

#include "ARManager.h"

// This delegate object allows us to receive callbacks from OpenCV, which requires an objective-C delegate
// It just calls a provided callback
@interface CvCameraDelegateObj : NSObject <CvVideoCameraDelegate> {
    std::function<void(cv::Mat&)> callbackFunc;
}
- (id)initWithCallback:(std::function<void(cv::Mat&)>)callback;

// Function called by openCV
- (void)processImage:(cv::Mat&)image;
@end

class cvARManager : public ARManager {
public:
    cvARManager(UIView* view, SCNScene* scene);
    void initAR() override;
    bool startAR() override;
    size_t stopAR() override;
    void pauseAR() override;
    GLKMatrix4 getCameraMatrix() override;
    GLKMatrix4 getProjectionMatrix() override;
    id<MTLTexture> getBgTexture() override;
    GLKMatrix4 getBgMatrix() override;
private:
    CvVideoCamera* camera;
    CvCameraDelegateObj* camDelegate;
    int video_width, video_height;
    
    void processImage(cv::Mat& image);
    
//    id<MTLTexture> videoTexture;
};

#endif /* cvARManager_hpp */
