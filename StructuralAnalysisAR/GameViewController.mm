//
//  GameViewController.m
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "GameViewController.h"
#import "ARView.h"
#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>
#import <GLKit/GLKQuaternion.h>
#import <GLKit/GLKMatrix4.h>
#import <GLKit/GLKit.h>

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

#define COL1_POS -80
#define COL2_POS -25
#define COL3_POS 74
#define COL4_POS 118

// IDs of UISegmentedControl for scenario selection
#define SCENARIO_VARIABLE 4

@implementation GameViewController

- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == self.vapp.isRetinaDisplay) {
        viewFrame.size.width *= [UIScreen mainScreen].scale;
        viewFrame.size.height *= [UIScreen mainScreen].scale;
    }
    return viewFrame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scene = [SCNScene scene];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:viewFrame.size.width height:viewFrame.size.height mipmapped:NO];
    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    videoTexture = [gpu newTextureWithDescriptor:texDescription];
    scene.background.contents = videoTexture;
    ARView* arView = [[ARView alloc] initWithFrame:viewFrame appSession:self.vapp backgroundTex:videoTexture];
    [self setView:arView];
    
    
    // Make camera as scene background
//    UIImage* backgroundImage = [UIImage imageNamed:@"skywalk.jpg"];
//    scene.background.contents = backgroundImage;
    
//    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
//    AVCaptureDevice* videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    NSError* error = nil;
//    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
//    if (videoInput) {
//        [captureSession addInput:videoInput];
//        AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
//        [captureSession startRunning];
//        
//        previewLayer.frame = self.view.bounds;
//        [self.view.layer addSublayer:previewLayer];
//        
//    }
//    else {
//        printf("Error when connecting to camera: %s", [error localizedDescription]);
//        scene.background.contents = [UIImage imageNamed:@"skywalk.jpg"];
//    }
//    scnView = [[SCNView alloc] initWithFrame:self.view.bounds options:nil];
//    scnView.backgroundColor = [UIColor clearColor];
//    [self.view addSubview:scnView ];
    
//    [scene.rootNode addChildNode:arrow.root];
    
    // Make a camera
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    // move the camera
    cameraNode.position = SCNVector3Make(-69, 36, 270);
    cameraNode.eulerAngles = SCNVector3Make(-0.1, -0.30, 0.033);
//    GLKVector3 z_axis = GLKVector3Make(cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
//    GLKVector3 newPos = GLKVector3Add(SCNVector3ToGLKVector3(cameraNode.position), GLKVector3MultiplyScalar(z_axis, 90));
//    cameraNode.position = SCNVector3FromGLKVector3(newPos);
//    printf("z: %f, %f, %f\n", cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
//    cameraNode.position = SCNVector3Make(-5.5, 5, 200);
    cameraNode.camera.zFar = 500;
