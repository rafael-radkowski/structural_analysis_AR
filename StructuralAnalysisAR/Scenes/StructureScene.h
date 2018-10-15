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

// forward-declaration
@class SceneTemplateView;

@protocol ARViewController
- (void) changeTrackingMode:(CGRect)anchorRect;
- (void)freezePressed:(id)sender freezeBtn:(UIButton*)freezeBtn curtain:(UIView*)curtain;
- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)screenshotBtnPressed:(id)sender infoBox:(UIView*)infoBox;
@end

@protocol StructureScene

// Holds the loaded xib defining the UI of the scene
@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;

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

- (void)touchesBegan:(CGPoint)p farHitIs:(GLKVector3)farClipHit;
- (void)touchesMoved:(CGPoint)p farHitIs:(GLKVector3)farClipHit;
- (void)touchesEnded;
- (void)touchesCancelled;

// Instantiate various ARManager types
- (ARManager*)makeStaticTracker;
- (ARManager*)makeIndoorTracker;
- (ARManager*)makeOutdoorTracker;
@end
#endif /* StructureScene_hpp */
