//
//  loadMarker.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include <assert.h>
#include "loadMarker.h"

LoadMarker::LoadMarker() : LoadMarker(2) { }


LoadMarker::LoadMarker(size_t nLoads) {
    assert(nLoads >= 2);
    loadValues.resize(nLoads);
    loadArrows.resize(nLoads);
    loadLines.resize(nLoads - 1);
    
    // Create root node and set child links
    rootNode = [SCNNode node];
    for (int i = 0; i < nLoads; ++i) {
        loadArrows[i].addAsChild(rootNode);
        loadArrows[i].setTipSize(0.25);
        loadArrows[i].setMaxLength(maxHeight);
        
        if (i != 0) {
            loadLines[i-1].addAsChild(rootNode);
        }
    }
}

void LoadMarker::addAsChild(SCNNode *node) {
    [node addChildNode:rootNode];
}

void LoadMarker::setLoad(size_t loadIndex, double value) {
    assert(loadIndex < loadValues.size() && loadIndex >= 0);
    loadValues[loadIndex] = value;
}

void LoadMarker::setPosition(GLKVector3 start, GLKVector3 end) {
    GLKVector3 lineDirection = GLKVector3Subtract(end, start);
    
    GLKVector3 lastPos;
    for (int i = 0; i < loadArrows.size(); ++i) {
        float proportion = (float)i / (loadArrows.size() - 1);
        GLKVector3 interpolatedPos = GLKVector3Add(GLKVector3MultiplyScalar(lineDirection, proportion), start);
        loadArrows[i].setPosition(interpolatedPos);
        loadArrows[i].setIntensity(loadValues[i]);
        
        // Move load line
        if (i != 0) {
            GLKVector3 adjusted_start = GLKVector3Make(lastPos.x, lastPos.y + loadArrows[i-1].getTipSize() + maxHeight*loadValues[i-1], lastPos.z);
            GLKVector3 adjusted_end = GLKVector3Make(interpolatedPos.x, interpolatedPos.y + loadArrows[i].getTipSize() + maxHeight*loadValues[i], interpolatedPos.z);
            loadLines[i - 1].move(adjusted_start, adjusted_end);
//            loadLines[i - 1].move(lastPos, interpolatedPos);
        }
        
        lastPos = interpolatedPos;
    }
}

void LoadMarker::setMaxHeight(float h) {
    maxHeight = h;
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setMaxLength(h);
    }
    // TODO: Readjust positions
}
