//
//  loadMarker.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include <assert.h>
#include "loadMarker.h"
#include <algorithm>

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

void LoadMarker::doUpdate() {
    for (GrabbableArrow& arrow : loadArrows) {
        arrow.doUpdate();
    }
}

void LoadMarker::setLoad(size_t loadIndex, double value) {
    assert(loadIndex < loadValues.size() && loadIndex >= 0);
    lastIntensity = value;
    loadValues[loadIndex] = value;
    refreshPositions();
}

void LoadMarker::setLoad(double value) {
    lastIntensity = value;
    for (int i = 0; i < loadValues.size(); ++i) {
        loadValues[i] = value;
    }
    refreshPositions();
}

float LoadMarker::getLoad(size_t loadIndex) {
    return loadValues[loadIndex];
}

void LoadMarker::setPosition(GLKVector3 start, GLKVector3 end) {
    startPos = start;
    endPos = end;
    refreshPositions();
}

const GLKVector3 LoadMarker::getStartPos() {
    return startPos;
}

const GLKVector3 LoadMarker::getEndPos() {
    return endPos;
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
            GLKVector3 adjusted_start = GLKVector3Make(lastPos.x, lastPos.y + minHeight + lengthRange*prevNormalizedValue, lastPos.z);
            GLKVector3 adjusted_end = GLKVector3Make(interpolatedPos.x, interpolatedPos.y + minHeight + lengthRange*thisNormalizedValue, interpolatedPos.z);
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

LoadMarker::Dragging LoadMarker::draggingMode() const {
    return dragState;
}

void LoadMarker::touchBegan(GLKVector3 origin, SCNHitTestResult* hitTestResult) {
//    GLKMatrix4 moveToEnd = GLKMatrix4MakeTranslation(lastArrowValue * -root.transform.m12, lastArrowValue * root.transform.m22, lastArrowValue * root.transform.m32);
//    GLKMatrix4 endTransform = GLKMatrix4Multiply(moveToEnd, SCNMatrix4ToGLKMatrix4(root.transform));
//    GLKVector4 endPos4 = GLKMatrix4GetColumn(endTransform, 3);
    
    // Check if the hit node was a load line
    for (Line3d& loadLine : loadLines) {
        if (loadLine.hasNode(hitTestResult.node)) {
            dragState = vertically;
        }
    }
    // check for left arrow
    if (loadArrows[0].hasNode(hitTestResult.node)) {
        dragState = horizontallyL;
    }
    // check for right arrow
    else if (loadArrows[loadArrows.size() - 1].hasNode(hitTestResult.node)) {
        dragState = horizontallyR;
    }
    // Check for one of the middle arrows
    else {
        for (int i = 1; i < loadArrows.size() - 1; ++i) {
            if (loadArrows[i].hasNode(hitTestResult.node)) {
                dragState = horizontally;
            }
        }
    }
    GLKVector3 hitPoint = SCNVector3ToGLKVector3(hitTestResult.worldCoordinates);
    dragStartPos = projectRay(origin, GLKVector3Subtract(hitPoint, origin));
    startAtDragBegin = startPos;
    endAtDragBegin = endPos;
}

GLKVector3 LoadMarker::projectRay(const GLKVector3 origin, const GLKVector3 touchRay) {
        GLKVector3 planeNormal = GLKVector3Make(rootNode.transform.m13, rootNode.transform.m23, rootNode.transform.m33);
        double numerator = GLKVector3DotProduct(planeNormal, GLKVector3Subtract(startPos, origin));
        double denominator = GLKVector3DotProduct(planeNormal, touchRay);
        
        assert(denominator != 0);
        double d = numerator / denominator;
        GLKVector3 hitPoint = GLKVector3Add(GLKVector3MultiplyScalar(touchRay, d), origin);
        return hitPoint;
}

float LoadMarker::getDragValue(GLKVector3 origin, GLKVector3 touchRay) {
    double value = lastIntensity;
    if (dragState == vertically) {
        GLKVector3 hitPoint = projectRay(origin, touchRay);
        
        GLKVector3 lineDir = GLKVector3Normalize(GLKVector3Subtract(endPos, startPos));
        GLKVector3 loadDir = GLKVector3CrossProduct(GLKVector3Make(rootNode.transform.m13, rootNode.transform.m23, rootNode.transform.m33), lineDir);
        // Unsure about the negative on the x-axis, but it works?
//        GLKVector3 loadDir = GLKVector3Make(-rootNode.transform.m12, rootNode.transform.m22, rootNode.transform.m32);
        // Position of startPos + arrow min length along load direction
        GLKVector3 loadPos = GLKVector3Add(startPos, GLKVector3MultiplyScalar(loadDir, minHeight));
        GLKVector3 hitDir = GLKVector3Subtract(hitPoint, loadPos);
        double normalizedValue = GLKVector3DotProduct(loadDir, hitDir);
        double heightRange = maxHeight - minHeight;
        normalizedValue = std::min(heightRange, std::max(0.0, normalizedValue));
        normalizedValue = normalizedValue / heightRange;
        value = minInput + normalizedValue * (maxInput - minInput);
    }
    else {
        value = lastIntensity;
    }
   
    return value;
}

std::pair<GLKVector3, GLKVector3> LoadMarker::getDragPosition(GLKVector3 origin, GLKVector3 touchRay) {
    std::pair<GLKVector3, GLKVector3> movedPos = std::make_pair(startPos, endPos);
    
    if (dragState == horizontallyR || dragState == horizontallyL || dragState == horizontally) {
        GLKVector3 hitPoint = projectRay(origin, touchRay);
        GLKVector3 lineDir = GLKVector3Normalize(GLKVector3Subtract(endPos, startPos));
        
        GLKVector3 shiftedHitPoint = GLKVector3Subtract(hitPoint, startPos);
        double dragDistance = GLKVector3DotProduct(lineDir, shiftedHitPoint);
        GLKVector3 dragPosition = GLKVector3Add(startPos, GLKVector3MultiplyScalar(lineDir, dragDistance));
        if (dragState == horizontallyL) {
            movedPos.first = dragPosition;
        }
        if (dragState == horizontallyR) {
            movedPos.second = dragPosition;
        }
        
        GLKVector3 fromStartVec = GLKVector3Subtract(hitPoint, dragStartPos);
        double differenceFromStart = GLKVector3DotProduct(fromStartVec, lineDir);
        if (dragState == horizontally) {
            movedPos.first = GLKVector3Add(startAtDragBegin, GLKVector3MultiplyScalar(lineDir, differenceFromStart));
            movedPos.second = GLKVector3Add(endAtDragBegin, GLKVector3MultiplyScalar(lineDir, differenceFromStart));
        }
    }
    // Don't let the ends get collapsed too far
    if (movedPos.second.x - movedPos.first.x < 5) {
        movedPos = std::make_pair(startPos, endPos);
    }
    return movedPos;
}

void LoadMarker::touchEnded() {
    dragState = none;
}

void LoadMarker::touchCancelled() {
    dragState = none;
}
