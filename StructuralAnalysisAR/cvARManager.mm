//
//  cvARManager.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/16/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//


#include "cvARManager.h"

#import <GLKit/GLKMatrix4.h>

// Use 3840x2160 video resolution
//#define HIGH_RES

// Utility functions (defined at bottom)
cv::Mat cvMatFromUIImage(UIImage* image);
UIImage* UIImageFromCVMat(cv::Mat cvMat);
GLKMatrix4 CVMat3ToGLKMat4(const cv::Mat& cvMat);
GLKMatrix4 CVMat4ToGLKMat4(const cv::Mat& cvMat);


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

cvARManager::cvARManager(UIView* view, SCNScene* scene)
: worker_busy(false)
, scene(scene)
, texUpdated(false)
, currentTexture(0) {
//    cv::setNumThreads(0);
    // Set up camera callbacks
    camera = [[CvVideoCamera alloc] initWithParentView:nil];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
#ifdef HIGH_RES
        camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset3840x2160;
#else
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1920x1080;
#endif
    camera.defaultFPS = 30;
    camera.rotateVideo = false;
    camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    // Make lambda for calling this->processImage(). Lets the callback not have to worry that its a member function
    auto this_processImage = [this](cv::Mat& img) {processImage(img);};
    camDelegate = [[CvCameraDelegateObj alloc] initWithCallback:this_processImage];
    camera.delegate = camDelegate;
    
    
//    std::cout << "sessio nloaded: " << camera.captureSessionLoaded << std::endl;
//    if ([camera.captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
//        std::cout << "3840" << std::endl;
//        video_width = 3840;
//        video_height = 2160;
//    }
//    else if ([camera.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
//        std::cout << "1920" << std::endl;
//        video_width = 1920;
//        video_height = 1080;
//    }
//    else if ([camera.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//        std::cout << "1280" << std::endl;
//        video_width = 1280;
//        video_height = 720;
//    }
//    else {
//        std::cout << "Your camera is terrible" << std::endl;
//    }
    
#ifdef HIGH_RES
    video_width = 3840;
    video_height = 2160;
#else
    video_width = 1920;
    video_height = 1080;
#endif
    
    
    // Create texture for holding video
    for (int i = 0; i < 2; ++i) {
        MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:video_width height:video_height mipmapped:NO];
        id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
        videoTextures[i] = [gpu newTextureWithDescriptor:texDescription];
    }
    scene.background.contents = videoTextures[currentTexture];
    
    // Allocate space for frame to hold frame being processed for tracking
    latest_frame = cv::Mat(video_height, video_width, CV_8UC4);
    // start background worker thread to perform tracking
    
    thread_live = true;
    worker_thread = std::thread([this] () {while (thread_live) performTracking();});
    
    cameraMatrix = GLKMatrix4Identity;
    
    // Calculate background scaling for texture
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
    
//    double intr_data[9] = {2927.801, 0, 1634.850,
//                           0, 2943.291, 1262.958,
//                           0, 0, 1};
//    double intr_data[9] = {3322.232, 0, 1994.099,
//                           0, 3289.874, 1426.956,
//                           0, 0, 1};
//    double intr_data[9] = {1054.603, 0, 633.047,
//                           0, 783.303, 339.751,
//                           0, 0, 1};
//    double intr_data[9] = {1049, 0, 640,
//        0, 1049, 360,
//        0, 0, 1};
    // From 1920x1080 video on iPad air
    // distortion = [0.139796, -0.278091, 0.000479, -0.000284]
    double intr_data[9] = {1706.752, 0, 963.632,
                           0, 1732.817, 596.788,
                           0, 0, 1};
//    cv::Mat raw_intrinsic_mat(3, 3, CV_64F, intr_data);
//    intrinsic_mat = cv::getOptimalNewCameraMatrix(raw_intrinsic_mat, std::vector<float>(4, 0), cv::Size(4032,3024), 0, cv::Size(video_width,video_height));
    
    intrinsic_mat = cv::Mat(3, 3, CV_64F, intr_data).clone();
    
    // Load reference image
#ifdef HIGH_RES
    UIImage* bgImage = [UIImage imageNamed:@"cutout_skywalk_3840x2160.png"];
#else
//    UIImage* bgImage = [UIImage imageNamed:@"cutout_skywalk_1920x1080.png"];
    UIImage* bgImage = [UIImage imageNamed:@"skywalk_1920_back.png"];
