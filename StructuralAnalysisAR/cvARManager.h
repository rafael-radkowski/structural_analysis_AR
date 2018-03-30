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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
#pragma clang diagnostic pop
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


typedef enum cvStructure {
    skywalk,
    campanile,
    town
} cvStructure_t;

class cvARManager : public ARManager {
public:
    cvARManager(UIView* view, SCNScene* scene, cvStructure_t structure, GLKMatrix4 pose_transform);
    ~cvARManager() override;
    void doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) override;
    bool startAR() override;
    size_t stopAR() override;
    void pauseAR() override;
    void startCamera() override;
    void stopCamera() override;
    GLKMatrix4 getCameraMatrix() override;
    GLKMatrix4 getProjectionMatrix() override;
    bool isTracked() override;
    void drawBackground() override;

    void saveImg();
    bool saveNext = false;

private:
    SCNScene* scene;
    
    void setBgImage(cv::Mat img);
    CvVideoCamera* camera;
    CvCameraDelegateObj* camDelegate;
    int video_width, video_height;
    // Metal textures for double-buffering the background video
    id<MTLTexture> videoTextures[2];
    std::atomic<size_t> currentTexture; // = 0
    std::atomic<bool> texUpdated; // = false
    
    // The structure being tracked
    cvStructure_t structure;
    cv::Mat intrinsic_mat;
    std::vector<double> distortion_coeffs;
    bool is_tracked = false;
    
    void processImage(cv::Mat& image);
    bool do_tracking = false;
    
    // Holds 3D points of the model image
    std::vector<cv::Point3f> model_pts_3d;
    struct MaskProperties {
        float edge_threshold;
        float min_length;
        cv::Vec2f line_angle;
        cv::Vec2f line_origin;
        float mask_width;
        bool equalize_hist;
    } mask_properties;
    
    // holds the frame that is being
    cv::Mat latest_frame;
    // Whether to keep the worker thread alive
    bool thread_live;
    std::atomic<bool> worker_busy;
    std::condition_variable worker_cond_var;
    std::mutex worker_mutex;
    std::thread worker_thread;
    void performTracking();
    
    // Transform matrix to apply to the calculated pose
    GLKMatrix4 pose_transform;
    
    // for single-frame tracking
    int frames_to_capture = 0;
    int most_inliers = 0;
    cv::Mat best_captured_frame;
    GLKMatrix4 best_captured_pose;
    std::deque<cv::Mat> captured_frames;
    // std::vector<cv::Mat> captured_poses;
    std::function<void(CB_STATE)> frame_callback;
    
    GLKMatrix4 cameraMatrix;
    GLKMatrix4 projectionMatrix;
    // AR things
    ImageMatcher matcher;
    
};

#endif /* cvARManager_hpp */