//    cameraNode.camera.focalLength = 0.0108268; // 3.3mm
    cameraNode.camera.xFov = 45.12 * 0.6666666; // Background image cropped roughly at 2/3 the size
    cameraNode.camera.yFov = 57.96 * 0.6666666;
    
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(100, 50, 30);
    lightNode.light.intensity = 700;
    [scene.rootNode addChildNode:lightNode];
    SCNNode *lightNode2 = [SCNNode node];
    lightNode2.light = [SCNLight light];
    lightNode2.light.type = SCNLightTypeOmni;
    lightNode2.light.intensity = 700;
    lightNode2.position = SCNVector3Make(-100, 50, 80);
    [scene.rootNode addChildNode:lightNode2];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.6;
    [scene.rootNode addChildNode:ambientLightNode];
    
    // Get the view and set our scene to it
    SCNView *scnView = (SCNView *)self.view;
    scnView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    scnView.multipleTouchEnabled = YES;
    scnView.scene = scene;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // Create SpriteKit scene
    scene2d = [SKScene sceneWithSize:screenRect.size];
    scene2d.delegate = self;
    scnView.overlaySKScene = scene2d;
    scene2d.userInteractionEnabled = NO;
    
    [[NSBundle mainBundle] loadNibNamed:@"View" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    printf("w: %f, h: %f\n", screenRect.size.width, screenRect.size.height);
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    // Hide visualization toggles switches in guided mode
    if (self.guided) {
        for (UIView* elem in [NSArray arrayWithObjects:self.liveLoadSwitch, self.deadLoadSwitch, self.rcnForceSwitch, self.liveLoadLabel, self.deadLoadLabel, self.rcnForceLabel, nil]) {
            elem.hidden = YES;
        }
    }
    
    CGColor* textColor = [UIColor colorWithRed:0.08235 green:0.49412 blue:0.9843 alpha:1.0].CGColor;
    // Setup home button style
    self.homeBtn.layer.borderWidth = 1.5;
    self.homeBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.homeBtn.layer.borderColor = textColor;
    self.homeBtn.layer.cornerRadius = 5;
    
    // Setup instruction box style
    self.instructionBox.layer.borderWidth = 1.5;
    self.instructionBox.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5);
    self.prevBtn.layer.borderWidth = self.nextBtn.layer.borderWidth = 1.5;
    self.prevBtn.layer.borderColor = self.nextBtn.layer.borderColor = textColor;
    self.prevBtn.layer.cornerRadius = self.nextBtn.layer.cornerRadius = 5;
    self.prevBtn.titleEdgeInsets = self.nextBtn.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    
    deflectLive = deflectDead = true;
    
    [self setupVisualizations];
    [self setupInstructions];
    
    // Set load visibilities to the default values
    [self setVisibilities];
    [self.loadPresetBtn sendActionsForControlEvents:UIControlEventValueChanged];
//    GLKMatrix4 projMat = SCNMatrix4ToGLKMatrix4(cameraNode.camera.projectionTransform);
    
    // Vuforia stuff
    self.vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    [self.vapp initAR:Vuforia::METAL orientation:self.interfaceOrientation];
}

- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {
    peopleLoad.doUpdate();
    deadLoad.doUpdate();
    for (GrabbableArrow& rcnArrow : reactionArrows) {
        rcnArrow.doUpdate();
    }
    beam1.doUpdate();
    beam2.doUpdate();
    beam3.doUpdate();
}

