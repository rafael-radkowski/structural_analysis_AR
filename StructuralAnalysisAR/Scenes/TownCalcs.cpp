//
//  TownCalcs.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/12/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include "TownCalcs.hpp"

using namespace TownCalcs;

Output_t Calculator::calculate(const Input_t& inputs) {
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
        VF_CE = ((inputs.L * power<2>(inputs.x2 - width) / 2) - MF_CE - MF_EC) / width;
        VF_EC = (inputs.L * (inputs.x2 - width) * (33.34 - inputs.x2 + ((inputs.x2 - width) / 2)) + MF_EC + MF_CE) / width;
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
