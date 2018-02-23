#pragma once

#include <opencv2/core/core.hpp>
// #include <opencv2/core/types.hpp>

/*
 * From Wikipedia page on Cohen-Sutherland Algorithm
 */

class EdgeClipper {
public:
    template <typename T>
    static cv::Vec<T, 4> clipLine(const cv::Vec<T, 4>& line, const cv::Size_<T>& bounds);

    // clipLine with same call format as openCV. Takes two endpoints references and modifies them
    template <typename T>
    static void clipLineCV(const cv::Size_<T>& bounds, cv::Vec<T, 2>& endpoint1, cv::Vec<T, 2>& endpoint2);
private:
    // disallow constructor
    EdgeClipper() {}

    // OutCodes
    typedef int OutCode;
    static const int INSIDE = 0; // 0000
    static const int LEFT = 1;   // 0001
    static const int RIGHT = 2;  // 0010
    static const int BOTTOM = 4; // 0100
    static const int TOP = 8;    // 1000
};


/*
-----------Implementation----------------
*/

// Cohen–Sutherland clipping algorithm clips a line from
// P0 = (x0, y0) to P1 = (x1, y1) against a rectangle with 
// diagonal from (xmin, ymin) to (xmax, ymax).
template <typename T>
cv::Vec<T, 4> EdgeClipper::clipLine(const cv::Vec<T, 4>& line, const cv::Size_<T>& bounds) {
    T x0 = line[0];
    T y0 = line[1];
    T x1 = line[2];
    T y1 = line[3];
    T xmin = 0;
    T xmax = bounds.width;
    T ymin = 0;
    T ymax = bounds.height;

    // Compute the bit code for a point (x, y) using the clip rectangle
    // bounded diagonally by (xmin, ymin), and (xmax, ymax)

    // ASSUME THAT xmax, xmin, ymax and ymin are global constants.
    auto ComputeOutCode = [xmin, xmax, ymin, ymax] (T x, T y) {
        OutCode code = INSIDE;
        // code = INSIDE;          // initialised as being inside of [[clip window]]

        if (x < xmin)           // to the left of clip window
            code |= LEFT;
        else if (x > xmax)      // to the right of clip window
            code |= RIGHT;
        if (y < ymin)           // below the clip window
            code |= BOTTOM;
        else if (y > ymax)      // above the clip window
            code |= TOP;

        return code;
    };
        

    // compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
    OutCode outcode0 = ComputeOutCode(x0, y0);
    OutCode outcode1 = ComputeOutCode(x1, y1);
    bool accept = false;

    while (true) {
        if (!(outcode0 | outcode1)) { // Bitwise OR is 0. Trivially accept and get out of loop
            accept = true;
            break;
        }
        else if (outcode0 & outcode1) { // Bitwise AND is not 0. (implies both end points are in the same region outside the window). Reject and get out of loop
            break;
        }
        else {
            // failed both tests, so calculate the line segment to clip
            // from an outside point to an intersection with clip edge
            T x, y;

            // At least one endpoint is outside the clip rectangle; pick it.
            OutCode outcodeOut = outcode0 ? outcode0 : outcode1;

            // Now find the intersection point;
            // use formulas:
            //   slope = (y1 - y0) / (x1 - x0)
            //   x = x0 + (1 / slope) * (ym - y0), where ym is ymin or ymax
            //   y = y0 + slope * (xm - x0), where xm is xmin or xmax
            if (outcodeOut & TOP) {           // point is above the clip rectangle
                x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0);
                y = ymax;
            } else if (outcodeOut & BOTTOM) { // point is below the clip rectangle
                x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0);
                y = ymin;
            } else if (outcodeOut & RIGHT) {  // point is to the right of clip rectangle
                y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0);
                x = xmax;
            } else if (outcodeOut & LEFT) {   // point is to the left of clip rectangle
                y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0);
                x = xmin;
            }

            // Now we move outside point to intersection point to clip
            // and get ready for next pass.
            if (outcodeOut == outcode0) {
                x0 = x;
                y0 = y;
                outcode0 = ComputeOutCode(x0, y0);
            } else {
                x1 = x;
                y1 = y;
                outcode1 = ComputeOutCode(x1, y1);
            }
        }
    }
    return cv::Vec<T, 4>(x0, y0, x1, y1);
}

template <typename T>
void EdgeClipper::clipLineCV(const cv::Size_<T>& bounds, cv::Vec<T, 2>& endpoint1, cv::Vec<T, 2>& endpoint2) {
    cv::Vec<T, 4> converted(endpoint1[0], endpoint1[1], endpoint2[0], endpoint2[1]);
    auto clipped = clipLine(converted, bounds);
    endpoint1[0] = clipped[0]; endpoint1[1] = clipped[1];
    endpoint2[0] = clipped[2]; endpoint2[1] = clipped[3];
}