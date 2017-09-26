//
//  OverlayLabel.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/26/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef OverlayLabel_hpp
#define OverlayLabel_hpp

#include <stdio.h>
#import <SpriteKit/SpriteKit.h>
#import <Scenekit/Scenekit.h>
#import <GLKit/GLKit.h>

class OverlayLabel {
public:
    OverlayLabel();
    void setText(NSString* text);
    void setScenes(SKScene* scene, SCNView* view3d);
    void setHidden(bool hidden);
    
    void setObject(SCNNode* attachedTo);
    void markPosDirty();
    void doUpdate();
    
private:
    void placeLabel();
    int paddingX = 12;
    
    SKScene* scene2d;
    SCNView* objectView;
    SKLabelNode* label;
    SKSpriteNode* backgroundBox;
    bool hidden = false;
    
    NSString* textToDisplay;
    bool textChanged = false;
    SCNNode* attachedNode;
    bool posChanged = false;
};

#endif /* OverlayLabel_hpp */
