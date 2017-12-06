#include "ImageMatcher.hpp"

#include <chrono>

//#define IMAGE_MATCHER_LOG

using namespace cv;
using std::vector;
using std::endl;

ImageMatcher::ImageMatcher(const Mat& ref_img, int n_features, double ratio, double ransac_confidence, double ransac_distance, std::ostream& out_log)
    : log(&out_log)
    , ref_img(ref_img)
    , ratio(ratio)
    , ransac_confidence(ransac_confidence)
    , ransac_distance(ransac_distance) {
    // feat_matcher = FlannBasedMatcher::create();
    // feat_extractor = xfeatures2d::SIFT::create(2000);
    feat_matcher = BFMatcher::create(NORM_HAMMING, false);
    feat_extractor = ORB::create(n_features);
    feat_detector = feat_extractor;

    // feat_extractor = xfeatures2d::FREAK::create();
    // feat_detector = AgastFeatureDetector::create();

    // Extract features from reference
    feat_detector->detect(ref_img, ref_keypoints);
    feat_extractor->compute(ref_img, ref_keypoints, ref_descriptors);
#ifdef IMAGE_MATCHER_LOG
    *log << "Ref image has " << ref_keypoints.size() << " descriptors" << std::endl;
#endif

    // Train matcher on reference features
    auto ref_db = vector<Mat>({ref_descriptors});
    feat_matcher->add(ref_db);
    feat_matcher->train();
}

const std::vector<cv::KeyPoint>& ImageMatcher::getRefKeypoints() const {
    return ref_keypoints;
}

ImageMatcher::Correspondences ImageMatcher::getMatches(const cv::Mat test_img) {
    // Find keypoints and descriptors
    vector<KeyPoint> keypoints;
    Mat descriptors;
    auto start_time = std::chrono::high_resolution_clock::now();
    feat_detector->detect(test_img, keypoints);
    feat_extractor->compute(test_img, keypoints, descriptors);

    Correspondences corr;

    // Initial matches
    vector<vector<DMatch>> matches;
    auto query_db = vector<Mat>({descriptors});
    feat_matcher->knnMatch(descriptors, matches, 2);
    // feat_matcher->knnMatch(ref_descriptors, descriptors, matches, 2);

    // std::vector<DMatch> matches;
    // feat_matcher->match(descriptors, matches);
#ifdef IMAGE_MATCHER_LOG
    *log << "Found " << matches.size() << " original matches" << endl;
#endif

    // Remove ones which fail the ratio test
    int matches_removed = ratioTest(matches);
    // int matches_removed = 0;
#ifdef IMAGE_MATCHER_LOG
    *log << "Removed " << matches_removed << " matches with ratio test" << endl;
#endif

    // Take just the top match
    vector<DMatch> top_matches;
    for (const auto& m : matches) {
        if (m.size() >= 1) {
            top_matches.push_back(m[0]);
        }
    }
    // auto top_matches = matches;

    if (top_matches.size() < 4) {
        // Write 0 matches for log consistency
#ifdef IMAGE_MATCHER_LOG
        *log << "After RANSAC, 0 matches" << endl;
#endif
        return corr;
    }

    // Epipolar test
    auto final_matches = ransacTest(top_matches, keypoints, ref_keypoints);

#ifdef IMAGE_MATCHER_LOG
    *log << "After RANSAC, " << final_matches.size() << " matches" << endl;
#endif

    // if (final_matches.size() < 4) {
    //     log << "error: not enough points, skipping homography" << std::endl;
    //     return Mat::eye(3, 3, CV_32F);
    // }

    // 2D points from matches
    corr.model_pts.reserve(final_matches.size()); corr.img_pts.reserve(final_matches.size());
    for (const auto& match : final_matches) {
//        corr.model_pts.push_back(ref_keypoints[match.trainIdx].pt);
        corr.model_pts.push_back(match.trainIdx);
        corr.img_pts.push_back(keypoints[match.queryIdx].pt);
    }
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
#ifdef IMAGE_MATCHER_LOG
    *log << "Took " << duration_ms.count() << " ms to perform matching" << std::endl;
#endif
    return corr;
    
    // Mat homography_mat = cv::findHomography(img_pts, model_pts, cv::RANSAC /*CV_LMEDS*/, 1);

    // return homography_mat;
}


int ImageMatcher::ratioTest(vector<vector<cv::DMatch> > &matches) {
    int removed=0;
    // for all matches
    for (vector<vector<cv::DMatch> >::iterator matchIterator= matches.begin();
         matchIterator!= matches.end();
         ++matchIterator)
    {
        
        // if 2 NN has been identified
        if (matchIterator->size() > 1)
        {
            // check distance ratio
            if ((*matchIterator)[0].distance/(*matchIterator)[1].distance > ratio)
            {
                matchIterator->clear(); // remove match
                removed++;
            }
        } else
        { // does not have 2 neighbours
            matchIterator->clear(); // remove match
            removed++;
        }
    }
    return removed;
}

vector<DMatch> ImageMatcher::ransacTest(const vector<cv::DMatch> &matches,
                                             const vector<cv::KeyPoint> &keypoints1,
                                             const vector<cv::KeyPoint> &keypoints2) {
    // Convert keypoints into Point2f
    vector<cv::Point2f> points1, points2;
    for (vector<cv::DMatch>::
             const_iterator it = matches.begin();
         it != matches.end(); ++it)

    {
        // Get the position of left keypoints
        float x = keypoints1[it->queryIdx].pt.x;
        float y = keypoints1[it->queryIdx].pt.y;
        points1.push_back(cv::Point2f(x, y));

        // Get the position of right keypoints
        x = keypoints2[it->trainIdx].pt.x;
        y = keypoints2[it->trainIdx].pt.y;
        points2.push_back(cv::Point2f(x, y));
    }

    // Compute F matrix using RANSAC
    vector<uchar> inliers;
    cv::Mat fundemental = cv::findFundamentalMat(cv::Mat(points1), cv::Mat(points2), // matching points
                                                 CV_FM_RANSAC,                       // RANSAC method
                                                 ransac_distance,                          // distance to epipolar line
                                                 ransac_confidence,                       // confidence probability
                                                 inliers);                         // match status (inlier or outlier)

    // extract the surviving (inliers) matches
    vector<DMatch> outMatches;
    vector<uchar>::const_iterator
        itIn = inliers.begin();
    vector<cv::DMatch>::const_iterator
        itM = matches.begin();
    // for all matches
    for (; itIn != inliers.end(); ++itIn, ++itM)
    {
        if (*itIn)
        { // it is a valid match
            outMatches.push_back(*itM);
        }
    }
    return outMatches;
}
