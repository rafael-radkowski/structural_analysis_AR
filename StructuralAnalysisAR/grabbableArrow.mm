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

GrabbableArrow::GrabbableArrow() {
    // Import the arrow object
    NSString* arrowHeadPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow_tip"] ofType:@"obj"];
    NSString* arrowBasePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow_base"] ofType:@"obj"];
    NSURL* arrowHeadUrl = [NSURL fileURLWithPath:arrowHeadPath];
    NSURL* arrowBaseUrl = [NSURL fileURLWithPath:arrowBasePath];
    MDLAsset* arrowHeadAsset = [[MDLAsset alloc] initWithURL:arrowHeadUrl];
    MDLAsset* arrowBaseAsset = [[MDLAsset alloc] initWithURL:arrowBaseUrl];
    
    arrowHead = [SCNNode nodeWithMDLObject:[arrowHeadAsset objectAtIndex:0]];
    arrowBase = [SCNNode nodeWithMDLObject:[arrowBaseAsset objectAtIndex:0]];
    
////    MDLObject* arrowTip = [arrowAsset objectAtPath:@"tip"];
////    MDLObject* root = [arrowAsset objectAtPath:@"tip"];
//    MDLMesh* loadedObj = (MDLMesh*) [arrowAsset objectAtIndex:0];
//    printf("asset had %lu objects\n", [loadedObj.submeshes count]);
//    printf("object called %s\n", [[loadedObj path] UTF8String]);
//    arrowNode = [SCNNode nodeWithMDLObject:[arrowAsset objectAtIndex:0]];
    
    // Make material for arrow
    SCNMaterial* arrowMat = [SCNMaterial material];
    arrowMat.diffuse.contents = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0];
    arrowHead.geometry.firstMaterial = arrowMat;
    arrowBase.geometry.firstMaterial = arrowMat;
    
    setThickness(defaultWidth);
    
    // Create a parent object for the arrow
    root = [SCNNode node];
    [root addChildNode:arrowHead];
    [root addChildNode:arrowBase];
    
    // Text stuff
    labelEmpty = [SCNNode node];
    [root addChildNode:labelEmpty];
    valueLabel.setObject(labelEmpty);
    valueLabel.setCenter(0.5, 1);
    setFormatString(@"%.1f k/ft");
}

void GrabbableArrow::setFormatString(NSString* str) {
    formatString = str;
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

void GrabbableArrow::setHidden(bool hidden) {
    root.hidden = hidden;
    valueLabel.setHidden(hidden || labelHidden);
}

bool GrabbableArrow::hasNode(SCNNode* node) {
    return node == arrowBase || node == arrowHead;
}

void GrabbableArrow::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
    valueLabel.markPosDirty();
}

void GrabbableArrow::setRotationAxisAngle(GLKVector4 axisAngle) {
    root.rotation = SCNVector4FromGLKVector4(axisAngle);
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


void GrabbableArrow::touchBegan(SCNHitTestResult* hitTestResult) {
//    GLKMatrix4 moveToEnd = GLKMatrix4MakeTranslation(lastArrowValue * -root.transform.m12, lastArrowValue * root.transform.m22, lastArrowValue * root.transform.m32);
//    GLKMatrix4 endTransform = GLKMatrix4Multiply(moveToEnd, SCNMatrix4ToGLKMatrix4(root.transform));
//    GLKVector4 endPos4 = GLKMatrix4GetColumn(endTransform, 3);
    
    if (hitTestResult.node == arrowBase || hitTestResult.node == arrowHead) {
        dragging = true;
    }
}

float GrabbableArrow::getDragValue(GLKVector3 origin, GLKVector3 touchRay, GLKVector3 cameraDir) {
    double value = lastArrowValue;
    if (dragging) {
        GLKMatrix4 arrowBaseGlobal = GLKMatrix4Multiply(
                                                        SCNMatrix4ToGLKMatrix4(root.transform),
                                                        SCNMatrix4ToGLKMatrix4(arrowBase.transform));
        GLKVector4 arrowPos4 = GLKMatrix4GetColumn(arrowBaseGlobal, 3);
        GLKVector3 arrowPos = GLKVector3Make(arrowPos4.x, arrowPos4.y, arrowPos4.z);
        
        double numerator = GLKVector3DotProduct(cameraDir, GLKVector3Subtract(arrowPos, origin));
        double denominator = GLKVector3DotProduct(cameraDir, touchRay);
        
        assert(denominator != 0);
        double d = numerator / denominator;
        GLKVector3 hitPoint = GLKVector3Add(GLKVector3MultiplyScalar(touchRay, d), origin);
        
        // Unsure about the negative on the x-axis, but it works?
        GLKVector3 arrowDir = GLKVector3Make(-root.transform.m12, root.transform.m22, root.transform.m32);
        GLKVector3 hitDir = GLKVector3Subtract(hitPoint, arrowPos);
        double value = GLKVector3DotProduct(arrowDir, hitDir);
        value = std::min(1.0, std::max(0.0, value));
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
    float normalizedValue = (value - minInput) / (maxInput - minInput);
    
    // adjust scale
//    arrowScale = ((new_value - 0.5) * 0.6) + 1;
//    arrow.root.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
    float lengthRange = maxLength - minLength; // The length range for the arrow base
    float desiredLength = (minLength - tipSize) + lengthRange * normalizedValue;
    arrowBase.scale = SCNVector3Make(arrowBase.scale.x, desiredLength, arrowBase.scale.z);
    labelEmpty.position = SCNVector3Make(0, desiredLength + tipSize, 0);
    valueLabel.markPosDirty();
    
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

