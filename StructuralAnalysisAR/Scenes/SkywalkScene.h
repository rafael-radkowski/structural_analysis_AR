//
//  SkywalkScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/5/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef SkywalkScene_hpp
#define SkywalkScene_hpp

#include <UIKit/UIKit.h>

#import "StructureScene.h"

#include <stdio.h>

#import "grabbableArrow.h"
#import "line3d.h"
#include "loadMarker.h"
#include "PeopleVis.h"
#include "BezierLine.h"
#include "Ruler.h"
#include "ARManager.h"
#import "SceneTemplateView.h"

#include <vector>
#include <string>
#include <mutex>

@interface SkywalkScene : NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;
    
    // Holds all the skywalk parts
    SCNNode* skywalk;
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
    Ruler ruler;
    
    std::vector<std::vector<float>> beamVals1, beamVals2, beamVals3;
    
    std::vector<std::string> instructions;
    int curStep;
    // Whether to include the dead and live loads in the deflection and reaction calculations
    bool deflectDead;
    bool deflectLive;
    
    bool defnsVisible;
}

// MARK: Properties
@property (nonatomic) bool guided;
@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;

@property (weak, nonatomic) IBOutlet UIView *liveLoadView;
@property (weak, nonatomic) IBOutlet UIView *deadLoadView;
@property (weak, nonatomic) IBOutlet UIView *rcnForceView;
@property (weak, nonatomic) IBOutlet UIView *rulerSwitchView;

@property (weak, nonatomic) IBOutlet UIView *visOptionsBox;
@property (weak, nonatomic) IBOutlet UISwitch *liveLoadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *liveLoadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *deadLoadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *deadLoadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *rcnForceSwitch;
@property (weak, nonatomic) IBOutlet UILabel *rcnForceLabel;
@property (weak, nonatomic) IBOutlet UISwitch *rulerSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *loadPresetBtn;
@property (weak, nonatomic) IBOutlet UITextView *instructionBox;
@property (weak, nonatomic) IBOutlet UIButton *prevBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (weak, nonatomic) IBOutlet UIView *defnsView;
- (IBAction)defnsPressed:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *defnsHeight;
@property (weak, nonatomic) IBOutlet UILabel *defnsExpandLabel;
@property (weak, nonatomic) IBOutlet UIButton *defnsExpandBtn;


// MARK: Actions
// One of the visualization switches was toggled
- (IBAction)visSwitchToggled:(id)sender;
- (IBAction)loadPresetSet:(id)sender;
- (IBAction)prevStepPressed:(id)sender;
- (IBAction)nextStepPressed:(id)sender;

- (void)calculateDeflection:(std::vector<float>&)deflection forValues:(const std::vector<float>&)vals rcnL:(double&)rcnL rcnR:(double&)rcnR beamStarts:(double)beamStart beamEnds:(double)beamEnds loadStarts:(double)loadStart loadEnds:(double)loadEnd loadMagnitude:(double)totalLoad;
- (void)updateBeamForces;

- (void)showInstruction:(int)curStep;


@end

#endif /* SkywalkScene_hpp */
