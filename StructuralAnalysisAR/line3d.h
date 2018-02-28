//
//  line3d.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef line3d_hpp
#define line3d_hpp

#include <stdio.h>
#import <Scenekit/Scenekit.h>
#import <ModelIO/ModelIO.h>
#import <Scenekit/ModelIO.h>
#import <GLKit/GLKit.h>

class Line3d {
public:
    Line3d() : Line3d(1.0) {}
    Line3d(float hitBoxScale);
    void setThickness(float thickness);
    void setColor(float r, float g, float b);
    void move(GLKVector3 start, GLKVector3 end);
    void addAsChild(SCNNode *scene);
    void setHidden(bool hidden);
    // Returns true if this line contains the given node
    bool hasNode(SCNNode* node);
    
private:
    SCNNode *boxNode;
    SCNNode *boxContainer;
    SCNNode *boxLookAt;
    SCNNode *hitBox;
};
#endif /* line3d_hpp */
