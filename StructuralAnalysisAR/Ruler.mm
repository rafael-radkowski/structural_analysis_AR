//
//  Ruler.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 2/23/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#include "Ruler.h"

const static int rendering_order = 200;

Ruler::Ruler() {
    rootNode = [SCNNode node];
    
    textFont = [[UIFont preferredFontForTextStyle:UIFontTextStyleCallout] fontWithSize:7];

    textMat = [SCNMaterial material];
    textMat.lightingModelName = SCNLightingModelConstant;
    textMat.diffuse.contents = [UIColor colorWithWhite:0 alpha:1];

    bgMat = [SCNMaterial material];
    bgMat.lightingModelName = SCNLightingModelConstant;
    bgMat.diffuse.contents = [UIColor colorWithWhite:1 alpha:0.7];

    longPlane = [SCNPlane planeWithWidth:(rulerEnd - rulerStart) height:lineThickness];
    longPlane.firstMaterial = textMat;
    longNode = [SCNNode nodeWithGeometry:longPlane];
    [rootNode addChildNode:longNode];
    
    formatString = @"%.0f";
    
//    SCNVector3 vert_pos[3] = {
//        SCNVector3Make(0, 0, 0),
//        SCNVector3Make(15, 5, 0),
//        SCNVector3Make(20, 15, 0)};
//    SCNGeometrySource* vertSrc = [SCNGeometrySource geometrySourceWithVertices:vert_pos count:3];
//    int vert_idx[4] = {0, 1, 1, 2};
//    NSData* vert_idx_data = [NSData dataWithBytes:vert_idx length:sizeof(vert_idx)];
//    SCNGeometryElement* geomElem = [SCNGeometryElement geometryElementWithData:vert_idx_data primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:2 bytesPerIndex:sizeof(int)];
//
//    SCNGeometry* lineGeom = [SCNGeometry geometryWithSources:@[vertSrc] elements:@[geomElem]];
//    SCNMaterial* lineMat = [SCNMaterial material];
//    lineMat.lightingModelName = SCNLightingModelConstant;
//    lineMat.diffuse.contents = [UIColor colorWithWhite:0 alpha:1];
//    lineGeom.firstMaterial = lineMat;
//    SCNNode* lineNode = [SCNNode nodeWithGeometry:lineGeom];
//    [rootNode addChildNode:lineNode];
    
    setEnds(rulerStart, rulerEnd);
}

void Ruler::addAsChild(SCNNode* node) {
    [node addChildNode:rootNode];
}

void Ruler::doUpdate() {
    
}

void Ruler::setScenes(SKScene* scene2d, SCNView* view3d) {
    
}

void Ruler::setPosition(GLKVector3 pos) {
    rootNode.position = SCNVector3FromGLKVector3(pos);
}

void Ruler::setOrientation(GLKQuaternion ori) {
    rootNode.orientation = SCNVector4Make(ori.x, ori.y, ori.z, ori.w);
}

void Ruler::positionMark(SCNNode* mark, int idx) {
    float x_pos = idx * markSpacing;
    mark.position = SCNVector3Make(x_pos, rulerWidth / 2, 0);
    
    // Note that only textNode has a rotation applied
    
    SCNNode* textNode = [mark childNodeWithName:@"text" recursively:NO];
    SCNText* text = (SCNText*)(textNode.geometry);
    text.string = [NSString stringWithFormat:formatString, x_pos];
    
    SCNNode* bgNode = [mark childNodeWithName:@"bg" recursively:NO];
    SCNPlane* bgPlane = (SCNPlane*)(bgNode.geometry);
    // Text local bounding box (i.e. x is direction of writing, y is text height)
    SCNVector3 min_bbox, max_bbox;
    [text getBoundingBoxMin:&min_bbox max:&max_bbox];
    float text_width = max_bbox.x - min_bbox.x;
    float text_height = max_bbox.y - min_bbox.y;
    bgPlane.width = text_height;
    bgPlane.height = text_width;
    
    textNode.position = SCNVector3Make(min_bbox.y, -rulerWidth/2 - min_bbox.x, 0);
    bgNode.position = SCNVector3Make(-text_height/2, -(rulerWidth - text_width) / 2, -0.1);
    
    // Add some padding
    float padding = textFont.pointSize * .1;
    textNode.position = SCNVector3Make(textNode.position.x - padding, textNode.position.y + padding, textNode.position.z);
    bgNode.position = SCNVector3Make(bgNode.position.x - padding, bgNode.position.y + padding, bgNode.position.z);
}

SCNNode* Ruler::makeMark() {
    SCNPlane* plane = [SCNPlane planeWithWidth:lineThickness height:rulerWidth];
    plane.firstMaterial = textMat;
    SCNNode* tickNode = [SCNNode nodeWithGeometry:plane];
    tickNode.renderingOrder = rendering_order;
    
    SCNText* text = [SCNText textWithString:@"-" extrusionDepth:0];
    text.font = textFont;
    text.flatness = 0.4;
    SCNNode* textNode = [SCNNode nodeWithGeometry:text];
    textNode.rotation = SCNVector4Make(0, 0, 1, M_PI/2);
    textNode.name = @"text";
    text.firstMaterial = textMat;
    
    SCNNode* bgNode = [SCNNode nodeWithGeometry:[SCNPlane planeWithWidth:1 height:1]];
    bgNode.name = @"bg";
    bgNode.geometry.firstMaterial = bgMat;
//    bgNode.rotation = SCNVector4Make(0, 0, 1, M_PI/2);

    [tickNode addChildNode:bgNode];
    [tickNode addChildNode:textNode];
    return tickNode;
}

void Ruler::setEnds(float start, float end) {
    rulerStart = start;
    rulerEnd = end;
    int n_marks = (end - start) / markSpacing + 1;
    while (marks.size() < n_marks) {
        SCNNode* newMark = makeMark();
        positionMark(newMark, static_cast<int>(marks.size()));
        [rootNode addChildNode:newMark];
        marks.push_back(newMark);
    }
    
    if (marks.size() > n_marks) {
        // need to remove some
        for (ssize_t i = marks.size() - 1; i >= n_marks; --i) {
            SCNNode* mark = marks[i];
            [mark removeFromParentNode];
            marks.pop_back();
        }
    }
    
    longPlane.width = end - start;
    longNode.position = SCNVector3Make((end - start) / 2., 0, -0.1);
}

void Ruler::setMarkSpacing(float spacing) {
    markSpacing = spacing;
    setEnds(rulerStart, rulerEnd);
    // Spacing changed, so need to replace all marks
    for (int i = 0; i < marks.size(); ++i) {
        positionMark(marks[i], i);
    }
}

void Ruler::setWidth(float width) {
    rulerWidth = width;
}

void Ruler::setLineThickness(float thickness) {
    lineThickness = thickness;
}

void Ruler::setHidden(bool hidden) {
    rootNode.hidden = hidden;
}
