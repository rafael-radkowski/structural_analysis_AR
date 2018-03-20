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
#import <ModelIO/ModelIO.h>
#import <Scenekit/ModelIO.h>
#import <GLKit/GLKit.h>

#include <utility>

#include "OverlayLabel.h"

class GrabbableArrow {
public:
    GrabbableArrow(float hit_scale = 1.0, bool as_loadmarker = false, bool reversed = false);
    void setFormatString(NSString* str);
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void addAsChild(SCNNode* node);
    
    // Perform SpriteKit update routines
    void doUpdate();
    
    void setTextHidden(bool hidden);
    void setHidden(bool hidden);
    void setPosition(GLKVector3 pos);
    void setRotationAxisAngle(GLKVector4 axisAngle);
    void setOrientation(GLKQuaternion quat);
    void setLabelFollow(bool follow);
    
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
    
    void touchBegan(GLKVector3 origin, GLKVector3 farHit);
    float getDragValue(GLKVector3 origin, GLKVector3 touchRay, GLKVector3 cameraDir);
    void touchEnded();
    void touchCancelled();
    
    void setIntensity(float value);
    void setWide(bool wide);
    float widthScale = 1.0;
    void setColor(float r, float g, float b);
    
    float lastArrowValue = 0.5;
    
    GLKQuaternion extraRotation, setRotation;
    bool negated = false;
    
    // Root node for entire arrow
    SCNNode* root;
    
    bool dragging = false;
    
private:
    bool reversed;
    
    NSString* formatString;
    OverlayLabel valueLabel;
    SCNNode* labelEmpty;
    bool labelHidden = false;
    bool labelFollows = true;
    
    SCNNode* arrowHead;
    SCNNode* arrowBase;
    SCNMaterial* arrowMat;
    // box for detecting touches near the arrow
    SCNNode* hitBox;
    float hitBoxScale;
    bool partOfLoadMarker;
    
    // Default tip size from .obj file is 0.3 units tall
    float defaultTipSize = 0.3;
    float tipSize = defaultTipSize;
    float defaultWidth = 0.2;
    
    float maxLength = 1;
    float minLength = 1;
    float minInput = 0;
    float maxInput = 1;
    
    SKScene* textScene = nullptr;
    SCNView* objectView = nullptr;
};

#endif /* grabbableArrow_h */