- (void)setupVisualizations {
    SCNView *scnView = (SCNView*)self.view;
    float defaultThickness = 5;
    
//    GLKQuaternion beamOri = GLKQuaternionMakeWithAngleAndAxis(0.015, 0, 0, 1);
    GLKQuaternion beamOri = GLKQuaternionMakeWithAngleAndAxis(0, 0, 0, 1);
    // Create live load bar
    peopleLoad = LoadMarker(3);
    peopleLoad.setPosition(GLKVector3Make(0, 5, 0));
    peopleLoad.setOrientation(beamOri);
    peopleLoad.setInputRange(0, 1.5);
    peopleLoad.setMinHeight(15);
    peopleLoad.setMaxHeight(40);
    peopleLoad.setThickness(defaultThickness);
    peopleLoad.addAsChild(scene.rootNode);
    
    // Create dead load bar
    deadLoad = LoadMarker(6);
    deadLoad.setInputRange(0, 1.5);
    deadLoad.setLoad(1.2); // 1.2 k/ft
//    float dead_z = self.guided ?
    deadLoad.setPosition(GLKVector3Make(0, 22, 0));
    deadLoad.setOrientation(beamOri);
    deadLoad.setEnds(COL1_POS, COL4_POS);
    deadLoad.setMinHeight(15);
    deadLoad.setMaxHeight(40);
    deadLoad.setThickness(defaultThickness);
    deadLoad.addAsChild(scene.rootNode);
    
    reactionArrows.resize(4);
    for (int i = 0; i < reactionArrows.size(); ++i) {
        reactionArrows[i].addAsChild(scene.rootNode);
        reactionArrows[i].setFormatString(@"%.1f k");
        reactionArrows[i].setThickness(defaultThickness);
        reactionArrows[i].setMinLength(15);
        reactionArrows[i].setMaxLength(40);
        reactionArrows[i].setInputRange(0, 150);
        reactionArrows[i].setRotationAxisAngle(GLKVector4Make(0, 0, 1, 3.1416));
        reactionArrows[i].setScenes(scene2d, scnView);
    }
    reactionArrows[0].setPosition(GLKVector3Make(COL1_POS, 3, 0));
    reactionArrows[1].setPosition(GLKVector3Make(COL2_POS, 3, 0));
    reactionArrows[2].setPosition(GLKVector3Make(COL3_POS, 3, 0));
    reactionArrows[3].setPosition(GLKVector3Make(COL4_POS, 3, 0));
    
    people = PeopleVis(10, cameraNode);
    people.addAsChild(scene.rootNode);
    
    int resolution = 10;
    beamVals1.resize(2); beamVals2.resize(2); beamVals3.resize(2);
    double stepSize1 = (COL2_POS - COL1_POS) / (resolution - 1);
    double stepSize2 = (COL3_POS - COL2_POS) / (resolution - 1);
    double stepSize3 = (COL4_POS - COL3_POS) / (resolution - 1);
    for (int i = 0; i < resolution; ++i) {
        beamVals1[0].push_back(COL1_POS + stepSize1 * i);
        beamVals2[0].push_back(COL2_POS + stepSize2 * i);
        beamVals3[0].push_back(COL3_POS + stepSize3 * i);
        beamVals1[1].push_back(0);
        beamVals2[1].push_back(0);
        beamVals3[1].push_back(0);
    }
    // TODO: ew. Put these in an array
    beam1 = BezierLine(beamVals1);
    beam2 = BezierLine(beamVals2);
    beam3 = BezierLine(beamVals3);
    beam1.setMagnification(4000);
    beam2.setMagnification(4000);
    beam3.setMagnification(4000);
    beam1.addAsChild(scene.rootNode);
    beam2.addAsChild(scene.rootNode);
    beam3.addAsChild(scene.rootNode);
    beam1.setOrientation(beamOri);
    beam2.setOrientation(beamOri);
    beam3.setOrientation(beamOri);
    beam1.setPosition(GLKVector3Make(0, 2, 0));
    beam2.setPosition(GLKVector3Make(0, 2, 0));
    beam3.setPosition(GLKVector3Make(0, 2, 0));
    beam1.setScenes(scene2d, scnView);
    beam2.setScenes(scene2d, scnView);
    beam3.setScenes(scene2d, scnView);
    
    peopleLoad.setScenes(scene2d, scnView);
    deadLoad.setScenes(scene2d, scnView);
}

- (void)setupInstructions {
    if (self.guided) {
        instructions.push_back("Step 1\nThat's a beam.");
        instructions.push_back("Step 2\nOh, and it's heavy.");
        instructions.push_back("Step 3\nCausing it to bend under its own weight");
        instructions.push_back("Step 4\nSometimes people walk on the skywalk");
        instructions.push_back("Step 5\nThey make it bend even more");
        instructions.push_back("Step 6\nThe supports have to hold all this up");
        curStep = 0;
        [self showInstruction:curStep];
        self.prevBtn.hidden = YES;
    }
    else {
        self.instructionBox.hidden = YES;
        self.prevBtn.hidden = YES;
        self.nextBtn.hidden = YES;
    }
}

