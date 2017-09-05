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
        loadArrows[i].setMaxLength(maxHeight);
        
        if (i != 0) {
            loadLines[i-1].addAsChild(rootNode);
        }
    }
}

void LoadMarker::setScenes(SKScene* scene2d, SCNView* view3d) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setScenes(scene2d, view3d);
    }
}

void LoadMarker::addAsChild(SCNNode *node) {
    [node addChildNode:rootNode];
}

void LoadMarker::setLoad(size_t loadIndex, double value) {
    assert(loadIndex < loadValues.size() && loadIndex >= 0);
    loadValues[loadIndex] = value;
    refreshPositions();
}

void LoadMarker::setPosition(GLKVector3 start, GLKVector3 end) {
    startPos = start;
    endPos = end;
    refreshPositions();
}

void LoadMarker::setMaxHeight(float h) {
    maxHeight = h;
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setMaxLength(h);
    }
    refreshPositions();
}

void LoadMarker::setMinHeight(float h) {
    minHeight = h;
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setMinLength(h);
    }
    refreshPositions();
}

void LoadMarker::setThickness(float thickness) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setThickness(thickness);
    }
    for (int i = 0; i < loadLines.size(); ++i) {
        loadLines[i].setThickness(thickness);
    }
    // Need to refresh since tip size changed
    refreshPositions();
}

void LoadMarker::refreshPositions() {
    GLKVector3 lineDirection = GLKVector3Subtract(endPos, startPos);
    
    float lengthRange = maxHeight - minHeight;
    GLKVector3 lastPos;
    for (int i = 0; i < loadArrows.size(); ++i) {
        float proportion = (float)i / (loadArrows.size() - 1);
        GLKVector3 interpolatedPos = GLKVector3Add(GLKVector3MultiplyScalar(lineDirection, proportion), startPos);
        loadArrows[i].setPosition(interpolatedPos);
        loadArrows[i].setIntensity(loadValues[i]);
        
        float prevNormalizedValue = (loadValues[i-1] - minInput) / (maxInput - minInput);
        float thisNormalizedValue = (loadValues[i] - minInput) / (maxInput - minInput);
        // Move load line
        if (i != 0) {
            GLKVector3 adjusted_start = GLKVector3Make(lastPos.x, lastPos.y + loadArrows[i-1].getStartLength() + lengthRange*prevNormalizedValue, lastPos.z);
            GLKVector3 adjusted_end = GLKVector3Make(interpolatedPos.x, interpolatedPos.y + loadArrows[i].getStartLength() + lengthRange*thisNormalizedValue, interpolatedPos.z);
            loadLines[i - 1].move(adjusted_start, adjusted_end);
        }
        
        lastPos = interpolatedPos;
    }
}

void LoadMarker::setHidden(bool hidden) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setHidden(hidden);
    }
    for (int i = 0; i < loadLines.size(); ++i) {
        loadLines[i].setHidden(hidden);
    }
}

void LoadMarker::setInputRange(float minValue, float maxValue) {
    minInput = minValue;
    maxInput = maxValue;
    
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setInputRange(minValue, maxValue);
    }
    refreshPositions();
}

std::pair<float, float> LoadMarker::getInputRange() {
    return std::make_pair(minInput, maxInput);
}
