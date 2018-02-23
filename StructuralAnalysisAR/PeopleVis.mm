//
//  PeopleVis.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/11/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "PeopleVis.h"
#include <cstdlib>
#include <ctime>
#include <algorithm>

PeopleVis::PeopleVis(int n) {
    srand(static_cast<uint>(time(NULL)));
    
    root = [SCNNode node];
//    MDLTexture* texture = [MDLTexture textureNamed:@"stick_man.png"];
    
    setNumPeople(n);
}

void PeopleVis::setNumPeople(int n) {
    n = std::max(n, 0); // Don't let go below 0
    long n_delete = billboards.size() - n;
    if (n_delete > 0) {
        for (int i = n; i < billboards.size(); ++i) {
            [billboards[i] removeFromParentNode];
        }
        billboards.erase(billboards.begin() + n, billboards.end());
    }
    
    long n_add = n - billboards.size();
    if (n_add > 0) {
        for (int i = 0; i < n_add; ++i) {
            SCNPlane* plane = [SCNPlane planeWithWidth:1 height:1];
            SCNNode* billboard = [SCNNode nodeWithGeometry:plane];
            billboard.constraints = [NSArray arrayWithObject:[SCNBillboardConstraint billboardConstraint]];
            
            SCNMaterial* mat = [SCNMaterial material];
    //        mat.diffuse.contents = [SCNMaterialProperty materialPropertyWithContents:@"stick_man.png"];
            NSString* texToLoad = rand() >= (RAND_MAX / 2) ? @"stick_man.png" : @"stick_woman.png";
            mat.diffuse.contents = [UIImage imageNamed:texToLoad];
            mat.lightingModelName = SCNLightingModelConstant;
            billboard.geometry.firstMaterial = mat;
            
            billboards.push_back(billboard);
            [root addChildNode:billboard];
        }
    }
    peopleOffsets.resize(n, 0);
    
    // Set scales
    setHeight(height);
    refreshPositions();
}

void PeopleVis::addAsChild(SCNNode *node) {
    [node addChildNode:root];
}

void PeopleVis::setWeight(float pounds) {
    float avgWeight = 1000;
    int n_people = static_cast<int>(pounds / avgWeight);
    setNumPeople(n_people);
}


void PeopleVis::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
}

void PeopleVis::setLength(float new_length) {
    length = new_length;
    refreshPositions();
}

void PeopleVis::setHeight(float new_height) {
    height = new_height;
    for (SCNNode* billboard : billboards) {
        // For some reason, setting the scale on the billboard node does not work.
        // Possibly the SCNPlane object automatically adjusts so the width and height attributes are always correct, despite node scale
        ((SCNPlane*)billboard.geometry).width = height;
        ((SCNPlane*)billboard.geometry).height = height;
    }
}

void PeopleVis::shuffle() {
    std::random_shuffle(billboards.begin(), billboards.end());
    
    float spacing = length / (billboards.size() - 1); // size() - 1 spaces between people
    // How much to allow random deviation from center, per person
    float randDeviation = spacing * 0.5;
    for (float& offset : peopleOffsets) {
        float norm_random = (float)rand() / RAND_MAX; // range in [0,1]
        offset = norm_random * randDeviation;
    }
    refreshPositions();
}

void PeopleVis::refreshPositions() {
    float spacing = length / (billboards.size() - 1); // size() - 1 spaces between people
    
    for (int i = 0; i < billboards.size(); ++i) {
        float pos_x = (spacing * i) + peopleOffsets[i];
        billboards[i].position = SCNVector3Make(pos_x, 0, 0);
    }
}