#endif
    
    MaskedImage masked(cvMatFromUIImage(bgImage));
    cv::Mat cropped = masked.getCropped();
    matcher = ImageMatcher(cropped, 6000, 0.8, 0.98, 4.0, std::cout);
    
    
    const float model_width = 200;
    const float model_height = (model_width * ((double)video_height / video_width));
    const std::vector<cv::KeyPoint>& model_keypoints = matcher.getRefKeypoints();
    model_pts_3d.resize(model_keypoints.size());
    float model_x_offset = -7;
    float model_y_offset = -25;
    float model_rotation_offset = 0.0;
    float cos_angle = std::cos(model_rotation_offset);
    float sin_angle = std::sin(model_rotation_offset);
    for (size_t i = 0; i < model_keypoints.size(); ++i) {
        auto model_pt = model_keypoints[i].pt;
        masked.uncropPoint(model_pt);
        float unrotated_x = model_pt.x * (model_width / video_width) - (model_width / 2);
        float unrotated_y = model_pt.y * (model_height / video_height) - (model_height / 2);
        // rotate
        model_pts_3d[i].x = unrotated_x * cos_angle - unrotated_y * sin_angle;
        model_pts_3d[i].y = unrotated_x * sin_angle + unrotated_y * cos_angle;
        // Add offsets
        model_pts_3d[i].x += model_x_offset;
        model_pts_3d[i].y += model_y_offset;
        
        model_pts_3d[i].z = 0;
    }
    
    cameraMatrix = GLKMatrix4Make(
                                          -0.987822, -0.009307, 0.155310, 0.000000,
                                          -0.045182, 0.981796, -0.184486, 0.000000,
                                          -0.154240, -0.189710, -0.969649, 0.000000,
                                          -8.753870, -31.452150, -204.253311, 1.000000);
    
    printf("aspect screen: %f\n", aspectScreen);
    projectionMatrix = GLKMatrix4MakePerspective(36.909 * (M_PI / 180.0), aspectScreen, 0.1, 500);
    
    // Copy image to background Metal texture
//    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
//    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:cvMatFromUIImage(bgImage).data bytesPerRow:(video_width*4)];
}

// destructor
cvARManager::~cvARManager() {
    // stop the camera, if it's not already stopped
    // ARC should clean it up once the object is deleted upon class destruction (I think)
    [camera stop];
    
    // stop the background processing thread
    thread_live = false;
    // wake up the background thread
    {
        std::unique_lock<std::mutex> lk(worker_mutex);
        worker_cond_var.notify_one();
    }
    worker_thread.join();
    
    scene.background.contents = nil;
    std::cout << "cvARManager destructor done" << std::endl;
}

void cvARManager::setBgImage(cv::Mat img) {
    // Copy image to the unused background Metal texture
    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
    [videoTextures[1-currentTexture] replaceRegion:region mipmapLevel:0 withBytes:img.data bytesPerRow:(video_width*4)];
    texUpdated = true;
}

void cvARManager::drawBackground() {
    if (texUpdated) {
        // Swap background textures
        currentTexture = 1 - currentTexture;
        scene.background.contents = videoTextures[currentTexture];
        texUpdated = false;
    }
}

void cvARManager::saveImg() {
    saveNext = true;
}

void cvARManager::doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) {
    captured_frames.clear();
    most_inliers = 0;
    frames_to_capture = n_avg;
    frame_callback = cb_func;
    
    
//    UIImage* bgImage = [UIImage imageNamed:@"skywalk_1920_back.png"];
//    std::unique_lock<std::mutex> lk(worker_mutex);
//    worker_busy = true;
//    cvMatFromUIImage(bgImage).copyTo(latest_frame);
//    setBgImage(latest_frame);
//    captured_frames.push_back(latest_frame);
//    worker_cond_var.notify_one();
}

bool cvARManager::startAR() {
    do_tracking = true;
    [camera start];
    return true;
}

size_t cvARManager::stopAR() {
    return 0;
}

void cvARManager::pauseAR() {
    do_tracking = false;
}

void cvARManager::startCamera() {
    [camera start];
}

void cvARManager::stopCamera() {
    [camera stop];
}

GLKMatrix4 cvARManager::getCameraMatrix() {
    //UIImage* image = imageView.image;
    return cameraMatrix;
}

GLKMatrix4 cvARManager::getProjectionMatrix() {
    return projectionMatrix;
}

bool cvARManager::isTracked() {
    return is_tracked;
}

