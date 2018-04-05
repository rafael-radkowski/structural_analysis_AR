//
//  CircleIndicator.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/16/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#include "CircleArrow.h"

CircleArrow::CircleArrow() {
    root = [SCNNode node];
    formatString = @"%.1f k-ft";
    
    NSString* arrowHeadPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow_tip"] ofType:@"obj"];
    NSURL* arrowHeadUrl = [NSURL fileURLWithPath:arrowHeadPath];
    MDLAsset* arrowHeadAsset = [[MDLAsset alloc] initWithURL:arrowHeadUrl];
    arrowHead = [SCNNode nodeWithMDLObject:[arrowHeadAsset objectAtIndex:0]];
    arrowHeadEmpty = [SCNNode node];
    [arrowHeadEmpty addChildNode:arrowHead];
    [root addChildNode:arrowHeadEmpty];
    
    bodyShape = [SCNShape shapeWithPath:makePath(0) extrusionDepth:thickness];
    bodyShape.chamferRadius = thickness / 2;
    arrowBody = [SCNNode nodeWithGeometry:bodyShape];
    [root addChildNode:arrowBody];
    
    SCNMaterial* arrowMat = [SCNMaterial material];
    arrowMat.diffuse.contents = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0];
    arrowHead.geometry.firstMaterial = arrowMat;
    arrowBody.geometry.firstMaterial = arrowMat;
    
    labelEmpty = [SCNNode node];
    [root addChildNode:labelEmpty];
    valueLabel.setObject(labelEmpty);
    valueLabel.setCenter(0.5, 1);
    
    setThickness(thickness);
}

void CircleArrow::setScenes(SKScene *scene2d, SCNView *view3d) {
    valueLabel.setScenes(scene2d, view3d);
}

void CircleArrow::doUpdate() {
    valueLabel.doUpdate();
}

void CircleArrow::setHidden(bool hide) {
    root.hidden = hide;
    valueLabel.setHidden(hide);
}

void CircleArrow::setColor(float r, float g, float b) {
    bodyShape.firstMaterial.diffuse.contents = [UIColor colorWithRed:r green:g blue:b alpha:1];
    arrowHead.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:r green:g blue:b alpha:1];
}

void CircleArrow::addAsChild(SCNNode* node) {
    [node addChildNode:root];
}

void CircleArrow::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
    valueLabel.markPosDirty();
}

void CircleArrow::setFormatString(NSString* str) {
    formatString = str;
}

void CircleArrow::setRotationAxisAngle(GLKVector4 axisAngle) {
    root.rotation = SCNVector4FromGLKVector4(axisAngle);
}

void CircleArrow::setThickness(float new_thickness) {
    thickness = new_thickness;
    float newTipSize = 2.4 * thickness;
    float tipScale = newTipSize / defaultTipSize;
    arrowHead.scale = SCNVector3Make(tipScale, tipScale, tipScale);
    
    arrowHead.position = SCNVector3Make(0, -newTipSize, 0);
    bodyShape.extrusionDepth = thickness;
    bodyShape.chamferRadius = thickness / 2;
}

void CircleArrow::setRadius(float new_radius) {
    radius = new_radius;
}

void CircleArrow::setInputRange(float min_value, float max_value) {
    minValue = min_value;
    maxValue = max_value;
}

void CircleArrow::setIntensity(float intensity) {
    float normalized_val = (intensity - minValue) / (maxValue - minValue);
    float angle = normalized_val * M_PI;
    bodyShape.path = makePath(angle);
    
    // Move the arrow tip around
    float tip_x = (radius) * std::cos(angle);
    float tip_y = (radius) * std::sin(angle);
    arrowHeadEmpty.position = SCNVector3Make(tip_x, tip_y, 0);
    // Keep it pointing parallel to the base
    if (normalized_val >= 0) {
        arrowHeadEmpty.rotation = SCNVector4Make(0, 0, 1, -M_PI + angle);
    }
    else {
        arrowHeadEmpty.rotation = SCNVector4Make(0, 0, 1, angle);
    }

    labelEmpty.position = SCNVector3Make(tip_x, tip_y, 0);
    valueLabel.setText([NSString stringWithFormat:formatString, std::abs(intensity)]);
    valueLabel.markPosDirty();
}


UIBezierPath* CircleArrow::makePath(float angle) {
    UIBezierPath* path = [UIBezierPath bezierPath];
    bool positive = angle >= 0;
    [path moveToPoint:CGPointMake(radius - thickness/2, 0)];
    [path addArcWithCenter:CGPointMake(0, 0) radius:radius - (thickness / 2) startAngle:0 endAngle:angle clockwise:positive];
    //    [path addLineToPoint:CGPointMake(-(radius - thickness), 0)];
    [path addArcWithCenter:CGPointMake(0, 0) radius:radius + (thickness / 2) startAngle:angle endAngle:0 clockwise:!positive];
    [path closePath];
    path.flatness = 0.1;
    return path;
}
