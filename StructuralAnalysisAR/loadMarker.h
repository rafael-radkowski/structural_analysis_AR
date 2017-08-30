//
//  loadMarker.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef loadMarker_hpp
#define loadMarker_hpp

#include "line3d.h"
#include "grabbableArrow.h"

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <Scenekit/ModelIO.h>

#include <stdio.h>
#include <stdint.h>
#include <vector>


class LoadMarker {
public:
    LoadMarker();
    LoadMarker(size_t nLoads);
    void addAsChild(SCNNode *node);
    void setLoad(size_t loadIndex, double value);
    void setPosition(GLKVector3 start, GLKVector3 end);
    void setMaxHeight(float h);
    
private:
    SCNNode* rootNode;
    std::vector<double> loadValues;
    std::vector<GrabbableArrow> loadArrows;
    std::vector<Line3d> loadLines;
    
    float maxHeight = 1.5;
};

#endif /* loadMarker_hpp */
