//
//  loadMarker.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include <assert.h>
#include "LoadMarker.h"
#include <algorithm>

LoadMarker::LoadMarker() : LoadMarker(2, false) { }


LoadMarker::LoadMarker(size_t nLoads, bool reversed, int n_labels, float hit_overlap)
: reversed(reversed) {
    assert(nLoads >= 2);
    loadValues.resize(nLoads);
//    loadArrows.resize(nLoads);
    
    // Make lines with 1.5x hit area
    // A vector::resize(n, instasnce_to_copy) call should work, but Line3d and GrabbableArrow doesn't have a working copy constructor, since it holds Objective-C objects
    for (int i = 0; i < nLoads - 1; ++i) {
        loadLines.emplace_back(hit_overlap);
        loadArrows.emplace_back(hit_overlap, false);
    }
    // Need one extra arrow
    loadArrows.emplace_back(hit_overlap, false);

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
    textLabels.resize(n_labels);
    labelEmpties.resize(n_labels);
    for (int i = 0; i < n_labels; ++i) {
        labelEmpties[i] = [SCNNode node];
        textLabels[i].setObject(labelEmpties[i]);
        textLabels[i].setCenter(0.5, 0);
        [rootNode addChildNode:labelEmpties[i]];
    }
    
    setFormatString(@"%.1f k/ft");
}

void LoadMarker::setScenes(SKScene* scene2d, SCNView* view3d) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setScenes(scene2d, view3d);
    }
    for (OverlayLabel& textLabel : textLabels) {
        textLabel.setScenes(scene2d, view3d);
    }
}

void LoadMarker::addAsChild(SCNNode *node) {
    [node addChildNode:rootNode];
}

void LoadMarker::doUpdate() {
    for (GrabbableArrow& arrow : loadArrows) {
        arrow.doUpdate();
    }
    for (OverlayLabel& textLabel : textLabels) {
        textLabel.doUpdate();
    }
}

void LoadMarker::setFormatString(NSString* str) {
    formatString = str;
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
    for (OverlayLabel& textLabel : textLabels) {
        textLabel.setText([NSString stringWithFormat:formatString, value]);
    }
    refreshPositions();
}

void LoadMarker::setLoadInterpolate(double val_l, double val_r) {
    for (int i = 0; i < loadValues.size(); ++i) {
        double interp_fac = (double)i / (loadValues.size() - 1);
        double interp_load = val_l + (val_r - val_l) * interp_fac;
        loadValues[i] = interp_load;
    }
    size_t n_labels = textLabels.size();
    // One label should be in the middle, averaged
    if (n_labels == 1) {
        textLabels[0].setText([NSString stringWithFormat:formatString, (val_l + val_r) / 2]);
    }
    // Multiple labels should include the endpoints
    for (int i = 0; i < n_labels; ++i) {
        double interp_fac = static_cast<float>(i) / (n_labels - 1);
        double interp_load = val_l + (val_r - val_l) * interp_fac;
        textLabels[i].setText([NSString stringWithFormat:formatString, interp_load]);
    }
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
    float maxY = 0; float minY = 0;
    for (int i = 0; i < loadArrows.size(); ++i) {
        float proportion = (float)i / (loadArrows.size() - 1);
        GLKVector3 interpolatedPos = GLKVector3Add(GLKVector3MultiplyScalar(lineDirection, proportion), startPos);

        float thisNormalizedValue = (loadValues[i] - minInput) / (maxInput - minInput);
        // actual height of load marker
        float this_load_height = minHeight + lengthRange * thisNormalizedValue;

        // For regular mode, arrow tips have y-position of 0. In "reversed" mode, arrow tips are height of marker
        GLKVector3 arrowPos = interpolatedPos;
        if (reversed) {
            arrowPos = GLKVector3Add(interpolatedPos, GLKVector3Make(0, -(this_load_height), 0));
        }
        
        loadArrows[i].setPosition(arrowPos);
        loadArrows[i].setIntensity(loadValues[i]);
        
        // Move load line
        if (i != 0) {
            float prevNormalizedValue = (loadValues[i-1] - minInput) / (maxInput - minInput);
            float prev_load_height = minHeight + lengthRange * prevNormalizedValue;
            
            GLKVector3 adjusted_start = GLKVector3Make(lastPos.x, lastPos.y + prev_load_height, lastPos.z);
            GLKVector3 adjusted_end = GLKVector3Make(interpolatedPos.x, interpolatedPos.y + this_load_height, interpolatedPos.z);
            if (reversed) {
                adjusted_start.y = -adjusted_start.y;
                adjusted_end.y = -adjusted_end.y;
            }
            loadLines[i - 1].move(adjusted_start, adjusted_end);
            // TODO: This only looks at load line start. Assuming flat load line
            maxY = std::max(maxY, adjusted_start.y);
            minY = std::min(minY, adjusted_start.y);
        }
        
        lastPos = interpolatedPos;
    }
    // Set position of text empties
    
    size_t n_labels = textLabels.size();
    // Weird stuff, since when there's one label, it should be in the middle, but multiple should have one at each endpoint
    float separation = n_labels == 1 ? 0 : (endPos.x - startPos.x) / (n_labels - 1);
    float start_x = n_labels == 1 ? (endPos.x + startPos.x) / 2 : 0;
    for (int i = 0; i < n_labels; ++i) {
        float posX = start_x + static_cast<float>(i) * separation;
        if (reversed) {
            labelEmpties[i].position = SCNVector3Make(posX, minY - thickness, lastPos.z);
        }
        else {
            labelEmpties[i].position = SCNVector3Make(posX, maxY + thickness, lastPos.z);
        }
        textLabels[i].markPosDirty();
    }
}

