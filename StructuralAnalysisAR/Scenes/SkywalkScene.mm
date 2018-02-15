//
//  SkywalkScene.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/5/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

// must include OpenCV-related headers before any iOS ones
#include "cvARManager.h"

#import "SkywalkScene.h"

#include "VuforiaARManager.h"
#include "StaticARManager.h"

#define COL_OFFSET (-10)
#define COL1_POS (-80 + COL_OFFSET)
#define COL2_POS (-25 + COL_OFFSET)
#define COL3_POS (74 + COL_OFFSET)
#define COL4_POS (118 + COL_OFFSET)

// IDs of UISegmentedControl for scenario selection
#define SCENARIO_VARIABLE 4

@implementation SkywalkScene

- (id)initWithController:(id<ARViewController>)controller {
    managingParent = controller;
    return [self init];
}

- (SCNNode*) createScene:(SCNView*)the_scnView skScene:(SKScene*)skScene withCamera:(SCNNode*)camera {
    scnView = the_scnView;
    cameraNode = camera;
    SCNNode* rootNode = [SCNNode node];
    
    auto addLight = [rootNode] (float x, float y, float z, float intensity) {
        SCNNode *lightNode = [SCNNode node];
        lightNode.light = [SCNLight light];
        lightNode.light.type = SCNLightTypeOmni;
        lightNode.light.intensity = intensity;
        lightNode.position = SCNVector3Make(x, y, z);
        [rootNode addChildNode:lightNode];
    };
    addLight(100, 50, -50, 700);
    addLight(0, 30, -100, 500);
    
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.8;
    [rootNode addChildNode:ambientLightNode];
    
    skywalk = [SCNNode node];
    [rootNode addChildNode:skywalk];
    
    float defaultThickness = 5;
    //    float heightOffset = -17;
    float heightOffset = 0;
    
    GLKQuaternion beamOri = GLKQuaternionMakeWithAngleAndAxis(0, 0, 0, 1);
    // Create live load bar
    peopleLoad = LoadMarker(3);
    peopleLoad.setPosition(GLKVector3Make(0, 33 + heightOffset, 0));
    peopleLoad.setOrientation(beamOri);
    peopleLoad.setInputRange(0, 1.5);
    peopleLoad.setMinHeight(15);
    peopleLoad.setMaxHeight(40);
    peopleLoad.setThickness(defaultThickness);
    peopleLoad.addAsChild(skywalk);
    
    // Create dead load bar
    deadLoad = LoadMarker(6);
    deadLoad.setInputRange(0, 1.5);
    deadLoad.setLoad(1.2); // 1.2 k/ft
    //    float dead_z = self.guided ?
    deadLoad.setPosition(GLKVector3Make(0, 5 + heightOffset, 0));
    deadLoad.setOrientation(beamOri);
    deadLoad.setEnds(COL1_POS, COL4_POS);
    deadLoad.setMinHeight(15);
    deadLoad.setMaxHeight(28);
    deadLoad.setThickness(defaultThickness);
    deadLoad.addAsChild(skywalk);
    
    reactionArrows.resize(4);
    for (int i = 0; i < reactionArrows.size(); ++i) {
        reactionArrows[i].addAsChild(skywalk);
        reactionArrows[i].setFormatString(@"%.1f k");
        reactionArrows[i].setThickness(defaultThickness);
        reactionArrows[i].setMinLength(15);
        reactionArrows[i].setMaxLength(40);
        reactionArrows[i].setInputRange(0, 150);
        reactionArrows[i].setRotationAxisAngle(GLKVector4Make(0, 0, 1, 3.1416));
        reactionArrows[i].setScenes(skScene, scnView);
    }
    reactionArrows[0].setPosition(GLKVector3Make(COL1_POS, 3 + heightOffset, 0));
    reactionArrows[1].setPosition(GLKVector3Make(COL2_POS, 3 + heightOffset, 0));
    reactionArrows[2].setPosition(GLKVector3Make(COL3_POS, 3 + heightOffset, 0));
    reactionArrows[3].setPosition(GLKVector3Make(COL4_POS, 3 + heightOffset, 0));
    
    people = PeopleVis(10);
    people.setPosition(GLKVector3Make(0, heightOffset, 0));
    people.addAsChild(skywalk);
    
    double gap = 1.5;
    int resolution = 10;
    beamVals1.resize(2); beamVals2.resize(2); beamVals3.resize(2);
    double stepSize1 = (COL2_POS - COL1_POS - gap) / (resolution - 1);
    double stepSize2 = (COL3_POS - COL2_POS - gap) / (resolution - 1);
    double stepSize3 = (COL4_POS - COL3_POS - (gap/2)) / (resolution - 1);
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
    beam1.addAsChild(skywalk);
    beam2.addAsChild(skywalk);
    beam3.addAsChild(skywalk);
    beam1.setOrientation(beamOri);
    beam2.setOrientation(beamOri);
    beam3.setOrientation(beamOri);
    beam1.setPosition(GLKVector3Make(0, 2 + heightOffset, 0));
    beam2.setPosition(GLKVector3Make(0, 2 + heightOffset, 0));
    beam3.setPosition(GLKVector3Make(0, 2 + heightOffset, 0));
    beam1.setScenes(skScene, scnView);
    beam2.setScenes(skScene, scnView);
    beam3.setScenes(skScene, scnView);
    
    peopleLoad.setScenes(skScene, scnView);
    deadLoad.setScenes(skScene, scnView);
    
    return rootNode;
}


