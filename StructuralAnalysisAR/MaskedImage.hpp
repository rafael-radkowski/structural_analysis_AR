#include <vector>
#include <iostream>

#include <opencv2/core/core.hpp>

class MaskedImage {
public:
    MaskedImage(const cv::Mat img, std::ostream& log = std::cout);
    cv::Mat getCropped();

    std::vector<cv::Vec4i> findLines(bool probabilistic);
    template <typename T>
    void uncropPoints(std::vector<cv::Point_<T>>& points);
private:
    std::ostream& log;
    void findSkywalk();

    cv::Mat orig_img;
    cv::Mat cropped_img;
    bool found_skywalk = false;
    cv::Vec4i skywalk_topline;

    int top_crop, bottom_crop;
};

template <typename T>
void MaskedImage::uncropPoints(std::vector<cv::Point_<T>>& points) {
   // We just need to add the area removed from above
   for (auto& point : points) {
       point.y += top_crop;
   } 
}