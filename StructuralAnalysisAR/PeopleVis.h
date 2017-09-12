//
//  PeopleVis.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/11/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef PeopleVis_hpp
#define PeopleVis_hpp

#include <stdio.h>
#include <vector>

#import <GLKit/GLKit.h>
#import <Scenekit/Scenekit.h>
#import <SpriteKit/SpriteKit.h>

class PeopleVis {
public:
    PeopleVis() : PeopleVis(0, nullptr) {};
    PeopleVis(int n, SCNNode* camera);
    void setPosition(GLKVector3 pos);
    void setLength(float length);
    
    void addAsChild(SCNNode* node);
    void doUpdate();
private:
    std::vector<SCNNode*> billboards;
    SCNNode* root;
};

#endif /* PeopleVis_hpp */
