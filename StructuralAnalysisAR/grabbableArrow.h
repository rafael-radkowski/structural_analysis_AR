//
//  grabbableArrow.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/24/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef grabbableArrow_h
#define grabbableArrow_h

#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>
#import <ModelIO/ModelIO.h>
#import <Scenekit/ModelIO.h>
#import <GLKit/GLKit.h>

#include <utility>

class GrabbableArrow {
public:
    GrabbableArrow();
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void addAsChild(SCNNode* node);
    void setHidden(bool hidden);
    void setPosition(GLKVector3 pos);
    void setRotationAxisAngle(GLKVector4 axisAngle);
    
    void setMaxLength(float newLength);
    float getMaxLength();
    void setMinLength(float newLength);
    float getMinLength();

    // True if the passed in node is part of the arrow
    bool hasNode(SCNNode* node);
    
    
    void setThickness(float thickness);
    
    // Ranges of inputs that will map to the arrow length
    void setInputRange(float minValue, float maxValue);
    std::pair<float,float> getInputRange();
    
    void touchBegan(SCNHitTestResult* hitTestResult);
    float getDragValue(GLKVector3 origin, GLKVector3 touchRay, GLKVector3 cameraDir);
    void touchEnded();
    void touchCancelled();
    
    void setIntensity(float value);
    void setWide(bool wide);
    float widthScale = 1.0;
    
    float lastArrowValue = 0.5;
    
    // Root node for entire arrow
    SCNNode* root;
    
    bool dragging = false;
    
private:
    // Moves text label to correct position
    void placeLabel();
    SCNNode* arrowHead;
    SCNNode* arrowBase;
    
    // Default tip size from .obj file is 0.3 units tall
    float defaultTipSize = 0.3;
    float tipSize = defaultTipSize;
    float defaultWidth = 0.2;
    float width = defaultWidth;
    
    float maxLength = 1;
    float minLength = 1;
    float minInput = 0;
    float maxInput = 1;
    
    SKScene* textScene = nullptr;
    SCNView* objectView = nullptr;
    SKLabelNode* valueLabel;
};

#endif /* grabbableArrow_h */
