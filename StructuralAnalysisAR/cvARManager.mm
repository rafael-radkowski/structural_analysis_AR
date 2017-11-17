//
//  cvARManager.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/16/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//


#include "cvARManager.h"

#import <GLKit/GLKMatrix4.h>

// Utility functions (defined at bottom)
cv::Mat cvMatFromUIImage(UIImage* image);
UIImage* UIImageFromCVMat(cv::Mat cvMat);
GLKMatrix4 CVMat3ToGLKMat4(const cv::Mat& cvMat);


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
    // Set up camera callbacks
    camera = [[CvVideoCamera alloc] initWithParentView:nil];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
//    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset3840x2160;
    camera.defaultFPS = 30;
    // Make lambda for calling this->processImage(). Lets the callback not have to worry that its a member function
    auto this_processImage = [this](cv::Mat& img) {processImage(img);};
    camDelegate = [[CvCameraDelegateObj alloc] initWithCallback:this_processImage];
    camera.delegate = camDelegate;
    
    video_width = 1280;
    video_height = 720;
    
    
    // Create texture for holding video
    MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:video_width height:video_height mipmapped:NO];
    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    videoTexture = [gpu newTextureWithDescriptor:texDescription];
    scene.background.contents = videoTexture;
    
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
    double intr_data[9] = {1049, 0, 640,
        0, 1049, 360,
        0, 0, 1};
    intrinsic_mat = cv::Mat(3, 3, CV_64F, intr_data);
    // Transform to account for crop
    
    // Load reference image
    UIImage* bgImage = [UIImage imageNamed:@"cutout_skywalk_1280x720.png"];
//    matcher = ImageMatcher(cvMatFromUIImage(bgImage), 6000, 0.75, 0.9, 3.0, std::cout); // for 1280x720
    matcher = ImageMatcher(cvMatFromUIImage(bgImage), 4000, 0.85, 0.98, 4.0, std::cout); // for 3840x
    
    
    // Copy image to background Metal texture
//    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
//    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:cvMatFromUIImage(bgImage).data bytesPerRow:(video_width*4)];
    
    [camera start];
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
    
    // Copy image to background Metal texture
    static MTLRegion region = MTLRegionMake2D(0, 0, video_width, video_height);
    [videoTexture replaceRegion:region mipmapLevel:0 withBytes:image.data bytesPerRow:(video_width*4)];
    
    MaskedImage masked(image);
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
    
//    cv::Mat warped_img = cv::Mat(image.size(), image.type());
//    if (homography_mat.dims) {
//        warpPerspective(image, warped_img, homography_mat, warped_img.size(), cv::INTER_LINEAR);
//    }
    
    if (correspondences.img_pts.size() >= 5) {
//        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, intrinsic_mat, cv::RANSAC);
        cv::Mat essential_mat = cv::findEssentialMat(correspondences.img_pts, correspondences.model_pts, cv::RANSAC);
        std::cout << "Essential matrix: " << std::endl << essential_mat << std::endl;
        cv::Mat rotation;
        cv::Mat translation;
//        int n_inliers = cv::recoverPose(essential_mat, correspondences.img_pts, correspondences.model_pts, intrinsic_mat, rotation, translation);
        int n_inliers = cv::recoverPose(essential_mat, correspondences.img_pts, correspondences.model_pts, rotation, translation);
        std::cout << n_inliers << " inliers" << std::endl;
        std::cout << "Rotation:\n" << rotation << std::endl;
        std::cout << "Translation:\n" << translation << std::endl;
        
        float scale = 100;
        cameraMatrix = CVMat3ToGLKMat4(rotation);
        cameraMatrix.m30 = -translation.at<double>(0) * scale;
        cameraMatrix.m31 = -translation.at<double>(1) * scale;
        cameraMatrix.m32 = -translation.at<double>(2) * scale;
        cameraMatrix.m33 = 1.0;
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
