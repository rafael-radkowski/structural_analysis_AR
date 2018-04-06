//
//  TownCalcs.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/12/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include "TownCalcs.hpp"
#include <utility>
using std::make_pair;

using namespace TownCalcs;

constexpr static std::array<double, 5> equation1 = {             0,  +2.25175E-05,  -2.54990E-04,  -3.64800E-05, -1.94686E-05};
constexpr static std::array<double, 5> equation2 = {             0,  +2.13136E-05,  -2.45540E-04,  -1.20251E-04, +1.94406E-05};
constexpr static std::array<double, 5> equation3 = {             0,  -6.30189E-06,  +7.84770E-05,  +1.09172E-04, -4.33148E-05};
constexpr static std::array<double, 5> equation4 = {             0,  -1.15516E-05,  +1.37205E-04,  +1.59369E-04, -5.70211E-05};
constexpr static std::array<double, 5> equation5 = {             0,  -2.12686E-05,  +2.44974E-04,  +1.20283E-04, -2.60839E-05};
constexpr static std::array<double, 5> equation6 = {-0.00000111121, +0.0000290842, -0.0000383479, -0.00230318, -0.0000111888};
constexpr static std::array<double, 5> equation7 = {-0.00000107914, +0.0000437637,  -0.000420113,  -0.000158754, -0.0000118881};