void LoadMarker::setHidden(bool hidden) {
    for (int i = 0; i < loadArrows.size(); ++i) {
        loadArrows[i].setHidden(hidden);
    }
    for (int i = 0; i < loadLines.size(); ++i) {
        loadLines[i].setHidden(hidden);
    }
    for (OverlayLabel& textLabel : textLabels) {
        textLabel.setHidden(hidden);
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

uint32_t LoadMarker::draggingMode() const {
    return dragState;
}

void LoadMarker::touchBegan(GLKVector3 origin, GLKVector3 farHit) {
//    GLKMatrix4 moveToEnd = GLKMatrix4MakeTranslation(lastArrowValue * -root.transform.m12, lastArrowValue * root.transform.m22, lastArrowValue * root.transform.m32);
//    GLKMatrix4 endTransform = GLKMatrix4Multiply(moveToEnd, SCNMatrix4ToGLKMatrix4(root.transform));
//    GLKVector4 endPos4 = GLKMatrix4GetColumn(endTransform, 3);
    NSDictionary* hitOptions = @{
                                 SCNHitTestBoundingBoxOnlyKey: @YES,
                                 SCNHitTestIgnoreHiddenNodesKey: @NO, // need to test for hidden nodes for hidden extra hitBox on lines and arrows
                                 SCNHitTestFirstFoundOnlyKey: @NO
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
        GLKVector3 planeNormal = GLKVector3Make(rootNode.transform.m31, rootNode.transform.m32, rootNode.transform.m33);
        double numerator = GLKVector3DotProduct(planeNormal, GLKVector3Subtract(startPos, origin));
        double denominator = GLKVector3DotProduct(planeNormal, touchRay);
        
        assert(denominator != 0);
        double d = numerator / denominator;
        GLKVector3 hitPoint = GLKVector3Add(GLKVector3MultiplyScalar(touchRay, d), origin);
        return hitPoint;
}

float LoadMarker::getDragPoint(GLKVector3 origin, GLKVector3 touchRay) {
    GLKVector3 hitPoint = projectRay(origin, touchRay);
    // global direction of x-axis
    GLKVector3 lineDir = GLKVector3Make(rootNode.transform.m11, rootNode.transform.m12, rootNode.transform.m13);
    
    GLKVector3 shiftedHitPoint = GLKVector3Subtract(hitPoint, SCNVector3ToGLKVector3(rootNode.position));
    double dragDistance = GLKVector3DotProduct(lineDir, shiftedHitPoint);
    return dragDistance;
}

float LoadMarker::getDragValue(GLKVector3 origin, GLKVector3 touchRay) {
    double value;
    if (dragState & vertically) {
        GLKVector3 hitPoint = projectRay(origin, touchRay);
        
        GLKVector3 lineDir = GLKVector3Make(1, 0, 0);
        GLKVector3 loadDir = GLKVector3Make(rootNode.transform.m21, rootNode.transform.m22, rootNode.transform.m23);
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
