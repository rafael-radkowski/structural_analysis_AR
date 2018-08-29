//
//  GameViewController.m
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

// Must #include openCV stuff before other things
#import "GameViewController.h"
#import "ARView.h"
#import "SkywalkScene.h"

#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>
#import <GLKit/GLKQuaternion.h>
#import <GLKit/GLKMatrix4.h>
#import <GLKit/GLKit.h>
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

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
           mat.m[0], mat.m[4], mat.m[8], mat.m[12], mat.m[1], mat.m[5], mat.m[9], mat.m[13], mat.m[2], mat.m[6], mat.m[10], mat.m[14], mat.m[3], mat.m[7], mat.m[11], mat.m[15]);
}

// For printing SCNMatrix4
//printf("\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
//       mat.m11, mat.m21, mat.m31, mat.m41, mat.m12, mat.m22, mat.m32, mat.m42, mat.m13, mat.m23, mat.m33, mat.m43, mat.m14, mat.m24, mat.m34, mat.m44);

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scene = [SCNScene scene];

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
 
//    structureScene = [[SkywalkScene alloc] initWithController:self];
    structureScene = [[(Class)self.sceneClass alloc] initWithController:self];
    
    sceneNode = [structureScene createScene:scnView skScene:scene2d withCamera:cameraNode];
    [scene.rootNode addChildNode:sceneNode];
    
    [structureScene setupUIWithScene:scnView screenBounds:screenRect isGuided:self.guided];
    
    // AR stuff
    extendedTrackingEnabled = YES;
    {
        std::lock_guard<std::mutex> lock(arManagerLock);
        //    arManager = new VuforiaARManager((ARView*)self.view, scene, Vuforia::METAL, self.interfaceOrientation);
        //    arManager = new cvARManager(self.view, scene);
        //    tracking_mode = TrackingMode::opencv;
        //        arManager = new StaticARManager(self.view, scene);
        arManager = [structureScene makeStaticTracker];
        int failed = arManager->startCamera();
        tracking_mode = TrackingMode::untracked;
        [structureScene setCameraLabelPaused:!failed isEnabled:failed];
    }
}

//- (void)viewDidAppear:(BOOL)animated {
//    NSError* error;
//    [self.vapp resumeAR:&error];
//    if (error) {
//        printf("Error on resumeAR\n");
//    }
//}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    NSError* error;
//    [self.vapp stopAR:&error];
    std::lock_guard<std::mutex> lock(arManagerLock);
    delete arManager;
    arManager = nullptr;
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
    if (!arManager) {
        // This function might get called after viewWillDisappear was called, so arManager could be deleted
        return;
    }
    
    // Hide scene if untracked
    sceneNode.hidden = !arManager->isTracked();
    scene2d.hidden = !arManager->isTracked();
    
    if (!camPaused) {
        arManager->drawBackground();
        GLKMatrix4 camera_matrix = arManager->getCameraMatrix();
//        [self printMatrix:camera_matrix];
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(camera_matrix);
        cameraNode.camera.projectionTransform = SCNMatrix4FromGLKMatrix4(arManager->getProjectionMatrix());
    }
    // TODO: call scene
    [structureScene scnRendererUpdateAt:time];
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
            arManager->doFrame(3, [self, freezeBtn, curtain](ARManager::CB_STATE update_type) {
                if (update_type == ARManager::DONE_CAPTURING) {
                    // Set the calculated camera matrix
                    GLKMatrix4 camera_matrix = arManager->getCameraMatrix();
                    cameraNode.transform = SCNMatrix4FromGLKMatrix4(camera_matrix);

                    // this callback function gets called from a different thread, so we must post UI chanages to the main thread
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [freezeBtn setEnabled:YES];
                        curtain.hidden = YES;
                        [structureScene setCameraLabelPaused:YES isEnabled:YES];
                    }];
                    arManager->stopCamera();
                }
            });
        }
    }
    else { // camPaused == true
        int failed = arManager->startCamera();
        camPaused = failed;
        [structureScene setCameraLabelPaused:failed isEnabled:!failed];
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
//        arManager = new VuforiaARManager((ARView*)self.view, scene, Vuforia::METAL, self.interfaceOrientation);
        arManager = [structureScene makeIndoorTracker];
    }
    // Outdoor
    else if (new_mode == TrackingMode::opencv) {
        if (tracking_mode == TrackingMode::vuforia) {
            delete arManager;
        }
//        arManager = new cvARManager(self.view, scene);
        arManager = [structureScene makeOutdoorTracker];
    }
    else if (new_mode == TrackingMode::untracked) {
        delete arManager;
//        arManager = new StaticARManager(self.view, scene);
        arManager = [structureScene makeStaticTracker];
    }
    tracking_mode = new_mode;
    int failed = arManager->startCamera();
    if (failed) {
        printf("not handling failure of ARManager camera start\n");
    }
    else {
        camPaused = NO;
        bool is_tracking = new_mode != TrackingMode::untracked;
        [structureScene setCameraLabelPaused:!is_tracking isEnabled:is_tracking];
    }
}