Output_t Calculator::calculateForces(const Input_t& inputs) {
    // fixed end moments
    double MF_BC = 0, MF_CB = 0, MF_CE = 0, MF_EC = 0;
    if (inputs.x1 <= width && inputs.x2 >= width) {
        MF_BC = inputs.L * power<3>(width - inputs.x1) * (width + 3*inputs.x1) / 3334.67;
        MF_CB = -inputs.L * power<2>(width - inputs.x1) * (1667.33 - (133.36*(width - inputs.x1)) + 3*power<2>(width - inputs.x1)) / 3334.67;
        MF_CE = inputs.L * power<2>(inputs.x2 - width) * (3*power<2>(inputs.x2 - width) + 3890.44 - 133.36*inputs.x2) / 3334.67;
        MF_EC = -inputs.L * power<3>(inputs.x2 - width) * (116.69 - 3*inputs.x2) / 3334.67;
    }
    else if (inputs.x1 <= width && inputs.x2 <= width) {
        MF_BC = inputs.L * power<2>(inputs.x2) * (3*power<2>(inputs.x2) - 133.36*inputs.x2 + 1667.33) / 3334.67
                + inputs.L * power<3>(width - inputs.x1) * (66.68 - (50.01 - 3*inputs.x1)) / 3334.67
                - 23.157 * inputs.L;
        MF_CB = -inputs.L * power<3>(inputs.x2) * (66.68 - 3*inputs.x2) / 3334.67
                - inputs.L * power<2>(width - inputs.x1) * (1667.33 - 133.36*(width - inputs.x1) + 3*power<2>(width - inputs.x1)) / 3334.67
                + 23.157 * inputs.L;
        MF_CE = 0;
        MF_EC = 0;
    }
    else if (inputs.x1 >= width && inputs.x2 >= width) {
        MF_BC = 0;
        MF_CB = 0;
        MF_CE = inputs.L * power<2>(inputs.x2 - width) * (3*power<2>(inputs.x2 - width) - 133.36*(inputs.x2 - width) + 1667.33) / 3334.67
                + inputs.L*power<3>(33.34 - inputs.x1) * (66.68 - 3*(33.34 - inputs.x1)) / 3334.67
                - 23.157 * inputs.L;
        MF_EC = -inputs.L * power<3>(inputs.x2 - width) * (66.68 - 3*(inputs.x2 - width)) / 3334.67
                - inputs.L * power<2>(33.34 - inputs.x1) * (1667.33 - 133.36*(33.34 - inputs.x1) + 3*power<2>(33.34 - inputs.x1)) / 3334.67
                + 23.157 * inputs.L;
    }
//    else if (inputs.x1 == 0 && inputs.x2 == width) {
//        MF_BC = 23.157 * inputs.L;
//        MF_CB = -23.157 * inputs.L;
//        MF_CE = 0;
//        MF_EC = 0;
//    }
//    else if (inputs.x1 == width && inputs.x2 == 2*width) {
//        MF_BC = 0;
//        MF_CB = 0;
//        MF_CE = 23.157 * inputs.L;
//        MF_EC = -23.157 * inputs.L;
//    }
    // add dead load contribution
    MF_BC += 23.157 * inputs.D;
    MF_CB -= 23.157 * inputs.D;
    MF_CE += 23.157 * inputs.D;
    MF_EC -= 23.157 * inputs.D;
    
    // fixed end shears
    double VF_BC = 0, VF_CB = 0, VF_CE = 0, VF_EC = 0;
    if (inputs.x1 <= width && inputs.x2 >= width) {
        VF_BC = (inputs.L * (power<2>(width - inputs.x1) / 2) + MF_CB + MF_BC) / width;
        VF_CB = (inputs.L * (width - inputs.x1) * (inputs.x1 + ((width - inputs.x1) / 2)) - MF_BC - MF_CB) / width;
        VF_CE = (inputs.L * (inputs.x2 - width) * (33.34 - inputs.x2 + ((inputs.x2 - width) / 2)) + MF_EC + MF_CE) / width;
        VF_EC = ((inputs.L * power<2>(inputs.x2 - width) / 2) - MF_CE - MF_EC) / width;
    }
    else if (inputs.x1 <= width && inputs.x2 <= width) {
        VF_BC = (inputs.L * (inputs.x2 - inputs.x1) * (width - inputs.x1 - ((inputs.x2 - inputs.x1) / 2)) + MF_BC + MF_CB) / width;
        VF_CB = (inputs.L * (inputs.x2 - inputs.x1) * (inputs.x2 - ((inputs.x2 - inputs.x1) / 2)) - MF_BC - MF_CB) / width;
        VF_CE = 0;
        VF_EC = 0;
    }
    else if (inputs.x1 >= width && inputs.x2 >= width) {
        VF_BC = 0;
        VF_CB = 0;
        VF_CE = (inputs.L * (inputs.x2 - inputs.x1) * (33.34 - inputs.x1 - ((inputs.x2 - inputs.x1) / 2)) + MF_CE + MF_EC) / width;
        VF_EC = (inputs.L * (inputs.x2 - inputs.x1) * ((inputs.x1 - width) + ((inputs.x2 - inputs.x1) / 2)) - MF_CE - MF_EC) / width;
    }
//    else if (inputs.x1 == 0 && inputs.x2 == width) {
//        VF_BC = 8.335 * inputs.L;
//        VF_CB = 8.335 * inputs.L;
//        VF_CE = 0;
//        VF_EC = 0;
//    }
//    else if (inputs.x1 == width && inputs.x2 == 33.34) {
//        VF_BC = 0;
//        VF_CB = 0;
//        VF_CE = 8.335 * inputs.L;
//        VF_EC = 8.335 * inputs.L;
//    }
    // add dead load contribution
    VF_BC += 8.335 * inputs.D;
    VF_CB += 8.335 * inputs.D;
    VF_CE += 8.335 * inputs.D;
    VF_EC += 8.335 * inputs.D;
    
    // solve for thetas and delta
    double A_data[16] = {
        4*k_1 + 4*k_4, 2*k_4,             0,           k_1/2,
        2*k_4,         4*k_4+4*k_2+4*k_5, 2*k_5,       k_2/2,
        0,             2*k_5,             4*k_5+4*k_3, k_3/2,
        k_1/2,         k_2/2,             k_2/2,       (k_1+k_2+k_3)/12
    };
    double b_data[4] = {-MF_BC, -MF_CB - MF_CE, -MF_EC, inputs.F};
    cv::Mat A(4, 4, CV_64F, A_data);
    cv::Mat b(4, 1, CV_64F, b_data);
    cv::Mat x(4, 1, CV_64F);
    bool has_solution = cv::solve(A, b, x);
    assert(has_solution);
    double theta_B = x.at<double>(0,0);
    double theta_C = x.at<double>(1,0);
    double theta_E = x.at<double>(2,0);
    double delta = x.at<double>(3,0);
    
    // calculate final values
    Output_t computed;
    computed.theta_B = theta_B;
    computed.theta_C = theta_C;
    computed.theta_E = theta_E;
    computed.delta = delta;
    
    // moments
    computed.M_AB = 2*k_1 * (theta_B + delta/4);
    computed.M_BA = 2*k_1 * (2*theta_B + delta/4);
    computed.M_BC = 2*k_4 * (2*theta_B + theta_C) + MF_BC;
    computed.M_CB = 2*k_4 * (theta_B + 2*theta_C) + MF_CB;
    computed.M_CD = 2*k_2 * (2*theta_C + delta/4);
    computed.M_DC = 2*k_2 * (theta_C + delta/4);
    computed.M_CE = 2*k_5 * (2*theta_C + theta_E) + MF_CE;
    computed.M_EC = 2*k_5 * (theta_C + 2*theta_E) + MF_EC;
    computed.M_EF = 2*k_3 * (2*theta_E + delta/4);
    computed.M_FE = 2*k_3 * (theta_E + delta/4);
    
    // shear forces
    computed.V_AB = (k_1 / 2) * (theta_B + delta/6);
    computed.V_BA = -computed.V_AB;
    computed.V_BC = 0.36 * k_4 * (theta_B + theta_C) + VF_BC;
    computed.V_CB = -0.36 * k_4 * (theta_B + theta_C) + VF_CB;
    computed.V_CD = (k_2 / 2) * (theta_C + delta/6);
    computed.V_DC = -computed.V_CD;
    computed.V_CE = 0.36 * k_5  * (theta_C + theta_E) + VF_CE;
    computed.V_EC = -0.36 * k_5  * (theta_C + theta_E) + VF_EC;
    computed.V_EF = (k_2 / 2) * (theta_E + delta/6);
    computed.V_FE = -computed.V_EF;

    // axial forces
    computed.F_AB = computed.V_BC;
    computed.F_BA = -computed.V_BC;
    computed.F_BC = -computed.V_BA;
    computed.F_CB = computed.V_BA;
    computed.F_CD = -computed.V_CB - computed.V_CE;
    computed.F_DC = computed.V_CB + computed.V_CE;
    computed.F_CE = computed.V_EF;
    computed.F_EC = -computed.V_EF;
    computed.F_EF = -computed.V_EC;
    computed.F_FE = computed.V_EC;
    
    return computed;
}