- (void)showInstruction:(int)step {
    self.instructionBox.text = [NSString stringWithCString:instructions[step].c_str() encoding:[NSString defaultCStringEncoding]];
    bool hideLive, hideDead, hideReactions, hideDeflectionText;
    hideLive = hideDead = hideReactions = hideDeflectionText = false;
    switch (step) {
        case 0: {
            for (int i = 1; i < 5; ++i) { [self.loadPresetBtn setEnabled:NO forSegmentAtIndex:i]; }
            [self.loadPresetBtn setEnabled:YES forSegmentAtIndex:0];
            self.loadPresetBtn.selectedSegmentIndex = 0;
            [self.loadPresetBtn sendActionsForControlEvents:UIControlEventValueChanged];
            hideLive = true;
            hideDead = true;
            hideReactions = true;
            hideDeflectionText = true;
            deflectLive = deflectDead = false;
            break;
        }
        case 1: {
            peopleLoad.setLoad(0);
            hideLive = true;
            hideReactions = true;
            deflectDead = false;
            hideDeflectionText = true;
            break;
        }
        case 2: {
            for (int i = 1; i < 5; ++i) { [self.loadPresetBtn setEnabled:NO forSegmentAtIndex:i]; }
            [self.loadPresetBtn setEnabled:YES forSegmentAtIndex:0];
            deflectDead = true;
            hideLive = true;
            hideReactions = true;
            peopleLoad.setHidden(true);
            self.loadPresetBtn.selectedSegmentIndex = 0;
            [self.loadPresetBtn sendActionsForControlEvents:UIControlEventValueChanged];
            break;
        }
        case 3: {
            deflectLive = false;
            hideReactions = true;
            for (int i = 0; i < 5; ++i) { [self.loadPresetBtn setEnabled:YES forSegmentAtIndex:i]; }
            self.loadPresetBtn.selectedSegmentIndex = 1;
            [self.loadPresetBtn sendActionsForControlEvents:UIControlEventValueChanged];
            break;
        }
        case 4: {
            deflectLive = true;
            hideReactions = true;
            break;
        }
        case 5: {
            break;
        }
        default:
            break;
    }
    peopleLoad.setHidden(hideLive);
    deadLoad.setHidden(hideDead);
    for (int i = 0; i < reactionArrows.size(); ++i) {
        reactionArrows[i].setHidden(hideReactions);
    }
    beam1.setTextHidden(hideDeflectionText); beam2.setTextHidden(hideDeflectionText); beam3.setTextHidden(hideDeflectionText);
    
    [self updateBeamForces];
}

- (IBAction)prevStepPressed:(id)sender {
    if (curStep > 0) {
        curStep -= 1;
        [self showInstruction:curStep];
        if (curStep == 0) {
            self.prevBtn.hidden = YES;
        }
        self.nextBtn.hidden = NO;
    }
}

- (IBAction)nextStepPressed:(id)sender {
    if (curStep < instructions.size() - 1) {
        curStep += 1;
        [self showInstruction:curStep];
        if (curStep == instructions.size() - 1) {
            self.nextBtn.hidden = YES;
        }
        self.prevBtn.hidden = NO;
    }
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


- (IBAction)visSwitchToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
    // Only obey the switches if they are visible
    if (!self.liveLoadSwitch.hidden) {
        peopleLoad.setHidden(!self.liveLoadSwitch.on);
    }
    if (!self.deadLoadSwitch.hidden) {
        deadLoad.setHidden(!self.deadLoadSwitch.on);
    }
    if (!self.rcnForceSwitch.hidden) {
        for (int i = 0; i < reactionArrows.size(); ++i) {
            reactionArrows[i].setHidden(!self.rcnForceSwitch.on);
        }
    }
}