- (void) changeTrackingMode:(CGRect)anchorRect {
    UIAlertController *customActionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    customActionSheet.popoverPresentationController.sourceView = self.view;
    customActionSheet.popoverPresentationController.sourceRect = anchorRect;
    
    UIAlertAction *untracked_btn = [UIAlertAction actionWithTitle:@"Untracked" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setTrackingMode:TrackingMode::untracked];
    }];
    [untracked_btn setValue:[UIColor blackColor] forKey:@"titleTextColor"];
    [untracked_btn setValue:[UIColor blackColor] forKey:@"imageTintColor"];

    UIAlertAction *indoor_btn = [UIAlertAction actionWithTitle:@"Indoor" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setTrackingMode:TrackingMode::vuforia];
    }];
    [indoor_btn setValue:[UIColor blackColor] forKey:@"titleTextColor"];
    
    UIAlertAction *outdoor_btn = [UIAlertAction actionWithTitle:@"Outdoor" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setTrackingMode:TrackingMode::opencv];
    }];
    [outdoor_btn setValue:[UIColor blackColor] forKey:@"titleTextColor"];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        //cancel
    }];
    [cancelButton setValue:[UIColor blackColor] forKey:@"titleTextColor"];
    
    switch (tracking_mode) {
        case TrackingMode::untracked:
            [untracked_btn setValue:@true forKey:@"checked"];
            break;
        case TrackingMode::vuforia:
            [indoor_btn setValue:@true forKey:@"checked"];
            break;
        case TrackingMode::opencv:
            [outdoor_btn setValue:@true forKey:@"checked"];
            break;
    }
    
    [customActionSheet addAction:untracked_btn];
    [customActionSheet addAction:indoor_btn];
    [customActionSheet addAction:outdoor_btn];
    [customActionSheet addAction:cancelButton];
    
    [self presentViewController:customActionSheet animated:YES completion:nil];
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

- (IBAction)screenshotBtnPressed:(id)sender infoBox:(UIView*)infoBox {
    // I'm so sorry for this callback hell
    
    // Request permission to access Photos
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                UIView* screen = self.view;
    
                UIGraphicsBeginImageContextWithOptions(screen.bounds.size, screen.opaque, 0.0);
                [screen drawViewHierarchyInRect:screen.bounds afterScreenUpdates:YES];
                UIImage* screengrab = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
    
                UIImageWriteToSavedPhotosAlbum(screengrab, nil, nil, nil);
    
                // Animate the info box fading in and out
                infoBox.hidden = NO;
                [UIView animateWithDuration:0.75
                                      delay: 0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     infoBox.alpha = 1.0;
                                 }
                                 completion:^(BOOL finished) {
                                     [UIView animateWithDuration:1.25
                                                           delay: 0.75
                                                         options:UIViewAnimationOptionCurveEaseOut
                                                      animations:^{
                                                          infoBox.alpha = 0.0;
                                                      }
                                                      completion:^(BOOL finished) {
                                                          infoBox.hidden = YES;
                                                      }
                                      ];
                                 }
                 ];
                
            }]; // end mainQueue handler
        }
        else { // request authorization denied
            UIAlertController* alert = [UIAlertController
                                        alertControllerWithTitle:@"Failed to save" message:@"Cannot save screenshot without Photos access" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* gotoSettingsBtn = [UIAlertAction
                                              actionWithTitle:@"Go to Settings"
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction* action) {
                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                                                     options:@{}
                                                                           completionHandler:nil];
                                              }];
            UIAlertAction* okayBtn = [UIAlertAction
                                      actionWithTitle:@"Okay"
                                      style:UIAlertActionStyleCancel
                                      handler:nil];
            [alert addAction:gotoSettingsBtn];
            [alert addAction:okayBtn];
            [self presentViewController:alert animated:YES completion:nil];
        }

    }]; // close requestAuthorization handler
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