//template <typename F>
void evalDeflection(const std::vector<std::pair<double, std::array<double, 5>>>& pieces,
                    std::vector<std::vector<float>>& deflection_vals) {
    for (size_t i = 0; i < deflection_vals[0].size(); ++i) {
        auto x = deflection_vals[0][i];
        auto x2 = x * x;
        auto x3 = x2 * x;
        auto x4 = x2 * x2;
        double value = 0;
        for (const auto& piece : pieces) {
            double poly_evaluated = piece.second[0] * x4 +
                                    piece.second[1] * x3 +
                                    piece.second[2] * x2 +
                                    piece.second[3] * x +
                                    piece.second[4];
            value += poly_evaluated * piece.first;
        }
        deflection_vals[1][i] = value;
    }
}

void Calculator::calculateDeflections(const Input_t& inputs, const double delta, Deflections_t& deflections, const double defl_scale) {
    // Column 1
    evalDeflection({   make_pair(defl_scale * delta / 0.0017344514, equation1),
                       make_pair(defl_scale * (inputs.L + 3) / 5., equation2)},
                   deflections.col_AB);
    // Column 2
    evalDeflection({make_pair(defl_scale * delta / 0.001677771, equation3)},
                   deflections.col_DC);
    // Column 3
    evalDeflection({   make_pair(defl_scale * delta / 0.001651762, equation4),
                       make_pair(defl_scale * (inputs.L + 3) / 5, equation5)},
                   deflections.col_FE);
    
    double A, B, C, D;
    if (inputs.x1 <= width) {
        if (inputs.x2 > width) {
            // Case 1
            A = (width - inputs.x1) / width;
            B = (inputs.x2 - width) / width;
            C = (inputs.x2 - width) / width;
            D = (width - inputs.x1) / width;
        }
        else { // x2 <= width
            // Case 2
            A = (inputs.x2 - inputs.x1) / width;
            B = 0;
            C = 0;
            D = (inputs.x2 - inputs.x1) / width;
        }
    }
    else { // x1 > width && x2 > width
        A = 0;
        B = (inputs.x2 - inputs.x1) / width;
        C = (inputs.x2 - inputs.x1) / width;
        D = 0;
    }
    
    // Beam 1
    double beam1_factor = 1
                          + 0.05 * inputs.L * (A - B) / 3
                          + 0.2 * inputs.F / 5;
    beam1_factor *= defl_scale;
    evalDeflection({make_pair(beam1_factor, equation6)},
                   deflections.beam_BC);
    
    // Beam 2
    double beam2_factor = 1
                + 0.05  *inputs.L * (C - D) / 3
                - 0.15 * inputs.L / 5;
    beam2_factor *= defl_scale;
    evalDeflection({make_pair(beam2_factor, equation7)},
                   deflections.beam_CE);
}

