//
//  OverlayLabel.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/26/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "OverlayLabel.h"

OverlayLabel::OverlayLabel() {
//    label = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"%f", lastArrowValue]];
    label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
//    label.fontName = @"Cochin";
    label.fontColor = [UIColor blackColor];
    label.fontSize = 26;
    backgroundBox = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:1.0 alpha:0.5] size:CGSizeMake(1,1)];
    backgroundBox.zPosition = -1;
    [label addChild:backgroundBox];
    label.text = [NSString stringWithFormat:@"%.1f k/ft", 123.3f];
}

void OverlayLabel::setScenes(SKScene *scene, SCNView *view3d) {
    scene2d = scene;
    objectView = view3d;
    if (!hidden) {
        // In case setTextHidden() is called before setScenes()
        [scene2d addChild:label];
    }
}

void OverlayLabel::setObject(SCNNode* attachedTo) {
    attachedNode = attachedTo;
    posChanged = true;
}

void OverlayLabel::markPosDirty() {
    posChanged = true;
}

void OverlayLabel::setHidden(bool new_hide) {
    hidden = new_hide;
    if (hidden) {
        // Node is part of the scene
        if (label.parent != nil) {
            [label removeFromParent];
        }
    }
    else {
        if (label.parent == nil) {
            [scene2d addChild:label];
        }
    }
    // TODO: Run placeLabel()?
}

void OverlayLabel::setText(NSString* text) {
    textToDisplay = text;
    textChanged = true;
}

void OverlayLabel::setCenter(float x, float y) {
    centerXNorm = x;
    centerYNorm = y;
}

void OverlayLabel::doUpdate() {
    if (posChanged) {
        placeLabel();
        posChanged = false;
    }
    if (textChanged) {
        label.text = textToDisplay;
        float width = label.frame.size.width;
        float height = label.frame.size.height;
        backgroundBox.xScale = width;
        backgroundBox.yScale = height;
        backgroundBox.position = CGPointMake(width / 2, height / 2);
        textChanged = false;
    }
}

void OverlayLabel::placeLabel() {
    if (objectView) {
        SCNVector3 worldPos = [attachedNode convertPosition:SCNVector3Make(0, 0, 0) toNode:nil];
        SCNVector3 screenCoords = [objectView projectPoint:worldPos];
        // Spritekit uses bottom-left as (0,0), while screen coordinates use top-right
        int reversedY = objectView.frame.size.height - screenCoords.y;
        float width = label.frame.size.width;
        float height = label.frame.size.height;
        label.position = CGPointMake(screenCoords.x - width*centerXNorm, reversedY - height*centerYNorm);
    }
}
