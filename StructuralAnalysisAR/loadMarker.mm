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
        loadArrows[i].setTextHidden(true);
        
        if (i != 0) {
            loadLines[i-1].addAsChild(rootNode);
        }
    }
    
    // Make an empty that the label will follow
    labelEmpty = [SCNNode node];
    textLabel.setObject(labelEmpty);
    textLabel.setCenter(0.5, 0);
    [rootNode addChildNode:labelEmpty];
}

void LoadMarker::setScenes(SKScene* scene2d, SCNView* view3d) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setScenes(scene2d, view3d);
    }
    textLabel.setScenes(scene2d, view3d);
}

void LoadMarker::addAsChild(SCNNode *node) {
    [node addChildNode:rootNode];
}

void LoadMarker::doUpdate() {
    for (GrabbableArrow& arrow : loadArrows) {
        arrow.doUpdate();
    }
    textLabel.doUpdate();
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
    textLabel.setText([NSString stringWithFormat:@"%.1f k/ft", value]);
    refreshPositions();
}

float LoadMarker::getLoad(size_t loadIndex) {
    return loadValues[loadIndex];
}

void LoadMarker::setEnds(float start, float end) {
    startPos = GLKVector3Make(start, 0, 0);
    endPos = GLKVector3Make(end, 0, 0);
    refreshPositions();
}

void LoadMarker::setPosition(GLKVector3 pos) {
    rootNode.position = SCNVector3FromGLKVector3(pos);
}

void LoadMarker::setOrientation(GLKQuaternion ori) {
    rootNode.orientation = SCNVector4Make(ori.x, ori.y, ori.z, ori.w);
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

void LoadMarker::setThickness(float new_thickness) {
    thickness = new_thickness;
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
    float maxY = 0;
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
            // TODO: This only looks at load line start. Assuming flat load line
            if (adjusted_start.y > maxY) {
                maxY = adjusted_start.y;
            }
        }
        
        lastPos = interpolatedPos;
    }
    // Set position of text empty
    float middleX = (endPos.x + startPos.x) / 2;
    labelEmpty.position = SCNVector3Make(middleX, maxY + thickness, lastPos.z);
    textLabel.markPosDirty();
}

void LoadMarker::setHidden(bool hidden) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setHidden(hidden);
    }
    for (int i = 0; i < loadLines.size(); ++i) {
        loadLines[i].setHidden(hidden);
    }
    textLabel.setHidden(hidden);
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

uint32_t LoadMarker::draggingMode() const {
    return dragState;
}

void LoadMarker::touchBegan(GLKVector3 origin, GLKVector3 farHit) {
//    GLKMatrix4 moveToEnd = GLKMatrix4MakeTranslation(lastArrowValue * -root.transform.m12, lastArrowValue * root.transform.m22, lastArrowValue * root.transform.m32);
//    GLKMatrix4 endTransform = GLKMatrix4Multiply(moveToEnd, SCNMatrix4ToGLKMatrix4(root.transform));
//    GLKVector4 endPos4 = GLKMatrix4GetColumn(endTransform, 3);
    NSDictionary* hitOptions = @{
                                 SCNHitTestBoundingBoxOnlyKey: @YES
                                 };
    SCNVector3 origin_local = [rootNode convertPosition:SCNVector3FromGLKVector3(origin) fromNode:nil];
    SCNVector3 destination_local = [rootNode convertPosition:SCNVector3FromGLKVector3(farHit) fromNode:nil];
    NSArray *hitResults = [rootNode hitTestWithSegmentFromPoint:origin_local toPoint:destination_local options:hitOptions];
    if ([hitResults count] == 0) {
        printf("Error: No hit results\n");
        return;
    }
    SCNHitTestResult* hitTestResult = hitResults.firstObject;
    
    // Check if the hit node was a load line
    for (Line3d& loadLine : loadLines) {
        if (loadLine.hasNode(hitTestResult.node)) {
            dragState = vertically | horizontally;
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
    if (dragState & vertically) {
        GLKVector3 hitPoint = projectRay(origin, touchRay);
        
        GLKVector3 lineDir = GLKVector3Make(1, 0, 0);
        GLKVector3 loadDir = GLKVector3CrossProduct(GLKVector3Make(rootNode.transform.m13, rootNode.transform.m23, rootNode.transform.m33), lineDir);
        // Unsure about the negative on the x-axis, but it works?
//        GLKVector3 loadDir = GLKVector3Make(-rootNode.transform.m12, rootNode.transform.m22, rootNode.transform.m32);
        // Position of startPos + arrow min length along load direction
        GLKVector3 shiftedHitPoint = GLKVector3Subtract(hitPoint, SCNVector3ToGLKVector3(rootNode.position));
        GLKVector3 loadPos = GLKVector3Add(startPos, GLKVector3MultiplyScalar(loadDir, minHeight));
        GLKVector3 hitDir = GLKVector3Subtract(shiftedHitPoint, loadPos);
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

std::pair<float, float> LoadMarker::getDragPosition(GLKVector3 origin, GLKVector3 touchRay) {
    std::pair<float, float> movedPos = std::make_pair(startPos.x, endPos.x);
    
    if (dragState & (horizontallyR | horizontallyL | horizontally)) {
        GLKVector3 hitPoint = projectRay(origin, touchRay);
        GLKVector3 lineDir = GLKVector3Make(1, 0, 0);
        
        GLKVector3 shiftedHitPoint = GLKVector3Subtract(hitPoint, SCNVector3ToGLKVector3(rootNode.position));
        double dragDistance = GLKVector3DotProduct(lineDir, shiftedHitPoint);
        if (dragState == horizontallyL) {
            movedPos.first = dragDistance;
        }
        if (dragState == horizontallyR) {
            movedPos.second = dragDistance;
        }
        
        GLKVector3 fromStartVec = GLKVector3Subtract(hitPoint, dragStartPos);
        double differenceFromStart = GLKVector3DotProduct(fromStartVec, lineDir);
        if (dragState & horizontally) {
            movedPos.first = startAtDragBegin.x + differenceFromStart;
            movedPos.second = endAtDragBegin.x + differenceFromStart;
        }
    }
    return movedPos;
}

void LoadMarker::touchEnded() {
    dragState = none;
}

void LoadMarker::touchCancelled() {
    dragState = none;
}
