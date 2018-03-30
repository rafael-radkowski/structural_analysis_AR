//
//  grabbableArrow.mm
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/24/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//


#import "grabbableArrow.h"
#include <stdio.h>
#import <assert.h>
#include <algorithm>

GrabbableArrow::GrabbableArrow(float hit_scale, bool as_loadmarker, bool reversed)
: lastArrowValue(0)
, reversed(reversed)
, extraRotation(GLKQuaternionIdentity)
, hitBoxScale(hit_scale)
, partOfLoadMarker(as_loadmarker) {
    // Import the arrow object
    NSString* arrowHeadPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow_tip"] ofType:@"obj"];
    NSString* arrowBasePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow_base"] ofType:@"obj"];
    NSURL* arrowHeadUrl = [NSURL fileURLWithPath:arrowHeadPath];
    NSURL* arrowBaseUrl = [NSURL fileURLWithPath:arrowBasePath];
    MDLAsset* arrowHeadAsset = [[MDLAsset alloc] initWithURL:arrowHeadUrl];
    MDLAsset* arrowBaseAsset = [[MDLAsset alloc] initWithURL:arrowBaseUrl];
    
    arrowHead = [SCNNode nodeWithMDLObject:[arrowHeadAsset objectAtIndex:0]];
    arrowBase = [SCNNode nodeWithMDLObject:[arrowBaseAsset objectAtIndex:0]];
    
    // make hit bounding box
    hitBox = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:hit_scale height:1 length:hit_scale chamferRadius:0]];
    hitBox.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0);
    // For some reason, in iOS 11, the search for hidden nodes flag is respected (hittest called in LoadMarker),
    // but in iOS 10, it doesn't work
    if (@available(iOS 11, *)) {
        hitBox.hidden = YES;
    }
    else {
        hitBox.opacity = 0;
        hitBox.geometry.firstMaterial.writesToDepthBuffer = NO;
    }

    // Make material for arrow
    arrowMat = [SCNMaterial material];
    setColor(1, 0, 0);
    arrowHead.geometry.firstMaterial = arrowMat;
    arrowBase.geometry.firstMaterial = arrowMat;

    // Create a parent object for the arrow
    root = [SCNNode node];
    [root addChildNode:arrowHead];
    [root addChildNode:arrowBase];
    [root addChildNode:hitBox];
    
    // Text stuff
    labelEmpty = [SCNNode node];
    [root addChildNode:labelEmpty];
    valueLabel.setObject(labelEmpty);
    valueLabel.setCenter(0.5, 1);
    setFormatString(@"%.1f k/ft");
    
    setThickness(defaultWidth);
}

void GrabbableArrow::setFormatString(NSString* str) {
    formatString = str;
    // update text
    setIntensity(lastArrowValue);
}

void GrabbableArrow::setScenes(SKScene* scene2d, SCNView* view3d) {
    textScene = scene2d;
    objectView = view3d;
    valueLabel.setScenes(scene2d, view3d);
}

void GrabbableArrow::addAsChild(SCNNode* node) {
    [node addChildNode:root];
}

void GrabbableArrow::doUpdate() {
    valueLabel.doUpdate();
}

void GrabbableArrow::setTextHidden(bool hide) {
    labelHidden = hide;
    valueLabel.setHidden(hide);
}

void GrabbableArrow::setLabelFollow(bool follow) {
    labelFollows = follow;
    labelEmpty.position = SCNVector3Make(0, 0, 0);
    setIntensity(lastArrowValue);
}

void GrabbableArrow::setHidden(bool hidden) {
    root.hidden = hidden;
    valueLabel.setHidden(hidden || labelHidden);
}

bool GrabbableArrow::hasNode(SCNNode* node) {
    return node == hitBox || node == arrowBase || node == arrowHead;
}

void GrabbableArrow::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
    valueLabel.markPosDirty();
}

void GrabbableArrow::setRotationAxisAngle(GLKVector4 axisAngle) {
    setOrientation(GLKQuaternionMakeWithAngleAndAxis(axisAngle.w, axisAngle.x, axisAngle.y, axisAngle.z));
}

