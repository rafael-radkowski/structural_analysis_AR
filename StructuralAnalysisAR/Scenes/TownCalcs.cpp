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

// Equation sets contain coefficients for a 4th-order polynomial
// equation ordering is Column 1, Column 2, Column 3, Beam 1, Beam 2

constexpr static double set1[5][5] = {
    {           0, +0.00025E-05, -1.16048E-04, -4.08217E-05, +1.46853E-06},
    {           0,            0,            0,            0,            0},
    {           0, +9.46295E-06, +1.08278E-04, +6.80167E-05, -1.48951E-05},
    {-6.44086E-07, +1.67887E-05, -1.69285E-05, -1.40017E-03, +5.59441E-07},
    {-6.44086E-07, +2.61590E-05, -2.51233E-04, -9.69119E-05, -1.02797E-05}
};
constexpr static double set2[5][5] = {
    {           0, -9.14932E-06, +2.57976E-04, +4.55614E-05, +9.65035E-06},
    {           0, -2.35326E-05, +4.24858E-04, +1.14676E-04, +4.54545E-06},
    {           0, -3.58239E-05, +5.69898E-04, +1.41777E-04, -9.09091E-07},
    {-6.45973E-07, +1.61668E-05, +5.03715E-06, -1.58447E-03, -2.09790E-06},
    {-6.46350E-07, +2.55224E-05, -2.39584E-04, -1.04232E-04, -6.57343E-06}
};
constexpr static double set3[5][5] = {
    {           0, +2.13136E-05, -2.45540E-04, -1.20251E-04, +1.94406E-05},
    {           0,           0,             0,            0,            0},
    {-2.12686E-05, +2.44974E-04,            0, +1.20283E-04, -2.60839E-05},
    {-1.07914E-06, +2.81932E-05, -3.07723E-05, -2.32299E-03, -5.24476E-06},
    {-1.07914E-06, +4.37637E-05, -4.20113E-04, -1.58754E-04, -1.18881E-05}
};
constexpr static double set4[5][5] = {
    {+2.25175E-05, -2.54990E-04,            0, -3.64800E-05, -1.94686E-05},
    {-6.30189E-06, +7.84770E-05,            0, +1.09172E-04, -4.33148E-05},
    {-1.15516E-05, +1.37205E-04,            0, +1.59369E-04, -5.70211E-05},
    {-1.09536E-06, +3.03011E-05, -3.67374E-05, -2.73434E-03, -4.19580E-06},
    {-6.38049E-07, +2.75176E-05, -3.26900E-04, +7.58784E-04, -8.53147E-06}
};
constexpr static double set5[5][5] = {
    {           0, +1.15550E-05, -1.37282E-04, -1.59049E-04, +5.37344E-05},
    {           0, +6.30189E-06, -7.84770E-05, -1.09172E-04, +4.33148E-05},
    {           0, -2.25051E-05, +2.54824E-04, +3.68944E-05, +2.31050E-05},
    {-6.38049E-07, +1.50275E-05, -1.45840E-05, -9.77656E-04, -1.39860E-07},
    {-1.09536E-06, +4.27376E-05, -3.47711E-04, -1.00523E-03, -1.36364E-05}
};
constexpr static double set6[5][5] = {
    {           0, -7.29022E-06, +2.62079E-04, -2.53888E-04, +1.43306E-04},
    {           0, -2.82002E-05, +4.96632E-04, -6.37493E-05, +8.92502E-05},
    {           0, -4.81354E-05, +7.22308E-04, +1.17812E-04, -2.93086E-04},
    {-1.07800E-06, +2.74170E-05, -6.03849E-06, -2.52496E-03, -2.44755E-06},
    {-1.07310E-06, +4.28000E-05, -4.04708E-04, -1.75618E-04, -1.21678E-05}
};
constexpr static double set7[5][5] = {
    {           0, -6.10988E-06, +2.52763E-04, -1.68262E-04, +1.01390E-04},
    {           0, -3.37276E-05, +5.61321E-04, +9.97222E-05, +2.42570E-05},
    {           0, -3.76564E-05, +6.06311E-04, +1.21614E-04, +2.60752E-05},
    {-1.09159E-06, +2.94230E-05, -1.08072E-05, -2.94034E-03, -2.23776E-06},
    {-6.33898E-07, +2.66291E-05, -3.12404E-04, +7.44872E-04, -7.06294E-06}
};
constexpr static double set8[5][5] = {
    {           0, -1.70072E-05, +3.69613E-04, -2.89779E-04, +1.75991E-04},
    {           0, -2.18534E-05, +4.17588E-04, -1.72889E-04, +1.31376E-04},
    {           0, -4.85515E-05, +7.23104E-04, -1.29261E-07, +1.01096E-04},
    {-6.33144E-07, +1.41557E-05, +1.05965E-05, -1.17727E-03, -3.00699E-06},
    {-1.08631E-06, +4.16666E-05, -3.31165E-04, -1.02572E-03, -9.72028E-06}
};

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
void evalSet(const double set[5][5], Deflections_t& deflections, std::function<double(double)> colScaleFunc, std::function<double(double)> beamScaleFunc) {
    auto evalPoly = [] (const double coeffs[5], std::vector<std::vector<float>>& vals, std::function<double(double)> scaleFunc) {
        for (size_t i = 0; i < vals.size(); ++i) {
            auto x = vals[0][i];
            auto x2 = x * x;
            auto x3 = x2 * x;
            auto x4 = x2 * x2;
            vals[1][i] = coeffs[0] * x4 +
                         coeffs[1] * x3 +
                         coeffs[2] * x2 +
                         coeffs[3] * x +
                         coeffs[4];
            vals[1][i] *= scaleFunc(x);
        }
    };
    evalPoly(set[0], deflections.col_AB, colScaleFunc);
    evalPoly(set[1], deflections.col_DC, colScaleFunc);
    evalPoly(set[2], deflections.col_FE, colScaleFunc);
//    double col1_defl = deflections.col_AB[1][deflections.col_AB[1].size() - 1];
    evalPoly(set[3], deflections.beam_BC, beamScaleFunc);
//    double col2_defl = deflections.col_DC[1][deflections.col_DC[1].size() - 1];
    evalPoly(set[4], deflections.beam_CE, beamScaleFunc);
}

