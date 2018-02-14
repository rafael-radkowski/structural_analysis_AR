#include <vector>
#include <iostream>

#include <opencv2/core/core.hpp>

class MaskedImage {
public:
    // line_angle and line_origin define what to compare the detected lines against
    // The mask will grow in the direction to the left of the vector. e.g. to grow it downward, line_angle should be (-1,0)
    MaskedImage(const cv::Mat img, int edge_threshold, float min_length, cv::Vec2f line_angle, cv::Vec2f line_origin, float angle_deviation, std::ostream& log = std::cout);
    cv::Mat getCropped();

    std::vector<cv::Vec4i> findLines(bool probabilistic);
    // Converts coordinates from cropped image to original image
    template <typename T>
    void uncropPoints(std::vector<cv::Point_<T>>& points);
    // Converts coordinates from original image to cropped image
    template <typename T>
    void cropPoints(T& points);
    template <typename T>
    void uncropPoint(cv::Point_<T>& point);
private:
    std::ostream& log;
    void findObject();

    cv::Mat orig_img;
    cv::Mat cropped_img;
    bool found_object = false;
    cv::Vec4i object_topline;

    cv::Vec3f ref_line_eqn;
    cv::Vec2f line_angle;

    float min_length, angle_deviation;
    int edge_threshold;

    cv::Rect crop_window;
};

template <typename T>
void MaskedImage::uncropPoints(std::vector<cv::Point_<T>>& points) {
   for (auto& point : points) {
       point.y += crop_window.y;
       point.x += crop_window.x;
   } 
}

template <typename T>
void MaskedImage::uncropPoint(cv::Point_<T>& point) {
    point.x += crop_window.x;
    point.y += crop_window.y;
}

template <typename T>
void MaskedImage::cropPoints(T& points) {
   for (auto& point : points) {
       point.y -= crop_window.y;
       point.x -= crop_window.x;
   } 
}
