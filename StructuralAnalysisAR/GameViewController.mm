//
//  GameViewController.m
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

// Must #include openCV stuff before other things
#include "cvARManager.h"
#import "GameViewController.h"
#import "ARView.h"
#include "VuforiaARManager.h"
#include "StaticARManager.h"
#import "SkywalkScene.h"

#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>
#import <GLKit/GLKQuaternion.h>
#import <GLKit/GLKMatrix4.h>
#import <GLKit/GLKit.h>
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>

#import "SampleApplicationUtils.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/Image.h>
#import <Vuforia/Renderer.h>

#include <cmath>
#include <algorithm>

@implementation GameViewController

//- (CGRect)getCurrentARViewFrame
//{
//    CGRect screenBounds = [[UIScreen mainScreen] bounds];
//    CGRect viewFrame = screenBounds;
//
//    // If this device has a retina display, scale the view bounds
//    // for the AR (OpenGL) view
//    if (YES == self.vapp.isRetinaDisplay) {
//        viewFrame.size.width *= [UIScreen mainScreen].scale;
//        viewFrame.size.height *= [UIScreen mainScreen].scale;
//    }
//    return viewFrame;
//}

- (void)printMatrix:(GLKMatrix4)mat {
    printf("%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
           mat.m[0], mat.m[1], mat.m[2], mat.m[3], mat.m[4], mat.m[5], mat.m[6], mat.m[7], mat.m[8], mat.m[9], mat.m[10], mat.m[11], mat.m[12], mat.m[13], mat.m[14], mat.m[15]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scene = [SCNScene scene];
     
    // Vuforia stuff
    extendedTrackingEnabled = YES;
    {
        std::lock_guard<std::mutex> lock(arManagerLock);
    //    arManager = new VuforiaARManager((ARView*)self.view, scene, Vuforia::METAL, self.interfaceOrientation);
    //    arManager = new cvARManager(self.view, scene);
    //    tracking_mode = TrackingMode::opencv;
        arManager = new StaticARManager(self.view, scene);
        tracking_mode = TrackingMode::untracked;
        arManager->startCamera();
    }
    
    // Make a camera
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // Get the view and set our scene to it
    SCNView *scnView = (SCNView *)self.view;
    scnView.delegate = self;
    
    scnView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    scnView.multipleTouchEnabled = YES;
    scnView.scene = scene;
    // Setting SCNView.playing to true makes it render on every scene, even if nothing in the scenegraph was moved
    // We want this behavior to update the video background
    scnView.playing = YES;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // Create SpriteKit scene
    scene2d = [SKScene sceneWithSize:screenRect.size];
    scene2d.delegate = self;
    scnView.overlaySKScene = scene2d;
    scene2d.userInteractionEnabled = NO;
 
    structureScene = [[SkywalkScene alloc] initWithController:self];
    
    sceneNode = [structureScene createScene:scnView skScene:scene2d withCamera:cameraNode];
    [scene.rootNode addChildNode:sceneNode];
    
    [structureScene setupUIWithScene:scnView screenBounds:screenRect isGuided:self.guided];
}

//- (void)viewDidAppear:(BOOL)animated {
//    NSError* error;
//    [self.vapp resumeAR:&error];
//    if (error) {
//        printf("Error on resumeAR\n");
//    }
//}

- (void)viewDidDisappear:(BOOL)animated {
//    NSError* error;
//    [self.vapp stopAR:&error];
    std::lock_guard<std::mutex> lock(arManagerLock);
    delete arManager;
}

//- (void)viewDidDisappear:(BOOL)animated {
//    [super viewDidDisappear:animated];
//    NSError * error = nil;
//    [self.vapp stopAR:&error];
//    if (error != nil) {
//        printf("Error stopping AR\n");
//    }
//}

- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {
    [structureScene skUpdate];
}

// called every frame by the renderer
- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    std::lock_guard<std::mutex> lock(arManagerLock);
    
    // Hide scene if untracked
    sceneNode.hidden = !arManager->isTracked();
    
    // For the SpriteKit scene, we have to hide it by changing overlaySKScene, rather than setting the scene2d.hidden attribute
    //      When the SKScene is hidden, the label widths become infinity, which messes up their placement in OverlayLabel
    if (arManager->isTracked()) {
        ((SCNView*) self.view).overlaySKScene = scene2d;
    }
    else {
        ((SCNView*) self.view).overlaySKScene = nil;
    }
    
    if (!camPaused) {
        arManager->drawBackground();
        GLKMatrix4 camera_matrix = arManager->getCameraMatrix();
//        [self printMatrix:camera_matrix];
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(camera_matrix);
        cameraNode.camera.projectionTransform = SCNMatrix4FromGLKMatrix4(arManager->getProjectionMatrix());
    }
    // TODO: call scene
    [structureScene scnRendererUpdate];
}


