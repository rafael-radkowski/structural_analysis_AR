//
//  TownCalcs.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/12/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef TownCalcs_h
#define TownCalcs_h

namespace TownCalcs {
    struct {
        double x1; // distance to start of live load, ft
        double x2; // distance to end of live load, ft
        double L; // value of live load in k/ft
        double D; // value of dead load in k/ft
        double F; // value of sideways force (kip?)
    } typedef Input_t;
    
    struct {
        double theta_B;
        double theta_C;
        double theta_E;
        double delta;
        
        double M_AB;
        double M_BA;
        double M_DC;
        double M_CD;
        double M_FE;
        double M_EF;
        double M_BC;
        double M_CB;
        double M_CE;
        double M_EC;
        
        double F_AB;
        double F_BA;
        double F_DC;
        double F_CD;
        double F_FE;
        double F_EF;
        double F_BC;
        double F_CB;
        double F_CE;
        double F_EC;
        
        double V_AB;
        double V_BA;
        double V_DC;
        double V_CD;
        double V_FE;
        double V_EF;
        double V_BC;
        double V_CB;
        double V_CE;
        double V_EC;
    } typedef Output_t;
    
    class Calculator {
        // constants
        static constexpr double k_1 = 11393.51;
        static constexpr double k_2 = 11393.51;
        static constexpr double k_3 = 11393.51;
        static constexpr double k_4 = 138404.186;
        static constexpr double k_5 = 138404.186;
        
    public:
        static constexpr double width = 16.67;
        static constexpr double height = 12;
        
        static Output_t calculate(const Input_t& inputs);
    };
    
    template <unsigned int P>
    double power(const double base) {
        return power<P-1>(base) * base;
    }
    
    template <>
    inline double power<1>(const double base) {
        return base;
    }
}

#endif /* TownCalcs_h */
