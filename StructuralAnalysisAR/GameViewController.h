//
//  GameViewController.h
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "MainPageViewController.h"
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>
#import <Metal/Metal.h>

#import "SampleApplicationSession.h"
#include "ARManager.h"
#import <Vuforia/DataSet.h>

#import "StructureScene.h"

#include <vector>
#include <string>
#include <mutex>

@interface GameViewController : UIViewController <ARViewController, SKSceneDelegate, SCNSceneRendererDelegate> {
    // Private vars
    SCNRenderer* renderer;
    SCNNode *cameraNode;
    SCNScene *scene;
    SKScene *scene2d;
    SCNNode* sceneNode;
    
    id<StructureScene> structureScene;
    
    // Should be obtained whenever calling arManager and when deleting/creating it
    std::mutex arManagerLock;
    ARManager* arManager;

    enum TrackingMode tracking_mode;
    id<MTLTexture> staticBgTex;
    UIImage* scaled_img;

    bool camPaused;
    int framesLeftToProcess;
    SCNMatrix4 bgImgScale;
    // Vuforia stuff
    Vuforia::DataSet*  dataSetStonesAndChips;
    Vuforia::DataSet*  dataSetCurrent;
    BOOL extendedTrackingEnabled;
    BOOL continuousAutofocusEnabled;
    id<MTLTexture> videoTexture;
}
// Set from MainPageViewController to determine if guided or not
@property (nonatomic) bool guided;
@property (nonatomic) Class<StructureScene> sceneClass;

// SKSceneDelegate implementations
- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene;

- (void) setTrackingMode:(enum TrackingMode)new_mode;
- (IBAction)freezePressed:(id)sender;

// override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

@end