void GrabbableArrow::setOrientation(GLKQuaternion quat) {
    setRotation = quat;
    GLKQuaternion final_rot = GLKQuaternionMultiply(extraRotation, setRotation);
    root.orientation = SCNVector4Make(final_rot.q[0], final_rot.q[1], final_rot.q[2], final_rot.q[3]);
}

void GrabbableArrow::setThickness(float thickness) {
    // Set the tip scale to be proportional
    float newTipSize = 2.4 * thickness;
    float tipScale = newTipSize / defaultTipSize;
    arrowHead.scale = SCNVector3Make(tipScale, tipScale, tipScale);
    arrowBase.position = SCNVector3Make(0, newTipSize, 0);
    tipSize = newTipSize;

    // Update arrow base length, since tip size is different
    float widthScale = thickness / defaultWidth;
    float baseLength = minLength - tipSize;
    arrowBase.scale = SCNVector3Make(widthScale, baseLength, widthScale);
    
    hitBox.scale = SCNVector3Make(thickness, hitBox.scale.y, thickness);
    
    // Call setIntensity to set positions
    setIntensity(lastArrowValue);
}

void GrabbableArrow::setMaxLength(float newLength) {
    maxLength = newLength;
    setIntensity(lastArrowValue);
}

void GrabbableArrow::setMinLength(float newLength) {
    minLength = newLength;
    setIntensity(lastArrowValue);
}

float GrabbableArrow::getMaxLength() {
    return maxLength;
}

float GrabbableArrow::getMinLength() {
    return minLength;
}

//
//void GrabbableArrow::setStartLength(float length) {
//    minLength = length - tipSize;
//    setIntensity(lastArrowValue);
//}

void GrabbableArrow::setInputRange(float minValue, float maxValue) {
    minInput = minValue;
    maxInput = maxValue;
    
    setIntensity(lastArrowValue);
}

std::pair<float, float> GrabbableArrow::getInputRange() {
    return std::make_pair(minInput, maxInput);
}


void GrabbableArrow::touchBegan(GLKVector3 origin, GLKVector3 farHit) {
//    GLKMatrix4 moveToEnd = GLKMatrix4MakeTranslation(lastArrowValue * -root.transform.m12, lastArrowValue * root.transform.m22, lastArrowValue * root.transform.m32);
//    GLKMatrix4 endTransform = GLKMatrix4Multiply(moveToEnd, SCNMatrix4ToGLKMatrix4(root.transform));
//    GLKVector4 endPos4 = GLKMatrix4GetColumn(endTransform, 3);
    
    NSDictionary* hitOptions = @{
                                 SCNHitTestBoundingBoxOnlyKey: @YES,
                                 SCNHitTestIgnoreHiddenNodesKey: @NO, // need to test for hidden nodes for hidden extra hitBox on lines and arrows
                                 SCNHitTestFirstFoundOnlyKey: @NO,
                                 SCNHitTestIgnoreChildNodesKey: @NO
                                 };
    SCNVector3 origin_local = [root convertPosition:SCNVector3FromGLKVector3(origin) fromNode:nil];
    SCNVector3 destination_local = [root convertPosition:SCNVector3FromGLKVector3(farHit) fromNode:nil];
    NSArray *hitResults = [root hitTestWithSegmentFromPoint:origin_local toPoint:destination_local options:hitOptions];
    
    for (SCNHitTestResult* hitTestResult : hitResults) {
        if (hitTestResult.node == arrowBase || hitTestResult.node == arrowHead || hitTestResult.node == hitBox) {
            dragging = true;
            break;
        }
    }
}