- (IBAction)loadPresetSet:(id)sender {
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.5];
    const float top_posL = 22;
    const float top_posR = 24;
    activeScenario = self.loadPresetBtn.selectedSegmentIndex;

    switch (self.loadPresetBtn.selectedSegmentIndex) {
        case 0: // none
            peopleLoad.setEnds(COL1_POS, COL4_POS);
            peopleLoad.setLoad(0);
            people.setPosition(GLKVector3Make(COL1_POS, top_posL - 12, 0));
            people.setLength(COL4_POS - COL1_POS);
            people.setWeight(0);
            reactionArrows[0].setIntensity(17.644);
            reactionArrows[1].setIntensity(108.071);
            reactionArrows[2].setIntensity(103.97);
            reactionArrows[3].setIntensity(7.914);
            break;
        case 1: // uniform
            peopleLoad.setEnds(COL1_POS, COL4_POS);
            peopleLoad.setLoad(0.8);
            people.setPosition(GLKVector3Make(COL1_POS, top_posL - 12, 0));
            people.setLength(COL4_POS - COL1_POS);
            people.setWeight((COL4_POS - COL1_POS) * 0.8 * 1000);
            reactionArrows[0].setIntensity(29.407);
            reactionArrows[1].setIntensity(180.118);
            reactionArrows[2].setIntensity(173.284);
            reactionArrows[3].setIntensity(13.191);
            break;
        case 2: // left
            peopleLoad.setEnds(COL1_POS, COL2_POS);
            peopleLoad.setLoad(0.8);
            people.setPosition(GLKVector3Make(COL1_POS, top_posL - 12, 0));
            people.setLength(COL2_POS - COL1_POS);
            people.setWeight((COL2_POS - COL1_POS) * 0.8 * 1000);
            reactionArrows[0].setIntensity(37.441);
            reactionArrows[1].setIntensity(113.919);
            reactionArrows[2].setIntensity(101.376);
            reactionArrows[3].setIntensity(8.863);
            break;
        case 3: // right
            peopleLoad.setEnds(COL3_POS, COL4_POS);
            peopleLoad.setLoad(0.8);
            people.setPosition(GLKVector3Make(COL3_POS, top_posR - 12, 0));
            people.setLength(COL4_POS - COL3_POS);
            people.setWeight((COL4_POS - COL3_POS) * 0.8 * 1000);
            reactionArrows[0].setIntensity(18.033);
            reactionArrows[1].setIntensity(106.792);
            reactionArrows[2].setIntensity(123.978);
            reactionArrows[3].setIntensity(23.997);
            break;
        case SCENARIO_VARIABLE: // variable
//            peopleLoad.setPosition(GLKVector3Make(COL1_POS, top_posL, 0), GLKVector3Make(COL4_POS, top_posR, 0));
            break;
        default:
            break;
    }
    people.shuffle();
    [self updateBeamForces];
    [SCNTransaction commit];
}

- (IBAction)homeBtnPressed:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainPageViewController *myNewVC = (MainPageViewController *)[storyboard instantiateViewControllerWithIdentifier:@"mainPage"];
    [self presentViewController:myNewVC animated:YES completion:nil];
}

// Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
//    NSAssert(touches.count == 1, @"number of touches != 1");
    
//    CGPoint p = [[touches anyObject] locationInView:scnView];
    // Use bounding boxes to increase the area that can be touched
//    NSDictionary* hitOptions = @{
//                                 SCNHitTestBoundingBoxOnlyKey: @YES
//                                 };
//    NSArray *hitResults = [scnView hitTest:p options:hitOptions];
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
//    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
//    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));
    
    peopleLoad.touchBegan(SCNVector3ToGLKVector3(cameraNode.position), farClipHit);
//    }
    if (peopleLoad.draggingMode() != LoadMarker::none) {
        activeScenario = SCENARIO_VARIABLE;
        self.loadPresetBtn.selectedSegmentIndex = SCENARIO_VARIABLE;
    }
    return;
}


- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    SCNView *scnView = (SCNView *)self.view;
    
//    NSAssert(touches.count == 1, @"number of touches != 1");
//    printf("%lu touches\n", touches.count);
    
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));
    
    //GLKVector3 cameraDir = GLKVector3Make(cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
    
    
    if (activeScenario == SCENARIO_VARIABLE) {
        float dragValue = peopleLoad.getDragValue(cameraPos, touchRay);
        peopleLoad.setLoad(dragValue);
        std::pair<float, float> sideDragPosition = peopleLoad.getDragPosition(cameraPos, touchRay);
//        printf("drag pos: %f, %f\n", sideDragMovement.first, sideDragMovement.second);
        // Limit left to the range of [COL1_POS, COL4_POS - 5]
        sideDragPosition.first = std::min<float>(std::max<float>(COL1_POS, sideDragPosition.first), COL4_POS - 5);
        // Limit right to the range of [COL1_POS + 5, COL4_POS]
        sideDragPosition.second = std::max<float>(std::min<float>(COL4_POS, sideDragPosition.second), COL1_POS + 5);
        // Dont let bar collapse
        if (sideDragPosition.second - sideDragPosition.first >= 5) {
            peopleLoad.setEnds(sideDragPosition.first, sideDragPosition.second);
            people.setPosition(GLKVector3Make(sideDragPosition.first, 10, 0));
            people.setLength(sideDragPosition.second - sideDragPosition.first);
            [self updateBeamForces];
        }
    }
