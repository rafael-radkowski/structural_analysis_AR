//
//  GameViewController.h
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "MainPageViewController.h"
#import "grabbableArrow.h"
#import "line3d.h"
#include "loadMarker.h"
#include "PeopleVis.h"
#include "BezierLine.h"
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>
#import <Metal/Metal.h>

#import "SampleApplicationSession.h"
#import <Vuforia/DataSet.h>

#include <vector>
#include <string>

@interface GameViewController : UIViewController <SKSceneDelegate, SampleApplicationControl> {
    // Private vars
    SCNRenderer* renderer;
    SCNNode *cameraNode;
    SCNScene *scene;
    SKScene *scene2d;
//    SCNNode *arrowNode;
//    SCNNode *arrowBase;
    SCNNode *targetSphere;
    double arrowScale;
    double arrowWidthFactor;
    bool arrowTop;
    
    double baseRotation;
    double subRotation;
    
    GrabbableArrow arrow;
    
    LoadMarker peopleLoad;
    LoadMarker deadLoad;
    std::vector<GrabbableArrow> reactionArrows;
    long activeScenario;
    
    PeopleVis people;
    BezierLine beam1, beam2, beam3;
    
    std::vector<std::vector<float>> beamVals1, beamVals2, beamVals3;
    
    std::vector<std::string> instructions;
    int curStep;
    // Whether to include the dead and live loads in the deflection and reaction calculations
    bool deflectDead;
    bool deflectLive;
    
//    SCNView* scnView;
    // Vuforia stuff
    Vuforia::DataSet*  dataSetStonesAndChips;
    Vuforia::DataSet*  dataSetCurrent;
    BOOL extendedTrackingEnabled;
    BOOL continuousAutofocusEnabled;
    id<MTLTexture> videoTexture;
}
// Vuforia stuff
@property (nonatomic, strong) SampleApplicationSession * vapp;
- (CGRect)getCurrentARViewFrame;

// SKSceneDelegate implementations
- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene;

- (void)setVisibilities;
- (void)setupVisualizations;
- (void)setupInstructions;

- (void)calculateDeflection:(std::vector<float>&)deflection forValues:(const std::vector<float>&)vals rcnL:(double&)rcnL rcnR:(double&)rcnR beamStarts:(double)beamStart beamEnds:(double)beamEnds loadStarts:(double)loadStart loadEnds:(double)loadEnd loadMagnitude:(double)totalLoad;
- (void)updateBeamForces;

- (void)showInstruction:(int)curStep;

// MARK: Properties
@property (nonatomic) bool guided;
@property (nonatomic, retain) IBOutlet UIView *viewFromNib;

@property (weak, nonatomic) IBOutlet UISwitch *liveLoadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *liveLoadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *deadLoadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *deadLoadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *rcnForceSwitch;
@property (weak, nonatomic) IBOutlet UILabel *rcnForceLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *loadPresetBtn;
@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UITextView *instructionBox;
@property (weak, nonatomic) IBOutlet UIButton *prevBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;



// MARK: Actions
// One of the visualization switches was toggled
- (IBAction)visSwitchToggled:(id)sender;
- (IBAction)loadPresetSet:(id)sender;
- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)prevStepPressed:(id)sender;
- (IBAction)nextStepPressed:(id)sender;


// override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

@end