- (void) setupUIWithScene:(SCNView*)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided {
    self.guided = guided;
    [[NSBundle mainBundle] loadNibNamed:@"skywalkView" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    // Hide visualization toggles switches in guided mode
    if (self.guided) {
        self.visOptionsBox.hidden = YES;
        self.defnsView.hidden = YES;
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
    
    // Setup freeze frame button
    self.freezeFrameBtn.layer.borderWidth = 1.5;
    self.freezeFrameBtn.layer.borderColor = textColor;
    self.freezeFrameBtn.layer.cornerRadius = 5;
    
    // Setup change tracking mode button
    self.changeTrackingBtn.layer.borderWidth = 1.5;
    self.changeTrackingBtn.layer.borderColor = textColor;
    self.changeTrackingBtn.layer.cornerRadius = 5;
    
    self.processingCurtainView.hidden = YES;
    self.processingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    
    self.visOptionsBox.layer.borderWidth = 1.5;
    self.visOptionsBox.layer.borderColor = UIColor.grayColor.CGColor;
    
    // Definitiosn box border
    self.defnsExpandBtn.layer.borderWidth = 1.5;
    self.defnsExpandBtn.layer.borderColor = UIColor.grayColor.CGColor;
    self.defnsView.layer.borderWidth = 1.5;
    self.defnsView.layer.borderColor = UIColor.grayColor.CGColor;
    self.defnsHeight.constant = 50;
    
    deflectLive = deflectDead = true;
    
    // Set load visibilities to the default values
    [self setVisibilities];
    [self setupInstructions];
    
    [self.loadPresetBtn sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void) skUpdate {
    peopleLoad.doUpdate();
    deadLoad.doUpdate();
    for (GrabbableArrow& rcnArrow : reactionArrows) {
        rcnArrow.doUpdate();
    }
    beam1.doUpdate();
    beam2.doUpdate();
    beam3.doUpdate();
}

- (void) scnRendererUpdateAt:(NSTimeInterval)time {
}

- (void)setupInstructions {
    if (self.guided) {
        instructions.push_back("Step 1\nShown above is the Skywalk, which can be simplified and modeled as three spans, each simply supported.");
        instructions.push_back("Step 2\nThe self-weight of the Skywalk acts as a uniformly distributed dead load that is always acting on the beam.");
        instructions.push_back("Step 3\nThis dead load causes the structure to deflect. Deflection values are based off of an estimated composite moment of inertia and modulus of elasticity.");
        instructions.push_back("Step 4\nPeople walking on the Skywalk contribute more load to the structure. They act as a uniformly distributed live load.");
        instructions.push_back("Step 5\nThe addition of this live load causes the structure to deflect an additional amount.");
        instructions.push_back("Step 6\nThe simplified Skywalk model has four supports, each having a vertical reaction force that counteracts the magnitude of the dead and live loads.");
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

- (IBAction)freezePressed:(id)sender {
    [managingParent freezePressed:sender freezeBtn:self.freezeFrameBtn curtain:self.processingCurtainView];
}

- (IBAction)homeBtnPressed:(id)sender {
    return [managingParent homeBtnPressed:sender];
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
        case 3: // right
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

- (void)setCameraLabelPaused:(bool)isPaused isEnabled:(bool)enabled {
    if (isPaused) {
        [self.freezeFrameBtn setTitle:@"Resume Camera" forState:UIControlStateNormal];
    }
    else {
        [self.freezeFrameBtn setTitle:@"Pause Camera" forState:UIControlStateNormal];
    }
    self.freezeFrameBtn.enabled = enabled;
}

- (IBAction)changeTrackingBtnPressed:(id)sender {
    CGRect frame = [self.changeTrackingBtn.superview convertRect:self.changeTrackingBtn.frame toView:scnView];
    [managingParent changeTrackingMode:frame];
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

- (IBAction)defnsPressed:(id)sender {
    defnsVisible = !defnsVisible;
    if (defnsVisible) {
        self.defnsHeight.constant = 250;
        self.defnsExpandLabel.transform = CGAffineTransformMakeRotation(M_PI);
    }
    else {
        self.defnsHeight.constant = 50;
        self.defnsExpandLabel.transform = CGAffineTransformMakeRotation(0);
    }
    [UIView animateWithDuration:0.3 animations:^{
        [scnView layoutIfNeeded];
    }];
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

// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(-15, 7, 280);
    GLKMatrix4 rot_y_mat = GLKMatrix4MakeYRotation(M_PI);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.1);
    GLKMatrix4 rot_z_mat = GLKMatrix4MakeZRotation(0.02);
    // Rotate by Y, then X
    GLKMatrix4 rot_mat = GLKMatrix4Multiply(rot_z_mat, GLKMatrix4Multiply(rot_y_mat, rot_x_mat));
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_mat, trans_mat);
    
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"skywalk_south_far.jpg");
}

- (ARManager*)makeIndoorTracker {
//    return new VuforiaARManager((ARView*)scnView, scnView.scene, Vuforia::METAL, managingParent.interfaceOrientation);
    GLKMatrix4 translation_mat = GLKMatrix4MakeTranslation(-10, 21, 0);
    GLKMatrix4 rot_y_mat = GLKMatrix4MakeYRotation(M_PI);
    GLKMatrix4 transform_mat = GLKMatrix4Multiply(rot_y_mat, translation_mat);
    return new VuforiaARManager((ARView*)scnView, scnView.scene, UIInterfaceOrientationLandscapeRight, @"skywalk_south1.xml", transform_mat);
}

- (ARManager*)makeOutdoorTracker {
    // Apply transformation to account for where the reference (model) image was taken from
    //        static const double y_angle = 0.174;
    //        static double rot_mat_data[16] = {
    //            std::cos(y_angle), 0, 0, 0,
    //            0, , -std::sin(y_angle), 0,
    //            0, std::sin(y_angle), std::cos(y_angle), 0,
    //            0, 0, 0, 1
    //        };
    //        static const cv::Mat rot_mat(3, 3, CV_64F, rot_mat_data);
    GLKMatrix4 rotMat_y = GLKMatrix4MakeYRotation(0.2 + M_PI);
    GLKMatrix4 rotMat_x = GLKMatrix4MakeXRotation(0.2);
    GLKMatrix4 rotMat = GLKMatrix4Multiply(rotMat_y, rotMat_x);
    
    return new cvARManager(scnView, scnView.scene, cvStructure_t::skywalk, rotMat);
}

// Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
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

@end
