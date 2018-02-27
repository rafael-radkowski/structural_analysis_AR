//
//  Ruler.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 2/23/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef Ruler_hpp
#define Ruler_hpp

#include <stdio.h>
#include <vector>

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>

class Ruler {
public:
    Ruler();
    void doUpdate();
    void addAsChild(SCNNode* node);
    void setScenes(SKScene* scene2d, SCNView* view3d);
    void setPosition(GLKVector3 pos);
    void setOrientation(GLKQuaternion);
    void setEnds(float start, float end);
    void setMarkSpacing(float spacing);
    void setWidth(float width);
    void setLineThickness(float thickness);
    void setHidden(bool hidden);
    
private:
    SCNNode* rootNode;
    // plane and node along length of ruler
    SCNPlane* longPlane;
    SCNNode* longNode;
    std::vector<SCNText*> texts;
    std::vector<SCNNode*> marks;
    
    UIFont* textFont;
    NSString* formatString;
    
    SCNMaterial* textMat;
    SCNMaterial* bgMat;
    
    float markSpacing = 15;
    float lineThickness = 1;
    float rulerWidth = 10;
    float rulerStart = 0;
    float rulerEnd = 0;

    // funtions
    SCNNode* makeMark();
    void positionMark(SCNNode* mark, int idx);
};
#endif /* Ruler_hpp */
