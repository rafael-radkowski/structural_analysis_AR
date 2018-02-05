#include <cmath>
#include <algorithm>
#include <array>

#include "MaskedImage.hpp"
#include "EdgeClipper.hpp"

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

#define MASKED_IMAGE_LOG

using namespace cv;

Vec4i paramToLine(Vec2d line_param, const Size img_size, float len=3000);

// Makes line equation in normal form from a point and a vector
template <typename T>
Vec<T,3> pointAngleToLine(Vec<T,2> origin, Vec<T,2> angle) {
    // Vec<T,3> line;
    // line[0] = angle[1];
    // line[1] = -angle[0];
    // line[2] = -origin[0]*angle[1] + angle[0]*origin[1];

    Vec<T,3> origin_homo(origin[0], origin[1], 1);
    Vec<T,3> point2_homo(origin[0] + angle[0], origin[1] + angle[1], 1);
    Vec<T,3> line = origin_homo.cross(point2_homo);

    // Normalize so third parameter is 1
    float norm_fac = std::sqrt(line[0]*line[0] + line[1]*line[1]);
    if (norm_fac != 0) {
        line /= norm_fac;
    }
    return line;
    
}

MaskedImage::MaskedImage(const Mat img, int edge_threshold, float min_length, Vec2f line_angle, Vec2f line_origin, float angle_deviation, std::ostream& log)
    : log(log)
    , orig_img(img)
    , line_angle(line_angle)
    , min_length(min_length)
    , angle_deviation(angle_deviation * (M_PI / 180.))
    , edge_threshold(edge_threshold) {
        ref_line_eqn = pointAngleToLine(line_origin, line_angle);
}

Mat MaskedImage::getCropped() {
    // If image hasn't been cropped yet, we need to compute ti
    if (!cropped_img.data) {
        findObject();
        int mask_margin = orig_img.size[0] * 0.01225;
        // int mask_width = orig_img.size[0] * 0.164;
        int mask_width = orig_img.size[0] * 0.08;

        if (found_object) {
            Vec2f raw_line_vec(object_topline[2] - object_topline[0], object_topline[3] - object_topline[1]);
            // Project reference line vector onto found (raw) line vector.
            // The resulting vector points along the found line, but in the direction of the reference vector.
            Vec2f projected_vec = raw_line_vec.dot(line_angle) * raw_line_vec;
            projected_vec  /= cv::norm(projected_vec);
            Vec2f found_line_origin(object_topline[0], object_topline[1]);

            // Rotate line_angle 90 degrees clockwise
            Vec2f mask_direction(-projected_vec[1], projected_vec[0]);
            Vec2f mask_line1_origin = found_line_origin - mask_direction * mask_margin;
            Vec2f mask_line2_origin = found_line_origin + mask_direction * (mask_margin + mask_width);

            Vec2f line1_endpoint1(mask_line1_origin - 10000 * projected_vec);
            Vec2f line1_endpoint2(mask_line1_origin + 10000 * projected_vec);
            Vec2f line2_endpoint1(mask_line2_origin - 10000 * projected_vec);
            Vec2f line2_endpoint2(mask_line2_origin + 10000 * projected_vec);
            EdgeClipper::clipLineCV(Size2f(orig_img.size()), line1_endpoint1, line1_endpoint2);
            EdgeClipper::clipLineCV(Size2f(orig_img.size()), line2_endpoint1, line2_endpoint2);

            auto x_range = std::minmax({line1_endpoint1[0], line1_endpoint2[0], line2_endpoint1[0], line2_endpoint2[0]});
            auto y_range = std::minmax({line1_endpoint1[1], line1_endpoint2[1], line2_endpoint1[1], line2_endpoint2[1]});
            crop_window = Rect(Point(x_range.first, y_range.first), Point(x_range.second, y_range.second));
        
            cropped_img = Mat(orig_img, crop_window);

            // The line endpoints will definitely be part of the triangle
            std::array<Point, 3> poly1_pts = {cv::Point(line1_endpoint1), cv::Point(line1_endpoint2), Point()};
            std::array<Point, 3> poly2_pts = {cv::Point(line2_endpoint1), cv::Point(line2_endpoint2), Point()};
            // Finding the last point of the triangle remains
            std::array<Point, 4> corners = {Point(crop_window.x, crop_window.y),
                                          Point(crop_window.x + crop_window.width, crop_window.y),
                                          Point(crop_window.x + crop_window.width, crop_window.y + crop_window.height),
                                          Point(crop_window.x, crop_window.y + crop_window.height)};
            // find corner which is furtherst from outside of each mask line
            Vec2f line1_normal = -mask_direction;
            Vec2f line2_normal = mask_direction;
            Vec3f line1_eqn = -pointAngleToLine(line1_endpoint1, projected_vec);
            Vec3f line2_eqn = pointAngleToLine(line2_endpoint1, projected_vec);
            
            // Finds the point furthest from a line (largest signed distance)
            auto furthest_pt = [&](const std::array<Point, 4>& search_pts, cv::Vec3f line_eqn) {
                float furthest_dist = -INFINITY;
                auto best_pt = search_pts[0];
                for (const auto& pt : search_pts) {
                    float dist = line_eqn.dot(Vec3f(pt.x, pt.y, 1));
                    if (dist >= 0 && dist > furthest_dist) {
                        best_pt = pt;
                        furthest_dist = dist;
                    }
                }
                return best_pt;
            };
            poly1_pts[2] = furthest_pt(corners, line1_eqn);
            poly2_pts[2] = furthest_pt(corners, line2_eqn);
            cropPoints(poly1_pts);
            cropPoints(poly2_pts);

            // Draw the mask
            const Point* all_polys[2] = {poly1_pts.data(), poly2_pts.data()};
            int n_pts[2] = {poly1_pts.size(), poly2_pts.size()};
            fillPoly(cropped_img, all_polys, n_pts, 2, cv::Scalar(0));
        }
        else {
            crop_window = Rect(0, 0, orig_img.size().width, orig_img.size().height);
            cropped_img = Mat(orig_img);
        }
    }

    return cropped_img;
}


