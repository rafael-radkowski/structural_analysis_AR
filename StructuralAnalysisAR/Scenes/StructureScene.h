//
//  StructureScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/5/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef StructureScene_hpp
#define StructureScene_hpp

#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMatrix4.h>
#import <GLKit/GLKit.h>

#include <stdio.h>
#include "ARManager.h"

@protocol ARViewController
- (void) changeTrackingMode:(CGRect)anchorRect;
- (void)freezePressed:(id)sender freezeBtn:(UIButton*)freezeBtn curtain:(UIView*)curtain;
- (IBAction)homeBtnPressed:(id)sender;
@end

@protocol StructureScene
// Initializes the scene 
- (id)initWithController:(id<ARViewController>)controller;

// Creates all the scene objects and returns a root node
- (SCNNode*) createScene:(SCNView*)scnView skScene:(SKScene*)skScene withCamera:(SCNNode*)camera;

// Configures scene-specific UI stuff
- (void) setupUIWithScene:(SCNView*)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided;

// Same as the update for SpriteKit delegate
- (void) skUpdate;

// Same as the renderer:updateAtTime() call for SceneKit
- (void) scnRendererUpdateAt:(NSTimeInterval)time;

// Sets the "pause camera"/"resume camera" button
- (void)setCameraLabelPaused:(bool)isPaused;

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

// Instantiate various ARManager types
- (ARManager*)makeStaticTracker;
- (ARManager*)makeIndoorTracker;
- (ARManager*)makeOutdoorTracker;
@end
#endif /* StructureScene_hpp */
