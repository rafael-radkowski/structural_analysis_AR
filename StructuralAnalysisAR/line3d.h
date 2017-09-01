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
    Line3d();
    void setThickness(float thickness);
    void setColor(float r, float g, float b);
    void move(GLKVector3 start, GLKVector3 end);
    void addAsChild(SCNNode *scene);
    void setHidden(bool hidden);
    
private:
    SCNNode *boxNode;
    SCNNode *boxContainer;
    SCNNode *boxLookAt;
};
#endif /* line3d_hpp */