//    self.sliderControl.value = dragValue;
}

- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    if (activeScenario == SCENARIO_VARIABLE) {
        if (peopleLoad.draggingMode() != LoadMarker::none && peopleLoad.draggingMode() != LoadMarker::horizontally) {
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            people.setWeight(1000 * peopleLoad.getLoad(0) * (peopleLoad.getEndPos().x - peopleLoad.getStartPos().x));
            people.shuffle();
            [SCNTransaction commit];
        }
        peopleLoad.touchEnded();
    }
}
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    if (activeScenario == SCENARIO_VARIABLE) {
        peopleLoad.touchCancelled();
    }
}

- (void)updateBeamForces {
    // Beam 1
    float loadStart = peopleLoad.getStartPos().x;
    float loadEnd = peopleLoad.getEndPos().x;
    float load = peopleLoad.getLoad(0);
    
    // Reaction forces
    double beam1_rcn, beam2_rcn, beam3_rcn, beam4_rcn;
    beam1_rcn = beam2_rcn = beam3_rcn = beam4_rcn = 0;
    
    // Calculate
    [self calculateDeflection:beamVals1[1] forValues:beamVals1[0] rcnL:beam1_rcn rcnR:beam2_rcn beamStarts:COL1_POS beamEnds:COL2_POS loadStarts:loadStart loadEnds:loadEnd loadMagnitude:load];
    [self calculateDeflection:beamVals2[1] forValues:beamVals2[0] rcnL:beam2_rcn rcnR:beam3_rcn beamStarts:COL2_POS beamEnds:COL3_POS loadStarts:loadStart loadEnds:loadEnd loadMagnitude:load];
    [self calculateDeflection:beamVals3[1] forValues:beamVals3[0] rcnL:beam3_rcn rcnR:beam4_rcn beamStarts:COL3_POS beamEnds:COL4_POS loadStarts:loadStart loadEnds:loadEnd loadMagnitude:load];
    
    beam1.updatePath(beamVals1);
    beam2.updatePath(beamVals2);
    beam3.updatePath(beamVals3);
    reactionArrows[0].setIntensity(beam1_rcn);
    reactionArrows[1].setIntensity(beam2_rcn);
    reactionArrows[2].setIntensity(beam3_rcn);
    reactionArrows[3].setIntensity(beam4_rcn);
}

- (void)calculateDeflection:(std::vector<float>&)deflection forValues:(const std::vector<float>&)vals rcnL:(double&)rcnL rcnR:(double&)rcnR beamStarts:(double)beamStart beamEnds:(double)beamEnd loadStarts:(double)loadStart loadEnds:(double)loadEnd loadMagnitude:(double)totalLoad {
    assert(vals.size() == deflection.size());
    double L = beamEnd - beamStart;
    double a = std::max(0.0, loadStart - beamStart); // Don't let load extend beyond start of beam
    double b = std::min(loadEnd, beamEnd) - std::max(loadStart, beamStart); // Don't let load extend beyond end of beam
    double w = totalLoad;
    double L3 = L*L*L;
    for (int i = 0; i < vals.size(); ++i) {
        double x = vals[i] - beamStart;
        double x2 = x * x;
        double x3 = x * x * x;
        double delta = 0;
        if (deflectLive && b > 0) { // b > 0 means load is on beam
            if (x < a) {
                delta = w * (
                             (x * b * (2*L-2*a - b) / L) *
                             (-2*x2 + 2*a*(2*L - a) + b*(2*L - 2*a - b))
                         );
            }
            else if (x <= a + b) {
                delta = w * (
                             std::pow(x-a, 4) +
                             (x * b * (2*L - 2*a - b) / L) *
                             (-2*x2 + 2*a*(2*L - a) + b*(2*L - 2*a - b))
                         );
            }
            else {
                delta = w * (
                             ((L-x) * b*(b + 2*a) / L) *
                             (
                               -2 * std::pow((L-x), 2) +
                               2 * (L - a - b) * (L + a + b) +
                               b * (b + 2*a)
                             )
                            );
            }
        }
        if (deflectDead) {
            // Extra deflection from dead load
            delta += 1.2 * x * (L3 - 2*L*x2 + x3);
        }
        // Scaling factor. Divide by 12 to convert inches to feet
        delta *= -3.72063E-10 / 12.0;//-1.04758E-6;
        deflection[i] = delta;
    }
    
    if (b <= 0) {
        if (deflectDead) {
            rcnL += 0.6*L;
            rcnR += 0.6*L;
        }
    }
    else {
        rcnL += 0.6*L + w * b * (2*L - 2*a - b) / (2*L);
        rcnR += 0.6*L + w * b * (2*a + b) / (2*L);
    }
}


