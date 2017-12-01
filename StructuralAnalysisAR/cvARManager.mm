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
: worker_busy(false) {
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
    MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:video_width height:video_height mipmapped:NO];
    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    videoTexture = [gpu newTextureWithDescriptor:texDescription];
    scene.background.contents = videoTexture;
    
    // Allocate space for frame to hold frame being processed for tracking
    working_frame = cv::Mat(video_height, video_width, CV_8UC4);
    // start background worker thread to perform tracking
    worker_thread = std::thread([this] () {while (1) performTracking();});
    
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
    double intr_data[9] = {3322.232, 0, 1994.099,
                           0, 3289.874, 1426.956,
                           0, 0, 1};
//    double intr_data[9] = {1054.603, 0, 633.047,
//                           0, 783.303, 339.751,
//                           0, 0, 1};
//    double intr_data[9] = {1049, 0, 640,
//        0, 1049, 360,
//        0, 0, 1};
    cv::Mat raw_intrinsic_mat(3, 3, CV_64F, intr_data);
    intrinsic_mat = cv::getOptimalNewCameraMatrix(raw_intrinsic_mat, std::vector<float>(4, 0), cv::Size(4032,3024), 0, cv::Size(video_width,video_height));

//    intrinsic_mat = cv::Mat(3, 3, CV_64F, intr_data);
    // Transform to account for crop
    
    // Load reference image
#ifdef HIGH_RES
    UIImage* bgImage = [UIImage imageNamed:@"cutout_skywalk_3840x2160.png"];
#else
    UIImage* bgImage = [UIImage imageNamed:@"cutout_skywalk_1920x1080.png"];
#endif
//    matcher = ImageMatcher(cvMatFromUIImage(bgImage), 6000, 0.75, 0.9, 3.0, std::cout); // for 1280x720
    matcher = ImageMatcher(cvMatFromUIImage(bgImage), 6000, 0.8, 0.98, 4.0, std::cout); // for 3840x2160
    
    
    // Copy image to background Metal texture
//    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
//    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:cvMatFromUIImage(bgImage).data bytesPerRow:(video_width*4)];
}

void cvARManager::doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) {
    captured_frames.clear();
    captured_poses.clear();
    frames_to_capture = n_avg;
    frame_callback = cb_func;
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
    return GLKMatrix4Identity;
}

id<MTLTexture> cvARManager::getBgTexture() {
    return nil;
}

GLKMatrix4 cvARManager::getBgMatrix() {
    return GLKMatrix4Identity;
}

void cvARManager::processImage(cv::Mat& image) {
    // Negative value means flip in both X and Y axes
    cv::flip(image, image, -1);
//    cv::Mat overdrawn(image.size(), image.type());
    
    // Copy image to background Metal texture
    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:image.data bytesPerRow:(video_width*4)];

    if (!worker_busy && do_tracking) {
        // Obtain mutex for this scope
        std::unique_lock<std::mutex> lk(worker_mutex);
        
        worker_busy = true;
        image.copyTo(working_frame);
        worker_cond_var.notify_one();
    }
    if (frames_to_capture) {
        captured_frames.push_back(image.clone());
        frames_to_capture--;
        // wake up the tracking thread
        worker_cond_var.notify_one();
        // All frames have been captured, so notify callback
        if (!frames_to_capture) {
            frame_callback(DONE_CAPTURING);
        }
    }
}

