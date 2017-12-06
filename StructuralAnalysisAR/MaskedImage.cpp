#include <cmath>
#include <algorithm>

#include "MaskedImage.hpp"
#include "EdgeClipper.hpp"

#include <opencv2/imgproc/imgproc.hpp>

#define MASKED_IMAGE_LOG

using namespace cv;

Vec4i paramToLine(Vec2d line_param, const Size img_size, float len=3000);

MaskedImage::MaskedImage(const Mat img, std::ostream& log)
    : log(log)
    , orig_img(img) {
}

Mat MaskedImage::getCropped() {
    // If image hasn't been cropped yet, we need to compute ti
    if (!cropped_img.data) {
        findSkywalk();
        int mask_margin = orig_img.size[0] * 0.01225;
        int mask_height = orig_img.size[0] * 0.164;

        if (found_skywalk) {
            top_crop = std::min(skywalk_topline[1], skywalk_topline[3]) - mask_margin;
            bottom_crop = std::max(skywalk_topline[1], skywalk_topline[3]) + mask_height + mask_margin;
        }
        else {
            top_crop = 0; bottom_crop = orig_img.size().height;
        }
        // Keep crops within bounds
        top_crop = std::max(0, top_crop);
        bottom_crop = std::min(orig_img.size().height, bottom_crop);
        
        Rect crop_window(0, top_crop, orig_img.size().width, bottom_crop - top_crop);
        cropped_img = Mat(orig_img, crop_window);

        // Now mask it
        // The top line coordinates in the cropped image
        Vec4i topline_cropped = skywalk_topline - Vec4i(0, top_crop, 0, top_crop);
        int visible_height = mask_height + (2 * mask_margin);
        Vec4i bottomline_cropped = topline_cropped + Vec4i(0, visible_height, 0, visible_height);
        // Mask for above the skywalk
        Point poly_mask_upper[4] = {
            Point(0, 0),
            Point(topline_cropped[2], 0),
            Point(topline_cropped[2], topline_cropped[3]),
            Point(0, topline_cropped[1]),
        };
        int cropped_height = bottom_crop - top_crop;
        Point poly_mask_lower[4] = {
            Point(0, bottomline_cropped[1]),
            Point(bottomline_cropped[2], bottomline_cropped[3]),
            Point(bottomline_cropped[2], cropped_height),
            Point(0, cropped_height)
        };
        const Point* all_polys[2] = {poly_mask_upper, poly_mask_lower};
        int n_pts[2] = {4, 4};
        fillPoly(cropped_img, all_polys, n_pts, 2, cv::Scalar(0));
    }

    return cropped_img;
}


void MaskedImage::findSkywalk() {
    auto lines = findLines(true);
    // 0.6 of width required
    int min_length = 0.6 * orig_img.size[1];
    float min_length2 = min_length * min_length;
    auto avgY = [](const Vec4i& v) {return (v[1] + v[3]) / 2.f;};
    Vec4i best_line;
    float best_y = std::numeric_limits<float>::max();
    for (size_t i = 0; i < lines.size(); ++i) {
        const Vec4i& line = lines[i];
        float delta_x = line[2] - line[0];
        float delta_y = line[3] - line[1];
        float length2 = (delta_x*delta_x + delta_y*delta_y);
        // delta_x != 0 avoids divide by zero. We don't want vertical lines anyway
        if (length2 >= min_length2 && delta_x != 0) {
            float theta = std::atan(delta_y / delta_x);
            if (std::abs(theta) < (15.f / 180) * M_PI) {
                // flat enough, take the highest
                float new_y = avgY(line);
                if (new_y < best_y) {
                    best_line = line;
                    best_y = new_y;
                }
            }
        }
    }

    if (best_y == std::numeric_limits<float>::max()) {
        // no valid lines were found
        // assert(false);
#ifdef MASKED_IMAGE_LOG
        log << "error: did not find a skywalk line" << std::endl;
#endif
        found_skywalk = false;
    }
    else {
        found_skywalk = true;
    }

    skywalk_topline = best_line;
}

std::vector<Vec4i> MaskedImage::findLines(bool probabilistic) {
    Mat yuv_img;
    yuv_img.create(orig_img.size(), orig_img.type());

    Mat gray_img;
    cvtColor(orig_img, yuv_img, CV_BGR2YUV);
    extractChannel(yuv_img, gray_img, 0);

    blur(gray_img, gray_img, Size(3, 3));

    // Mat edge_img.create(single_chnl.size(), single_chnl.type());
    int lowThreshold = 80;
    Canny(gray_img, gray_img, lowThreshold, lowThreshold * 3, 3);
    
    // imwrite("edges_0038.png", gray_img);
    // namedWindow("window");
    // resize(gray_img, gray_img, Size(0, 0), 0.5, 0.5);
    // imshow("window", gray_img);
    // waitKey(0);
    
    std::vector<Vec4i> lines;
    if (probabilistic) {
        // HoughLinesP(gray_img, lines, 1, 1 * CV_PI/180, 50, 90, 20);
        HoughLinesP(gray_img, lines, 1, 1 * CV_PI/180, 200, 50, 300);
    }
    else {
        std::vector<Vec2f> lines_full;
        int threshold = (280.0 / 3264) * orig_img.size().width;
        HoughLines(gray_img, lines_full, 0.5, 0.5 * CV_PI/180, threshold);
        for (const Vec2f& line_param : lines_full) {
            lines.push_back(paramToLine(line_param, orig_img.size(), orig_img.size[1] * 2));
        }
    }

    return lines;
}

Vec4i paramToLine(Vec2d line_param, const Size img_size, float len) {
        float rho = line_param[0];
        float theta = line_param[1];
        double a = std::cos(theta);
        double b = std::sin(theta);
        double x0 = a*rho, y0 = b*rho;
        Point pt1, pt2;
        Vec4i endpoints = Vec4i(cvRound(x0 - b * len),
                            cvRound(y0 + a * len),
                            cvRound(x0 + b * len),
                            cvRound(y0 - a * len));
        Vec4i clipped = EdgeClipper::clipLine(endpoints, img_size);
        return clipped;
}