#pragma mark - Vuforia stuff

// Converts Vuforia matrix to SceneKit matrix
- (GLKMatrix4)GLKMatrix4FromQCARMatrix44:(Vuforia::Matrix44F)matrix {
    GLKMatrix4 glkMatrix;
    
    for(int i=0; i<16; i++) {
        glkMatrix.m[i] = matrix.data[i];
    }
//    printf("m10: %f, m[1] = %f, m[4] = %f\n", glkMatrix.m10, glkMatrix.m[1], glkMatrix.m[4]);
    
    return glkMatrix;
//    return SCNMatrix4FromGLKMatrix4(glkMatrix);
    
}

- (void)printMatrix:(GLKMatrix4)mat {
    printf("%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
           mat.m[0], mat.m[1], mat.m[2], mat.m[3], mat.m[4], mat.m[5], mat.m[6], mat.m[7], mat.m[8], mat.m[9], mat.m[10], mat.m[11], mat.m[12], mat.m[13], mat.m[14], mat.m[15]);
}

// Calculate inverse matrix and assign it to cameraNode
- (void)setCameraMatrix:(Vuforia::Matrix44F)matrix {
    GLKMatrix4 extrinsic = [self GLKMatrix4FromQCARMatrix44:matrix];
    bool invertible;
    GLKMatrix4 inverted = GLKMatrix4Invert(extrinsic, &invertible); // inverse matrix!
//    SCNMatrix4 rotated = SCNMatrix4Mult(inverted, SCNMatrix4MakeRotation(M_PI, 1, 0, 0));
//    GLKMatrix4 desiredMat = GLKMatrix4Make(inverted.m00, -inverted.m01,  -inverted.m02, inverted.m03,
//                                           inverted.m10, -inverted.m11,  -inverted.m12, inverted.m13,
//                                           inverted.m20, -inverted.m21,  -inverted.m22, inverted.m23,
//                                           0,             0,              0,            1);
//    GLKMatrix4 desiredMat = GLKMatrix4Make(inverted.m00,  -inverted.m10,   -inverted.m20, 0,
//                                            inverted.m01,  -inverted.m11,  -inverted.m21, 0,
//                                            inverted.m02,  -inverted.m12,  -inverted.m22, 0,
//                                            inverted.m30, inverted.m31, inverted.m32, 1);
    GLKMatrix4 desiredMat = GLKMatrix4Make(inverted.m00,  inverted.m01,   inverted.m02, 0,
                                            -inverted.m10,  -inverted.m11,  -inverted.m12, 0,
                                            -inverted.m20,  -inverted.m21,  -inverted.m22, 0,
                                            inverted.m30, inverted.m31, inverted.m32, 1);
    [self printMatrix:desiredMat];
    cameraNode.transform = SCNMatrix4FromGLKMatrix4(desiredMat);
//    cameraNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply(fixer, inverted));
//    cameraNode.transform = inverted; // assign it to the camera node's transform property.
}

