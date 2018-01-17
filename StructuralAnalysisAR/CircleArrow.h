//
//  CircleIndicator.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/16/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef CircleIndicator_h
#define CircleIndicator_h

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>
#import <Scenekit/ModelIO.h>

#include "OverlayLabel.h"

class CircleArrow {
public:
    CircleArrow();
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void addAsChild(SCNNode* node);
    void setHidden(bool hide);
    
    void doUpdate();
    void setPosition(GLKVector3 pos);
    void setRotationAxisAngle(GLKVector4 axisAngle);
    
    void setRadius(float new_radius);
    void setThickness(float new_thickness);
    
    void setInputRange(float min_value, float max_value);
    void setIntensity(float intensity);
    void setFormatString(NSString* str);
private:
    SCNNode* root;
    OverlayLabel valueLabel;
    SCNNode* labelEmpty;
    NSString* formatString;

    // Height of the tip
    float defaultTipSize = 0.3;
    float tipSize = defaultTipSize;
    
    float thickness = 5;
    float radius = 10;
    float minValue = 0;
    float maxValue = 1;
    
    SCNView* scnView = nullptr;
    SKScene* scene2d = nullptr;
    
    SCNNode* arrowHead;
    SCNNode* arrowHeadEmpty;
    SCNShape* bodyShape;
    SCNNode* arrowBody;
    
    UIBezierPath* makePath(float angle);
};

#endif /* CircleIndicator_h */
