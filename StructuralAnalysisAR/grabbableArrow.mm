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
    
    setTipSize(defaultTipSize);
    
    // Create a parent object for the arrow
    root = [SCNNode node];
    [root addChildNode:arrowHead];
    [root addChildNode:arrowBase];
    
    // Create text label
//    valueLabel = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"%f", lastArrowValue]];
    valueLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    valueLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
//    valueLabel.fontName = @"Cochin";
    valueLabel.fontColor = [UIColor blackColor];
    valueLabel.fontSize = 26;
}

void GrabbableArrow::setScenes(SKScene* scene2d, SCNView* view3d) {
    textScene = scene2d;
    objectView = view3d;
    [textScene addChild:valueLabel];
    placeLabel();
}

void GrabbableArrow::addAsChild(SCNNode* node) {
    [node addChildNode:root];
}

void GrabbableArrow::setHidden(bool hidden) {
    root.hidden = hidden;
    valueLabel.hidden = hidden;
}


void GrabbableArrow::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
    placeLabel();
}

void GrabbableArrow::setRotationAxisAngle(GLKVector4 axisAngle) {
    root.rotation = SCNVector4FromGLKVector4(axisAngle);
}

void GrabbableArrow::placeLabel() {
    if (objectView) {
        SCNVector3 screenCoords = [objectView projectPoint:root.position];
        // Spritekit uses bottom-left as (0,0), while screen coordinates use top-right
        int reversedY = objectView.frame.size.height - screenCoords.y;
        valueLabel.position = CGPointMake(12 + screenCoords.x, reversedY);
    }
}

void GrabbableArrow::setTipSize(float newTipSize) {
    float tipScale = newTipSize / defaultTipSize;
    arrowHead.scale = SCNVector3Make(tipScale, tipScale, tipScale);
    arrowBase.position = SCNVector3Make(0, newTipSize, 0);
    
    tipSize = newTipSize;
}

float GrabbableArrow::getTipSize() {
    return tipSize;
}

void GrabbableArrow::setThickness(float thickness) {
    float widthScale = thickness / defaultWidth;
    arrowBase.scale = SCNVector3Make(widthScale, arrowBase.scale.y, widthScale);
    setTipSize(2.4 * thickness);
}


void GrabbableArrow::setMaxLength(float newLength) {
    maxLength = newLength;
    setIntensity(lastArrowValue);
}

float GrabbableArrow::getMaxLength() {
    return maxLength;
}

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
        value = MIN(1.0, MAX(0, value));
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
    float normalizedValue = (value - minInput) / (maxInput - minInput);
    
    // adjust scale
//    arrowScale = ((new_value - 0.5) * 0.6) + 1;
//    arrow.root.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
    arrowBase.scale = SCNVector3Make(arrowBase.scale.x, maxLength * normalizedValue, arrowBase.scale.z);
    
    // adjust color
//    double reverse_value = 1 - normalizedValue ;
//    double hue = 0.667 * reverse_value;
//    UIColor* color = [[UIColor alloc] initWithHue:hue saturation:1.0 brightness:0.8 alpha:1.0];
//    arrowHead.geometry.firstMaterial.diffuse.contents = color;
//    arrowBase.geometry.firstMaterial.diffuse.contents = color;
    
    valueLabel.text = [NSString stringWithFormat:@"%.1 flbf", value];
}

void GrabbableArrow::setWide(bool wide) {
    widthScale = wide ? 1.5 : 1.0;
    [SCNTransaction begin];
    SCNTransaction.animationDuration = 0.5;
    arrowHead.scale = SCNVector3Make(widthScale, arrowHead.scale.y, widthScale);
    [SCNTransaction commit];
}