- (void)setProjectionMatrix:(Vuforia::Matrix44F)matrix {
    GLKMatrix4 projMat = [self GLKMatrix4FromQCARMatrix44:matrix];
    projMat.m11 = -projMat.m11;
    projMat.m22 = -projMat.m22;
    projMat.m23 = -projMat.m23;
    cameraNode.camera.projectionTransform = SCNMatrix4FromGLKMatrix4(projMat);
}

- (void) onVuforiaUpdate: (Vuforia::State *) state {
    
//    Vuforia::Frame frame = state->getFrame();
//    if (frame.getNumImages()) {
//        const Vuforia::Image* img = frame.getImage(0);
//        if (videoTexture == nil) {
//            MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:img->getBufferWidth() height:img->getBufferHeight() mipmapped:NO];
//            id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
//            videoTexture = [gpu newTextureWithDescriptor:texDescription];
////            scene.background.contents = videoTexture;
//            printf("Image: bufferWidth: %d, bufferHeight: %d, width: %d, height: %d, stride: %d, fmt: %d\n", img->getBufferWidth(), img->getBufferHeight(), img->getWidth(), img->getHeight(), img->getStride(), img->getFormat() == Vuforia::GRAYSCALE);
//        }
//        MTLRegion texRegion = MTLRegionMake2D(0, 0, img->getWidth(), img->getHeight());
//        // Copy image into texture
////        [videoTexture replaceRegion:texRegion mipmapLevel:0 withBytes:img->getPixels() bytesPerRow:img->getStride()];
//    }
//    const float kObjectScaleNormal = 0.003f;
    const float kObjectScaleNormal = 10;
    
    [self setProjectionMatrix:self.vapp.projectionMatrix];
    
//    printf("Have %d trackables\n", state->getNumTrackableResults());
    if (state->getNumTrackableResults()) {
        const Vuforia::TrackableResult* track_result = state->getTrackableResult(0);
        
        Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(track_result->getPose());
        SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, &modelViewMatrix.data[0]);
//        SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
        [self setCameraMatrix:modelViewMatrix];
        printf("Pos: %f, %f, %f\n", cameraNode.position.x, cameraNode.position.y, cameraNode.position.z);
        printf("Looking at: %f, %f, %f\n", cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
    }
}


// Load the image tracker data set
- (Vuforia::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}

- (bool) doStopTrackers {
    // Stop the tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

- (bool) doUnloadTrackersData {
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    if (!objectTracker->destroyDataSet(dataSetStonesAndChips))
    {
        NSLog(@"Failed to destroy data set Stones and Chips.");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

- (BOOL)activateDataSet:(Vuforia::DataSet *)theDataSet
{
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
//    if (success) {
//        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingEnabled];
//    }
    
    return success;
}
- (BOOL)deactivateDataSet:(Vuforia::DataSet *)theDataSet
{
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
//    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}
//
//- (BOOL) setExtendedTrackingForDataSet:(Vuforia::DataSet *)theDataSet start:(BOOL) start {
//    BOOL result = YES;
//    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
//        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
//        if (start) {
//            if (!trackable->startExtendedTracking())
//            {
//                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
//                result = false;
//            }
//        } else {
//            if (!trackable->stopExtendedTracking())
//            {
//                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
//                result = false;
//            }
//        }
//    }
//    return result;
//}

#pragma mark - SampleApplicationControl

// Initialize the application trackers
- (bool) doInitTrackers {
    // Initialize the object tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

- (bool) doDeinitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return YES;
}

// load the data associated to the trackers
- (bool) doLoadTrackersData {
    dataSetStonesAndChips = [self loadObjectTrackerDataSet:@"skywalk_far.xml"];
    if (dataSetStonesAndChips == NULL) {
        NSLog(@"Failed to load datasets");
        return NO;
    }
    if (! [self activateDataSet:dataSetStonesAndChips]) {
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    
    
    return YES;
}

// start the application trackers
- (bool) doStartTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

// callback called when the initailization of the AR is done
- (void) onInitARDone:(NSError *)initError {
    if (initError == nil) {
        NSError * error = nil;
        [self.vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
//        [eaglView updateRenderingPrimitives];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
        //[eaglView configureBackground];
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}


@end
