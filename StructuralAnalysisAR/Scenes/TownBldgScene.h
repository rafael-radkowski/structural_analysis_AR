//
//  TownBldgScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/9/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef TownBldgScene_h
#define TownBldgScene_h

#include <vector>
#include <thread>

#import "StructureScene.h"
#include "loadMarker.h"
#include "BezierLine.h"
#include "CircleArrow.h"
#include "SKCornerNode.h"
#include "TownCalcs.hpp"

@interface TownBldgScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SKScene* skScene;
    SCNNode* cameraNode;
    
    SKCornerNode* cornerB, *cornerE;
    SKShapeNode* jointBox;
    
    LoadMarker liveLoad;
    LoadMarker deadLoad;
    GrabbableArrow sideLoad;

    TownCalcs::Input_t calc_inputs;
    BezierLine line_AB, line_DC, line_FE, line_BC, line_CE;
    GrabbableArrow F_AB, F_FE, V_AB, V_FE;
    
    bool draggingJointBox;
    CGPoint lastDragPt;
}

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (nonatomic, retain) IBOutlet UIView *viewFromNib;
@property (weak, nonatomic) IBOutlet UIView *visOptionsBox;
@property (weak, nonatomic) IBOutlet UISwitch *liveLoadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *deadLoadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rcnForceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *modelSwitch;

@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenshotBtn;
@property (weak, nonatomic) IBOutlet UIView *screenshotInfoBox;
@property (weak, nonatomic) IBOutlet UIButton *freezeFrameBtn;
// Tracking Mode (indoor/outdoor)
@property (weak, nonatomic) IBOutlet UIButton *changeTrackingBtn;
- (IBAction)changeTrackingBtnPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *processingCurtainView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingSpinner;


- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)screenshotBtnPressed:(id)sender;
- (IBAction)freezePressed:(id)sender;
// some visualization switch was toggled
- (IBAction)visToggled:(id)sender;

- (void)setVisibilities;

- (void)updateForces;

// convert a point in scnView coordinate system to skScene coordinate system
- (CGPoint)convertTouchToSKScene:(CGPoint)scnViewPt;

@end

#endif /* TownBldgScene_h */
