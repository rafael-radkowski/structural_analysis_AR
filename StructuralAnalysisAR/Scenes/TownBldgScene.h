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
#include "CircleArrow.h"
#include "PeopleVis.h"
#include "SKCornerNode.h"
#include "TownCalcs.hpp"
#include "SceneTemplateView.h"

@interface TownBldgScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SKScene* skScene;
    SCNNode* cameraNode;
    
    SCNNode* townModel;
    // occlusion planes for AR
    SCNNode* frontOcclPlane;
    SCNNode* sideOcclPlane;

    SKCornerNode* cornerB, *cornerE;
    SKShapeNode* jointBox;
    
    LoadMarker liveLoad;
    LoadMarker deadLoad;
    GrabbableArrow sideLoad;
    PeopleVis people;
    bool forcesDirty;

    TownCalcs::Input_t calc_inputs;
    BezierLine line_AB, line_DC, line_FE, line_BC, line_CE;
    GrabbableArrow F_AB, F_DC, F_FE, V_AB, V_DC, V_FE;
    CircleArrow M_AB, M_DC, M_FE;
    TownCalcs::Deflections_t deflections;
    
    bool draggingJointBox;
    CGPoint lastDragPt;
}
@property (weak, nonatomic) IBOutlet UIView *liveLoadView;
@property (weak, nonatomic) IBOutlet UIView *deadLoadView;
@property (weak, nonatomic) IBOutlet UIView *rcnForceView;
@property (weak, nonatomic) IBOutlet UIView *modelToggleView;
@property (weak, nonatomic) IBOutlet UIView *legendView;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;
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
