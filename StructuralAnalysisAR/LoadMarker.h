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
#include "OverlayLabel.h"

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>
#import <Scenekit/ModelIO.h>

#include <stdio.h>
#include <stdint.h>
#include <vector>
#include <utility>



class LoadMarker {
public:
    LoadMarker();
    LoadMarker(size_t nLoads, bool reversed=false, int n_labels=1, float hit_overlap=1.0);
    void setFormatString(NSString* str);
    enum Dragging : uint32_t {
        none = 0,
        vertically = 1,
        horizontallyL = 1 << 2,
        horizontallyR = 1 << 3,
        horizontally = 1 << 4
    };
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void addAsChild(SCNNode *node);
    void doUpdate();
    void setLoad(size_t loadIndex, double value);
    void setLoad(double value);
    void setLoadInterpolate(double val_l, double val_r);
    void setPosition(GLKVector3 pos);
    void setOrientation(GLKQuaternion);
    void setEnds(float start, float end);
    void setMaxHeight(float h);
    void setMinHeight(float h);
    void setThickness(float thickness);
    float getLoad(size_t loadIndex);
    uint32_t draggingMode() const;
    
    void setHidden(bool hidden);
    
    // Ranges of inputs that will map to the arrow length
    void setInputRange(float minValue, float maxValue);
    std::pair<float, float> getInputRange();
    
    // Touch and drag functions
    void touchBegan(GLKVector3 origin, GLKVector3 touchRay);
    // The value, and whether it is a new value
    float getDragValue(GLKVector3 origin, GLKVector3 touchRay);
    // The distance from the left-hand end of the load marker to the point that's being dragged
    float getDragPoint(GLKVector3 origin, GLKVector3 touchRay);
    // Returns the dragged start and end x position
    std::pair<float, float> getDragPosition(GLKVector3 origin, GLKVector3 farHit);
    void touchEnded();
    void touchCancelled();
    
    const GLKVector3 getStartPos();
    const GLKVector3 getEndPos();
    
    
private:
    NSString* formatString;
    void refreshPositions();

    // Returns the 3D point where a touch ray intersects the "plane" created by the load marker
    GLKVector3 projectRay(const GLKVector3 origin, const GLKVector3 touchRayr);
    
    GLKVector3 startPos;
    GLKVector3 endPos;
    
    SCNNode* rootNode;
    std::vector<double> loadValues;
    std::vector<GrabbableArrow> loadArrows;
    std::vector<Line3d> loadLines;
    
    float maxHeight = 1.5;
    float minHeight = 0;
    float minInput = 0;
    float maxInput = 1;
    
    uint32_t dragState = none;
    // Coordinates of touch hit point when touchBegan
    GLKVector3 dragStartPos;
    // startPos and endPos whend touchBegan
    GLKVector3 startAtDragBegin;
    GLKVector3 endAtDragBegin;
    
    bool reversed;

    float lastIntensity = 0.5;
    float thickness;
    
    // Label
    std::vector<OverlayLabel> textLabels;
    std::vector<SCNNode*> labelEmpties;
};

#endif /* loadMarker_hpp */