float GrabbableArrow::getDragValue(GLKVector3 origin, GLKVector3 touchRay, GLKVector3 cameraDir) {
    // TODO: This probably doesn't work when reversed
    double value = lastArrowValue;
    if (dragging) {
        GLKVector4 arrowPos4 = GLKMatrix4GetColumn(SCNMatrix4ToGLKMatrix4(root.transform), 3);
        GLKVector3 arrowPos = GLKVector3Make(arrowPos4.x, arrowPos4.y, arrowPos4.z);
        
        double numerator = GLKVector3DotProduct(cameraDir, GLKVector3Subtract(arrowPos, origin));
        double denominator = GLKVector3DotProduct(cameraDir, touchRay);
        
        assert(denominator != 0);
        double d = numerator / denominator;
        GLKVector3 hitPoint = GLKVector3Add(GLKVector3MultiplyScalar(touchRay, d), origin);
        
        // Unsure about the negative on the x-axis, but it works?
        GLKVector3 arrowDir = GLKVector3Make(-root.transform.m12, root.transform.m22, root.transform.m32);
        GLKVector3 hitDir = GLKVector3Subtract(hitPoint, arrowPos);
        double rawValue = GLKVector3DotProduct(arrowDir, hitDir);
        double normValue = (rawValue - minLength) / (maxLength - minLength);
        normValue = std::min(1.0, std::max(0.0, normValue));
        value = minInput + normValue * (maxInput - minInput);
        lastArrowValue = value;
    }
    else {
        value = lastArrowValue;
    }
    
    return value;
}

void GrabbableArrow::touchEnded() {
    dragging = false;
}

void GrabbableArrow::touchCancelled() {
    dragging = false;
}

void GrabbableArrow::setIntensity(float value) {
    lastArrowValue = value;
    if (!negated && value < 0) {
        value = std::abs(value);
        extraRotation = GLKQuaternionMakeWithAngleAndAxis(M_PI, 0, 1, 0);
        setOrientation(setRotation);
        negated = true;
    }
    else if (negated && value > 0) {
        extraRotation = GLKQuaternionIdentity;
        setOrientation(setRotation);
        negated = false;
    }
    float normalizedValue = (value - minInput) / (maxInput - minInput);
    
    // adjust scale
//    arrowScale = ((new_value - 0.5) * 0.6) + 1;
//    arrow.root.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
    float lengthRange = maxLength - minLength; // The length range for the arrow base
    float desiredLength = (minLength - tipSize) + lengthRange * normalizedValue;
    // hitbox should start at tip and to go tend of arrow
    float hitBoxLength = desiredLength + tipSize;
    // If is part of a LoadMarker, need to subtract half the width from the length so it doesn't overlap the LoadMarker it's attached to
    // This is only necessary because the SceneKit hitTest is broken and sometimes doesn't detect things that are overlapped
    if (partOfLoadMarker) {
        hitBoxLength -=  (hitBoxScale * hitBox.scale.x) / 2;
    }
    arrowBase.scale = SCNVector3Make(arrowBase.scale.x, desiredLength, arrowBase.scale.z);
    hitBox.scale = SCNVector3Make(hitBox.scale.x, hitBoxLength, hitBox.scale.z);
    
    if (labelFollows) {
        if (reversed) {
            arrowBase.position = SCNVector3Make(0, -desiredLength, 0);
            arrowHead.position = SCNVector3Make(0, -desiredLength - tipSize, 0);
            hitBox.position = SCNVector3Make(0, -hitBoxLength, 0);
            labelEmpty.position = SCNVector3Make(0, -desiredLength - tipSize, 0);
        }
        else {
            labelEmpty.position = SCNVector3Make(0, desiredLength + tipSize, 0);
        }
        valueLabel.markPosDirty();
    }

    // adjust color
//    double reverse_value = 1 - normalizedValue ;
//    double hue = 0.667 * reverse_value;
//    UIColor* color = [[UIColor alloc] initWithHue:hue saturation:1.0 brightness:0.8 alpha:1.0];
//    arrowHead.geometry.firstMaterial.diffuse.contents = color;
//    arrowBase.geometry.firstMaterial.diffuse.contents = color;
    
//    valueLabel.text = [NSString stringWithFormat:@"%.1f k", value];
    valueLabel.setText([NSString stringWithFormat:formatString, value]);
}

void GrabbableArrow::setWide(bool wide) {
    widthScale = wide ? 1.5 : 1.0;
    [SCNTransaction begin];
    SCNTransaction.animationDuration = 0.5;
    arrowHead.scale = SCNVector3Make(widthScale, arrowHead.scale.y, widthScale);
    [SCNTransaction commit];
}

void GrabbableArrow::setColor(float r, float g, float b) {
    arrowMat.diffuse.contents = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

