//
//  BezierLine.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/12/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef BezierLine_hpp
#define BezierLine_hpp

#include <stdio.h>
#include <vector>

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>

class BezierLine {
public:
    BezierLine();
    BezierLine(std::vector<std::vector<float>> points);
    void updatePath(const std::vector<std::vector<float>>& points);
    void setThickness(float newThickness);
    
    void setColor(float r, float g, float b);
    void addAsChild(SCNNode *scene);
    void setHidden(bool hidden);
private:
    float thickness = 2;
    SCNNode* lineNode;
    UIBezierPath* interpolatePoints(const std::vector<std::vector<float>>& points, float height);
    SCNShape* meshFromPath(UIBezierPath* path);
};

#endif /* BezierLine_hpp */
