//
//  cvARManager.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/16/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef cvARManager_hpp
#define cvARManager_hpp

// Apparently include openCV things before any other iOS-specific headers
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
// these reference openCV includes
#include "ImageMatcher.hpp"
#include "MaskedImage.hpp"

#include <stdio.h>
#include <functional>
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <vector>
#include <deque>

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
    void doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) override;
    bool startAR() override;
    size_t stopAR() override;
    void pauseAR() override;
    void startCamera() override;
    void stopCamera() override;
    GLKMatrix4 getCameraMatrix() override;
    GLKMatrix4 getProjectionMatrix() override;
    id<MTLTexture> getBgTexture() override;
    GLKMatrix4 getBgMatrix() override;
    
    void saveImg();
    bool saveNext = false;
private:
    void setBgImage(cv::Mat img);
    CvVideoCamera* camera;
    CvCameraDelegateObj* camDelegate;
    bool cam_running = false;
    int video_width, video_height;
    // Metal texture for the background video
    id<MTLTexture> videoTexture;
    
    cv::Mat intrinsic_mat;
    
    void processImage(cv::Mat& image);
    bool do_tracking = false;
    
    // Holds 3D points of the model image
    std::vector<cv::Point3f> model_pts_3d;
    
    // holds the frame that is being
    cv::Mat latest_frame;
    std::atomic<bool> worker_busy;
    std::condition_variable worker_cond_var;
    std::mutex worker_mutex;
    std::thread worker_thread;
    void performTracking();
    
    // for single-frame tracking
    int frames_to_capture = 0;
    int most_inliers = 0;
    cv::Mat best_captured_frame;
    GLKMatrix4 best_captured_pose;
    std::deque<cv::Mat> captured_frames;
    // std::vector<cv::Mat> captured_poses;
    std::function<void(CB_STATE)> frame_callback;
    
    GLKMatrix4 cameraMatrix;
    // AR things
    ImageMatcher matcher;
    
};

#endif /* cvARManager_hpp */
