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
#include "ARManager.h"
#import <Vuforia/DataSet.h>

#include <vector>
#include <string>

@interface GameViewController : UIViewController <SKSceneDelegate, SCNSceneRendererDelegate> {
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
    
    ARManager* arManager;
    enum TrackingMode {
        vuforia = 0,
        opencv = 1
    };
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
// Vuforia stuff
//@property (nonatomic, strong) SampleApplicationSession * vapp;
//- (CGRect)getCurrentARViewFrame;

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


@property (weak, nonatomic) IBOutlet UIView *visOptionsBox;
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
@property (weak, nonatomic) IBOutlet UIButton *freezeFrameBtn;
// Tracking Mode (indoor/outdoor)
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackingModeBtn;
// To hide the interface when processing frames
@property (weak, nonatomic) IBOutlet UIView *processingCurtainView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingSpinner;


//@property (weak, nonatomic) IBOutlet UIStepper *x_stepper_thing;
//@property (weak, nonatomic) IBOutlet UIStepper *y_stepper_thing;
//@property (weak, nonatomic) IBOutlet UIStepper *z_stepper_thing;
//- (IBAction)x_stepper:(id)sender;
//- (IBAction)y_stepper:(id)sender;
//- (IBAction)z_stepper:(id)sender;
//@property (weak, nonatomic) IBOutlet UILabel *x_label;
//@property (weak, nonatomic) IBOutlet UILabel *y_label;
//@property (weak, nonatomic) IBOutlet UILabel *z_label;
@property (weak, nonatomic) IBOutlet UILabel *x_label;
@property (weak, nonatomic) IBOutlet UILabel *y_label;
@property (weak, nonatomic) IBOutlet UILabel *z_label;

//@property (weak, nonatomic) IBOutlet UISwitch *extendedSwitch;
//- (IBAction)extendedChanged:(id)sender;


// MARK: Actions
// One of the visualization switches was toggled
- (IBAction)visSwitchToggled:(id)sender;
- (IBAction)loadPresetSet:(id)sender;
- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)prevStepPressed:(id)sender;
- (IBAction)nextStepPressed:(id)sender;
- (IBAction)freezePressed:(id)sender;
// When the indoor/outdoor toggle switch is touched. Goes between OpenCV ARManager adn Vuforia ARManager
- (IBAction)trackingModeChanged:(id)sender;



// override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

@end