void MaskedImage::findObject() {
    auto lines = findLines(true);
    // 0.6 of width required mask
    int min_length_px = min_length * orig_img.size[1];
    float min_length2_px = min_length_px * min_length_px;
    auto calc_center = [](const Vec4i& v) {return Vec3f((v[0]+v[2])/2, (v[1]+v[3])/2, 1);};
    Vec4i best_line;
    float best_dist = std::numeric_limits<float>::max();
    for (size_t i = 0; i < lines.size(); ++i) {
        const Vec4i& line = lines[i];
        float delta_x = line[2] - line[0];
        float delta_y = line[3] - line[1];
        Vec3f new_line_eqn(delta_y, -delta_x, line[0]*line[3] - line[2]*line[1]);
        // normalize
        if (new_line_eqn[2] != 0) {new_line_eqn /= new_line_eqn[2];}
        Point2f line_vec = Point2f(delta_x, delta_y);
        line_vec /= cv::norm(line_vec); // normalize
        float length2 = (delta_x*delta_x + delta_y*delta_y);
        // delta_x != 0 avoids divide by zero. We don't want vertical lines anyway
        if (length2 >= min_length2_px) {
            float theta = std::acos(line_vec.dot(line_angle));
            if (theta >= CV_PI / 2) {theta -= M_PI;}
            if (theta <= -CV_PI / 2) {theta += M_PI;}
            // float theta = std::atan(delta_y / delta_x);
            if (theta < angle_deviation) {
                Vec3f line_center = calc_center(line);
                float line_dist = std::abs(ref_line_eqn.dot(line_center));
                if (line_dist < best_dist) {
                    best_dist = line_dist;
                    best_line = line;
                }
            }
        }
    }

    if (best_dist == std::numeric_limits<float>::max()) {
        // no valid lines were found
        // assert(false);
#ifdef MASKED_IMAGE_LOG
        log << "error: did not find a object line" << std::endl;
#endif
        found_object = false;
    }
    else {
        found_object = true;
    }

    object_topline = best_line;
}

std::vector<Vec4i> MaskedImage::findLines(bool probabilistic) {
    Mat yuv_img;
    yuv_img.create(orig_img.size(), orig_img.type());

    Mat gray_img;
    cvtColor(orig_img, yuv_img, CV_BGR2YUV);
    extractChannel(yuv_img, gray_img, 0);

    blur(gray_img, gray_img, Size(3, 3));

    // Mat edge_img.create(single_chnl.size(), single_chnl.type());
    Canny(gray_img, gray_img, edge_threshold, edge_threshold * 3, 3);
    

    
    std::vector<Vec4i> lines;
    if (probabilistic) {
        // HoughLinesP(gray_img, lines, 1, 1 * CV_PI/180, 50, 90, 20);
        // HoughLinesP(gray_img, lines, 1, 1 * CV_PI/180, 200, 50, 300);
        HoughLinesP(gray_img, lines, 1, 1 * CV_PI/180, 100, 50, 300);
    }
    else {
        std::vector<Vec2f> lines_full;
        int threshold = (280.0 / 3264) * orig_img.size().width;
        HoughLines(gray_img, lines_full, 0.5, 0.5 * CV_PI/180, threshold);
        for (const Vec2f& line_param : lines_full) {
            lines.push_back(paramToLine(line_param, orig_img.size(), orig_img.size[1] * 2));
        }
    }

//    cv::Mat color_img(gray_img.size(), orig_img.type());
//    cv::cvtColor(gray_img, color_img, cv::COLOR_GRAY2BGR);
//    for (const Vec4i& found_line : lines) {
//        line(color_img,
//            Point(found_line[0], found_line[1]),
//            Point(found_line[2], found_line[3]),
//            cv::Scalar(0, 0, 255), 2, CV_AA);
//    }
//    // imwrite("edges_0038.png", gray_img);
//    namedWindow("window");
//    resize(color_img, color_img, Size(0, 0), 0.5, 0.5);
//    imshow("window", color_img);
//    waitKey(0);

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