void cvARManager::performTracking() {
    std::unique_lock<std::mutex> lk(worker_mutex);
    // Wait only if there is no work to do, either in the form of live data in working_frame, or captured data in captured_frames
    while (!worker_busy && !captured_frames.size()) {
        worker_cond_var.wait(lk);
    }
    
    // image that will be processed
    cv::Mat frame;
    bool processed_live_frame = false;
    // Process captured frames with higher priority
    if (captured_frames.size()) {
        frame = captured_frames.front();
        captured_frames.pop_front();
    }
    else {
        frame = working_frame;
        processed_live_frame = true;
    }
    
    MaskedImage masked(frame);
    cv::Mat cropped = masked.getCropped();
    auto correspondences = matcher.getMatches(cropped);
    
    masked.uncropPoints(correspondences.img_pts);
    //    cv::Mat homography_mat;
    //    if (correspondences.img_pts.size() >= 4) {
    //        homography_mat = cv::findHomography(correspondences.img_pts, correspondences.model_pts, cv::RANSAC, 1);
    //    }
    //    else {
    //        std::cout << "error: not enough points for homography" << std::endl;
    //        homography_mat = cv::Mat::eye(3, 3, CV_32F);
    //    }
    //    std::cout << "Homography matrix: " << std::endl << homography_mat << std::endl;
    
    //    cv::Mat warped_img = cv::Mat(frame.size(), frame.type());
    //    if (homography_mat.dims) {
    //        warpPerspective(frame, warped_img, homography_mat, warped_img.size(), cv::INTER_LINEAR);
    //    }
    
    if (correspondences.img_pts.size() >= 5) {
        cv::Mat mask;
        //        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, intrinsic_mat, cv::RANSAC);
        //        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, cv::RANSAC);
        //        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, 1.0, cv::Point2d(0, 0), cv::RANSAC, 0.999, 1.0, mask);
        //        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, intrinsic_mat, cv::RANSAC, 0.999, 1.0, mask);
        //        std::cout << "Essential matrix: " << std::endl << essential_mat << std::endl;
        cv::Mat rotation, rotation_vec;
        cv::Mat translation;
        //        int n_inliers = cv::recoverPose(essential_mat, correspondences.img_pts, correspondences.model_pts, intrinsic_mat, rotation, translation);
        //        int n_inliers = cv::recoverPose(essential_mat, correspondences.img_pts, correspondences.model_pts, rotation, translation, 1.0, cv::Point2d(0, 0), mask);
        //        int n_inliers = cv::recoverPose(essential_mat, correspondences.img_pts, correspondences.model_pts, intrinsic_mat, rotation, translation, mask);
        
        // convert 2d model points to 3d model points
        // TODO: This can be done once
        std::vector<cv::Point3f> model_pts3(correspondences.model_pts.size());
        const float model_width = 154;
        const float model_height = (model_width * ((double)video_height / video_width));
        for (size_t i = 0; i < correspondences.model_pts.size(); ++i) {
            model_pts3[i].x = correspondences.model_pts[i].x * (model_width / video_width) - (model_width / 2);
            //            model_pts3[i].y = (720 - correspondences.model_pts[i].y) * (115.0 / 720.0);
            model_pts3[i].y = correspondences.model_pts[i].y * (model_height / video_height) - (model_height / 2);
            model_pts3[i].z = 0;
            //            cv::circle(overdrawn, correspondences.img_pts[i], 4, cv::Scalar(0, 0, 255));
        }
        //        static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
        //        [videoTexture replaceRegion:region mipmapLevel:0 withBytes:overdrawn.data bytesPerRow:(video_width*4)];
        
        std::vector<float> dist_coeffs;
        //        cv::solvePnP(model_pts3, correspondences.img_pts, intrinsic_mat, dist_coeffs, rotation_vec, translation);
        cv::solvePnPRansac(model_pts3, correspondences.img_pts, intrinsic_mat, dist_coeffs, rotation_vec, translation);
        cv::Rodrigues(rotation_vec, rotation);
        //        rotation = rotation.inv();
        //        rotation = rotation.t();
        
        
        
        //        std::cout << n_inliers << " inliers" << std::endl;
//        std::cout << "Rotation:\n" << rotation << std::endl;
//        std::cout << "Translation:\n" << translation << std::endl;
        
        cv::Mat cvExtrinsic(4, 4, CV_64F);
        // copy rotation matrix into a larger 4x4 transformation matrix
        rotation.copyTo(cvExtrinsic.colRange(0, 3).rowRange(0, 3));
        
//        extrinsic.at<double>(0,3) = translation.at<double>(0) * scale;
//        extrinsic.at<double>(1,3) = translation.at<double>(0) * scale;
//        extrinsic.at<double>(2,3) = translation.at<double>(0) * scale;
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
        
//        std::cout << skExtrinsic << std::endl;
        // Keep the captured frame
        if (!processed_live_frame) {
            captured_poses.push_back(skExtrinsic);
        }
        
        cameraMatrix = CVMat4ToGLKMat4(skExtrinsic);
        
//        GLKMatrix4 extrinsic = CVMat3ToGLKMat4(rotation);
//        extrinsic.m03 = translation.at<double>(0) * scale;
//        extrinsic.m13 = translation.at<double>(1) * scale;
//        extrinsic.m23 = translation.at<double>(2) * scale;
//        extrinsic.m33 = 1.0;
//        bool invertible;
//        GLKMatrix4 inverted = GLKMatrix4Invert(extrinsic, &invertible); // inverse matrix!
//        assert(invertible);
//        cameraMatrix = GLKMatrix4Make(inverted.m00,  inverted.m01,   inverted.m02, 0,
//                                      inverted.m10,  inverted.m11,  -inverted.m12, 0,
//                                      inverted.m20,  -inverted.m21,  inverted.m22, 0,
//                                      inverted.m03, -inverted.m13, -inverted.m23, 1);
        
        
        //        cameraMatrix.m31 += 57;
        //        cameraMatrix.m32 += 50;
        //        cameraMatrix = GLKMatrix4Transpose(inverted);
        //        cameraMatrix.m30 = -cameraMatrix.m30;
        //        cameraMatrix.m31 = -cameraMatrix.m31;
        //        cameraMatrix.m32 = -cameraMatrix.m32;
        //        GLKMatrix4 rot_mat = GLKMatrix4MakeXRotation(M_PI);
        //        cameraMatrix = GLKMatrix4Multiply(rot_mat, cameraMatrix);
        //        cameraMatrix.m30 = translation.at<double>(0) * scale;
        //        cameraMatrix.m31 = translation.at<double>(1) * scale;
        //        cameraMatrix.m32 = translation.at<double>(2) * scale;
    }
    else {
        std::cout << "Not enough points for cv::recoverPose" << std::endl;
    }
    if (processed_live_frame) {
        worker_busy = false;
    }
    else {
        // If we just processed the last frame to capture
        if (frames_to_capture == 0 && !captured_frames.size()) {
            // TODO: Average
            cameraMatrix = CVMat4ToGLKMat4(captured_poses[0]);
        }
        frame_callback(PROCESSED_FRAME);
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