int Calculator::calculateDeflections(const Input_t& inputs, const double delta, Deflections_t& deflections, const double defl_scale) {
    // minimum value to be considered 0
    const double eps = 0.001;
    double load_length = inputs.x2 - inputs.x1;
    double left_prop = (width - inputs.x1) / load_length;
    double right_prop = (inputs.x2 - width) / load_length;
    // Set 1
    int set = -1;
    if (inputs.L <= eps && inputs.F <= eps) {
        auto scaleFunc = [&](auto x) {return defl_scale;};
        evalSet(set1, deflections, scaleFunc, scaleFunc);
        set = 1;
    }
    // Set 2
    else if (inputs.L <= eps && inputs.F > eps) {
        auto scaleFunc = [&](auto x) {return defl_scale * inputs.F / 5;};
        evalSet(set2, deflections, scaleFunc, scaleFunc);
        set = 2;
    }
    // Set 3
    else if (inputs.L > eps && inputs.F <= eps &&
             (inputs.x1 <= eps && inputs.x2 >= (2*width - eps))) {
        auto scaleFunc = [&](auto x) {return defl_scale * inputs.L / 2;};
        evalSet(set3, deflections, scaleFunc, scaleFunc);
        set = 3;
    }
    // Set 4
    else if (inputs.L > eps && inputs.F < eps && left_prop > right_prop) {
        auto colScaleFunc = [&](auto x) {return defl_scale * delta / 0.001785334;};
        auto beamScaleFunc = [&](auto x) {return defl_scale * inputs.L * (width - inputs.x1) / (width * 2);};
        evalSet(set4, deflections, colScaleFunc, beamScaleFunc);
        set = 4;
    }
    // Set 5
    else if (inputs.L > eps && inputs.F <= eps && right_prop > left_prop) {
        auto colScaleFunc = [&](auto x) {return defl_scale * delta / -0.001785334;};
        auto beamScaleFunc = [&](auto x) {return defl_scale * inputs.L * (inputs.x2 - width) / (width * 2);};
        evalSet(set5, deflections, colScaleFunc, beamScaleFunc);
        set = 5;
    }
    // Set 6
    else if (inputs.L > eps && inputs.F > eps &&
             (inputs.x1 <= eps && inputs.x2 >= (2*width - eps))) {
        auto colScaleFunc = [&](auto x) {return defl_scale * delta / 0.021899;};
        auto beamScaleFunc = [&](auto x) {return defl_scale * inputs.F * inputs.L / 10;};
        evalSet(set6, deflections, colScaleFunc, beamScaleFunc);
        set = 6;
    }
    // Set 7
    else if (inputs.L > eps && inputs.F > eps && left_prop > right_prop) {
        auto colScaleFunc = [&](auto x) {return defl_scale * delta / 0.023684;};
        auto beamScaleFunc = [&](auto x) {return defl_scale * inputs.F * inputs.L * (width - inputs.x1) / 166.7;};
        evalSet(set7, deflections, colScaleFunc, beamScaleFunc);
        set = 7;
    }
    // Set 8
    else if (inputs.L > eps && inputs.F > eps && right_prop > left_prop) {
        auto colScaleFunc = [&](auto x) {return defl_scale * delta / 0.020114;};
        auto beamScaleFunc = [&](auto x) {return defl_scale * inputs.F * inputs.L * (inputs.x2 - width) / 166.7;};
        evalSet(set8, deflections, colScaleFunc, beamScaleFunc);
        set = 8;
    }
    else {
        printf("No matching case for x1 = %lf, x2 = %lf, L = %lf, F = %lf, delta = %lf\n",
               inputs.x1, inputs.x2, inputs.L, inputs.F, delta);
    }
    return set;
}

