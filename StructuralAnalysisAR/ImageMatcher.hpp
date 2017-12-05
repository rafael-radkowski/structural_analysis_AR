#pragma once

#include <string>
#include <vector>
#include <iostream>

#include <opencv2/core/core.hpp>
#include <opencv2/calib3d/calib3d.hpp>
//#include <opencv2/xfeatures2d.hpp>

class ImageMatcher {
public:
    // matching functions will not work if you only use the default constructor. But it's suitable for placeholder initialization
    ImageMatcher() {}
    ImageMatcher(const cv::Mat& ref_img, int n_features, double ratio, double ransac_confidence, double ransac_dist, std::ostream& out_log = std::cout);

    struct Correspondences {
        std::vector<size_t> model_pts;
        std::vector<cv::Point2f> img_pts;
    };
    Correspondences getMatches(const cv::Mat test_img);
    
    // the keypoints found in the reference image
    const std::vector<cv::KeyPoint>& getRefKeypoints() const;
private:
    std::ostream* log;

    cv::Ptr<cv::DescriptorMatcher> feat_matcher;
    cv::Ptr<cv::Feature2D> feat_detector;
    cv::Ptr<cv::Feature2D> feat_extractor;

    cv::Mat ref_img;
    cv::Mat ref_descriptors;
    std::vector<cv::KeyPoint> ref_keypoints;

    double ratio;
    double ransac_confidence;
    double ransac_distance;

    int ratioTest(std::vector<std::vector<cv::DMatch> > &matches);

    /*****************************************************************************
     // Identify good matches using RANSAC
    // Return valid matches
    */
    std::vector<cv::DMatch> ransacTest(const std::vector<cv::DMatch> &matches,
                                       const std::vector<cv::KeyPoint> &keypoints1,
                                       const std::vector<cv::KeyPoint> &keypoints2);
};
