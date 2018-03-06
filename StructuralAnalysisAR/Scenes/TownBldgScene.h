//
//  CampanileScene.hpp
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

@interface TownBldgScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;
}

@property (nonatomic, retain) IBOutlet UIView *viewFromNib;
@property (weak, nonatomic) IBOutlet UIView *visOptionsBox;
@property (weak, nonatomic) IBOutlet UISwitch *modelVisSwitch;

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

@end

#endif /* TownBldgScene_h */
