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
    void setWeight(float pounds);
    void setNumPeople(int n);
    void setPosition(GLKVector3 pos);
    void setLength(float length);
    void setHeight(float height);
    
    // Rearranges the people by random
    void shuffle();
    
    void addAsChild(SCNNode* node);
    void doUpdate();
private:
    void refreshPositions();
    std::vector<SCNNode*> billboards;
    std::vector<float> peopleOffsets;
    SCNNode* root;
    float length = 10;
    float height = 6;
};

#endif /* PeopleVis_hpp */