void cvARManager::processImage(cv::Mat& image) {
//    cv::Mat overdrawn(image.size(), image.type());
    
    if (saveNext) {
        static int img_idx = 0;
        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", img_idx++]];
        
        // Save image.
        [UIImagePNGRepresentation(UIImageFromCVMat(image)) writeToFile:filePath atomically:YES];
        saveNext = false;
    }
    
    setBgImage(image);

    if (!worker_busy && do_tracking) {
        // Obtain mutex for this scope
        std::unique_lock<std::mutex> lk(worker_mutex);
        
        worker_busy = true;
        image.copyTo(latest_frame);
        worker_cond_var.notify_one();
    }
    if (frames_to_capture) {
        // wake up the tracking thread
        std::unique_lock<std::mutex> lk(worker_mutex);
        
        captured_frames.push_back(image.clone());
        frames_to_capture--;
        worker_cond_var.notify_one();
    }
}

void cvARManager::performTracking() {
    // image that will be processed
    cv::Mat frame;
    // A copy that will be left unmodified by the crop operation. Only nececsary when not processing live
    cv::Mat frame_copy;
    bool processed_live_frame = false;
    
    // Only need to hold the mutex for this block, since we modify worker_busy and captured_frames here
    {
        std::unique_lock<std::mutex> lk(worker_mutex);
        // Wait only if there is no work to do, either in the form of live data in latest_frame, or captured data in captured_frames
        // Also only wait if we're supposed to be alive
        while (!worker_busy && !captured_frames.size() && thread_live) {
            worker_cond_var.wait(lk);
        }
        if (!thread_live) {
            // Thread was told to end, so return
            return;
        }
        // Process captured frames with higher priority
        if (captured_frames.size()) {
            frame = captured_frames.front();
            captured_frames.pop_front();
            frame_copy = frame.clone();
        }
        else {
            frame = latest_frame;
            processed_live_frame = true;
        }
    }
    
    MaskedImage masked(frame);
    cv::Mat cropped = masked.getCropped();
    auto correspondences = matcher.getMatches(cropped);
    masked.uncropPoints(correspondences.img_pts);
    
    // Number of consecutive missed frames in tracking
    static int missed_frames = 0;
    
    if (correspondences.img_pts.size() >= 5) {
        cv::Mat mask;

        cv::Mat rotation, rotation_vec;
        cv::Mat translation;

        std::vector<cv::Point3f> correspondence_model_pts3(correspondences.model_pts.size());
        for (size_t i = 0; i < correspondences.model_pts.size(); ++i) {
            const auto& model_pt = model_pts_3d[correspondences.model_pts[i]];
            correspondence_model_pts3[i] = model_pt;
        }
        std::vector<float> dist_coeffs;
//        cv::solvePnP(correspondence_model_pts3, correspondences.img_pts, intrinsic_mat, dist_coeffs, rotation_vec, translation);
        cv::Mat pnp_inliers;
        cv::solvePnPRansac(correspondence_model_pts3, correspondences.img_pts, intrinsic_mat, dist_coeffs, rotation_vec, translation,
                           false, // useExtrinsicGuess
                           100, // iterationsCount
                           8.0, // reprojectionError
                           0.99, // confidence
                           pnp_inliers);
        std::cout << pnp_inliers.size[0] << " inliers" << std::endl;
        cv::Rodrigues(rotation_vec, rotation);

//        std::cout << "Rotation:\n" << rotation << std::endl;
        std::cout << "Translation:\n" << translation << std::endl;
        
        cv::Mat cvExtrinsic(4, 4, CV_64F);
        // copy rotation matrix into a larger 4x4 transformation matrix
        rotation.copyTo(cvExtrinsic.colRange(0, 3).rowRange(0, 3));

        translation.copyTo(cvExtrinsic.col(3).rowRange(0,3));
        cvExtrinsic.row(3).setTo(0);
        cvExtrinsic.at<double>(3,3) = 1;
        cv::Mat inverted = cvExtrinsic.inv();

        // Transform the OpenCV camera matrix into the compatible format for SceneKit
        cv::Mat skExtrinsic(inverted);
        // Set new bottom row to be the old rightmost column
        skExtrinsic.col(3).copyTo(skExtrinsic.row(3).reshape(0,4));
        // clear rightmost column
        skExtrinsic.col(3).setTo(0);
        skExtrinsic.at<double>(3,3) = 1;
        // negate the necessary elements (why?)
        auto negate = [&skExtrinsic](int row, int col) {skExtrinsic.at<double>(row,col) = -skExtrinsic.at<double>(row,col);};
        negate(1,2);
        negate(2,1);
        negate(3,1);
        negate(3,2);
        
        // Apply transformation to account for where the reference (model) image was taken from
//        static const double y_angle = 0.174;
//        static double rot_mat_data[16] = {
//            std::cos(y_angle), 0, 0, 0,
//            0, , -std::sin(y_angle), 0,
//            0, std::sin(y_angle), std::cos(y_angle), 0,
//            0, 0, 0, 1
//        };
//        static const cv::Mat rot_mat(3, 3, CV_64F, rot_mat_data);
        GLKMatrix4 rotMat_y = GLKMatrix4MakeYRotation(0.2 + M_PI);
        GLKMatrix4 rotMat_x = GLKMatrix4MakeXRotation(0.2);
        GLKMatrix4 rotMat = GLKMatrix4Multiply(rotMat_y, rotMat_x);
        
        
        GLKMatrix4 pose_estimate = GLKMatrix4Multiply(rotMat, CVMat4ToGLKMat4(skExtrinsic));
        
        // Keep the captured frame
        if (!processed_live_frame) {
            bool within_range = (translation.at<double>(0) > -15 && translation.at<double>(0) < 15 &&
                                 translation.at<double>(1) > -20 && translation.at<double>(1) < 20 &&
                                 translation.at<double>(2) > 150 && translation.at<double>(2) < 260);
            std::cout << "within range: " << within_range << std::endl;
            if (within_range) {
                // If within range, just accept it
                best_captured_pose = pose_estimate;
                best_captured_frame = frame_copy;
                frames_to_capture = 0;
                captured_frames.clear();
            }
            else if (pnp_inliers.size[0] > most_inliers) {
                    most_inliers = pnp_inliers.size[0];
                    best_captured_pose = pose_estimate;
                    best_captured_frame = frame_copy;
            }
        }
        else {
            // live tracking, so just go with the pose
            cameraMatrix = pose_estimate;
            is_tracked = true;
            missed_frames = 0;
        }
    }
    else {
        std::cout << "Not enough points for cv::recoverPose" << std::endl;
        // If live tracking say that tracking has been lost when we miss 5 frames in a row
        if (processed_live_frame) {
            missed_frames++;
            if (missed_frames >= 5) {
                is_tracked = false;
            }
        }
    }
    if (processed_live_frame) {
        std::unique_lock<std::mutex> lk(worker_mutex);
        worker_busy = false;
    }
    else {
        // If we're done processing frames
        // Could be due to finding an acceptable solution or running out of attempts. Regardless, we want to return the best guess
        if (frames_to_capture == 0 && !captured_frames.size()) {
            is_tracked = true;
            cameraMatrix = best_captured_pose;
            frame_callback(DONE_CAPTURING);
            setBgImage(best_captured_frame);
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////
//                               OpenCV Utilities
/////////////////////////////////////////////////////////////////////////////////


cv::Mat cvMatFromUIImage(UIImage* image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    cv::cvtColor(cvMat, cvMat, CV_RGBA2BGRA);
    
    return cvMat;
}

// TODO: Do returned UIImage* objects from here need to be manually deleted? Or does ARC work?
UIImage* UIImageFromCVMat(cv::Mat cvMat)
{
    
    cv::cvtColor(cvMat, cvMat, CV_BGRA2RGBA);
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

GLKMatrix4 CVMat3ToGLKMat4(const cv::Mat& cvMat) {
    GLKMatrix4 glkMat;
    glkMat.m00 = cvMat.at<double>(0, 0);
    glkMat.m01 = cvMat.at<double>(0, 1);
    glkMat.m02 = cvMat.at<double>(0, 2);
    
    glkMat.m10 = cvMat.at<double>(1, 0);
    glkMat.m11 = cvMat.at<double>(1, 1);
    glkMat.m12 = cvMat.at<double>(1, 2);
    
    glkMat.m20 = cvMat.at<double>(2, 0);
    glkMat.m21 = cvMat.at<double>(2, 1);
    glkMat.m22 = cvMat.at<double>(2, 2);
    return glkMat;
}

GLKMatrix4 CVMat4ToGLKMat4(const cv::Mat& cvMat) {
    // Copy the upper 3x3
    GLKMatrix4 glkMat = CVMat3ToGLKMat4(cvMat);
    
    // then copy the last column and row
    glkMat.m30 = cvMat.at<double>(3, 0);
    glkMat.m31 = cvMat.at<double>(3, 1);
    glkMat.m32 = cvMat.at<double>(3, 2);
    
    
    glkMat.m03 = cvMat.at<double>(0, 3);
    glkMat.m13 = cvMat.at<double>(1, 3);
    glkMat.m23 = cvMat.at<double>(2, 3);
    glkMat.m33 = cvMat.at<double>(3, 3);
    return glkMat;
}
