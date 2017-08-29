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
    
    arrowBase.position = SCNVector3Make(0, 0.3, 0);
    // Create a parent object for the arrow
    root = [SCNNode node];
    [root addChildNode:arrowHead];
    [root addChildNode:arrowBase];
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
    // adjust scale
//    arrowScale = ((new_value - 0.5) * 0.6) + 1;
//    arrow.root.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
    arrowBase.scale = SCNVector3Make(1, value, 1);
    
    // adjust color
    double reverse_value = 1 - value;
    double hue = 0.667 * reverse_value;
    UIColor* color = [[UIColor alloc] initWithHue:hue saturation:1.0 brightness:0.8 alpha:1.0];
    arrowHead.geometry.firstMaterial.diffuse.contents = color;
    arrowBase.geometry.firstMaterial.diffuse.contents = color;
}

void GrabbableArrow::setWide(bool wide) {
    widthScale = wide ? 1.5 : 1.0;
    [SCNTransaction begin];
    SCNTransaction.animationDuration = 0.5;
    arrowHead.scale = SCNVector3Make(widthScale, arrowHead.scale.y, widthScale);
    [SCNTransaction commit];
}
