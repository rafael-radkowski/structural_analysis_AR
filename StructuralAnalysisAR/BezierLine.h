//
//  BezierLine.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/12/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef BezierLine_hpp
#define BezierLine_hpp

#include "OverlayLabel.h"

#include <stdio.h>
#include <vector>

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>

class BezierLine {
public:
    BezierLine() : BezierLine([UIBezierPath bezierPath]) {};
    // TODO: This is kind of dumb, passing 2, rather than "thickness", but thickness is uninitialized otherwise
    BezierLine(const std::vector<std::vector<float>>& points) : BezierLine(interpolatePoints(points, 2)) {};
    BezierLine(UIBezierPath* path);
    void doUpdate();
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void updatePath(const std::vector<std::vector<float>>& points);
    void setThickness(float newThickness);
    void setPosition(GLKVector3 pos);
    void setOrientation(GLKQuaternion ori);
    
    void setMagnification(float new_mag);
    void setColor(float r, float g, float b);
    void addAsChild(SCNNode *scene);
    void setHidden(bool hidden);
    void setTextHidden(bool hidden);
private:
    bool hidden = false;
    float magnification = 1;
    float thickness = 2;
    SCNNode* lineNode;
    SCNNode* rootNode;
    UIBezierPath* interpolatePoints(const std::vector<std::vector<float>>& points, float height);
    SCNShape* meshFromPath(UIBezierPath* path);
    
    // Deflection label
    OverlayLabel defLabel;
    SCNNode* labelEmpty;
    bool labelHidden = false;
};

#endif /* BezierLine_hpp */