- (void)freezePressed:(id)sender freezeBtn:(UIButton*)freezeBtn curtain:(UIView*)curtain {
    std::lock_guard<std::mutex> lock(arManagerLock);
    if (!camPaused) {
        if (tracking_mode == TrackingMode::vuforia) {
            camPaused = true;
            arManager->stopCamera();
            [freezeBtn setTitle:@"Resume Camera" forState:UIControlStateNormal];
        }
        else if (tracking_mode == TrackingMode::opencv) {
            //            ((cvARManager*)arManager)->saveImg();
            camPaused = true;
            [freezeBtn setEnabled:NO];
            curtain.hidden = NO;
            arManager->doFrame(5, [self, freezeBtn, curtain](ARManager::CB_STATE update_type) {
                if (update_type == ARManager::DONE_CAPTURING) {
                    // Set the calculated camera matrix
                    GLKMatrix4 camera_matrix = arManager->getCameraMatrix();
                    cameraNode.transform = SCNMatrix4FromGLKMatrix4(camera_matrix);
                    
                    // this callback function gets called from a different thread, so we must post UI chanages to the main thread
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [freezeBtn setEnabled:YES];
                        curtain.hidden = YES;
                        [structureScene setCameraLabelPaused:YES];
                    }];
                    arManager->stopCamera();
                }
            });
        }
    }
    else { // camPaused == true
        camPaused = false;
        [structureScene setCameraLabelPaused:NO];
        arManager->startCamera();
    }
    
    //    [self setAREnabled:!arEnabled];
    //    ARView* scnView = (ARView*) self.view;
    // Toggle whether we update background video texture
    //    scnView.renderVideo = !scnView.renderVideo;
}


- (void) setTrackingMode:(enum TrackingMode)new_mode {
    // obtain arManagerLock so we can make calls and re-create arManager if needed
    std::lock_guard<std::mutex> lock(arManagerLock);
    arManager->stopCamera();
    // Indoor
    if (new_mode == TrackingMode::vuforia) {
        if (tracking_mode == TrackingMode::opencv) {
            delete arManager;
        }
        arManager = new VuforiaARManager((ARView*)self.view, scene, Vuforia::METAL, self.interfaceOrientation);
    }
    // Outdoor
    else if (new_mode == TrackingMode::opencv) {
        if (tracking_mode == TrackingMode::vuforia) {
            delete arManager;
        }
        arManager = new cvARManager(self.view, scene);
    }
    else if (new_mode == TrackingMode::untracked) {
        delete arManager;
        arManager = new StaticARManager(self.view, scene);
    }
    tracking_mode = new_mode;
    camPaused = false;
    arManager->startCamera();
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (IBAction)homeBtnPressed:(id)sender {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    MainPageViewController *myNewVC = (MainPageViewController *)[storyboard instantiateViewControllerWithIdentifier:@"mainPage"];
//    [self presentViewController:myNewVC animated:YES completion:nil];
    [self performSegueWithIdentifier:@"backToHomepageSegue" sender:self];
}


// Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [structureScene touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    [structureScene touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    [structureScene touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    [structureScene touchesCancelled:touches withEvent:event];
}


@end
