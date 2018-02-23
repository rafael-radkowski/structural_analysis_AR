//
//  OverlayLabel.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/26/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef OverlayLabel_hpp
#define OverlayLabel_hpp

#include <mutex>
#include <stdio.h>
#import <SpriteKit/SpriteKit.h>
#import <Scenekit/Scenekit.h>
#import <GLKit/GLKit.h>

class ExclusiveNSString {
public:
    ExclusiveNSString() : str([NSString alloc]) {}
    ExclusiveNSString(NSString* other) : str(other) {}
    // move constructor
    ExclusiveNSString(ExclusiveNSString&& other);
    // copy constructor
    ExclusiveNSString(const ExclusiveNSString& other);
    // copy assignment
    ExclusiveNSString& operator=(const ExclusiveNSString& other);
    // move assignment
    ExclusiveNSString& operator=(ExclusiveNSString&& other);
    
    ExclusiveNSString& operator=(const NSString* other);
    operator NSString*() {
        std::lock_guard<std::mutex> lock(mut);
        return str;
    }
private:
    NSString* str;
    mutable std::mutex mut;
};

class OverlayLabel {
public:
    OverlayLabel();
    void setText(NSString* text);
    void setScenes(SKScene* scene, SCNView* view3d);
    void setHidden(bool hidden);
    // What part of the label to center on object. x and y are normalized to the range of [0,1]
    void setCenter(float x, float y);
    
    void setObject(SCNNode* attachedTo);
    void markPosDirty();
    void doUpdate();
    
private:
    void placeLabel();
//    int paddingX = 12;
    float centerXNorm = 0.5;
    float centerYNorm = 0.5;
    
    SKScene* scene2d;
    SCNView* objectView;
    int viewHeight;
    SKLabelNode* label;
    SKSpriteNode* backgroundBox;
    bool hidden = false;
    
//    NSString* textToDisplay;
    ExclusiveNSString textToDisplay;
    bool textChanged = false;
    SCNNode* attachedNode;
    bool posChanged = false;
};

#endif /* OverlayLabel_hpp */
