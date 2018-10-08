//
//  CattScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/28/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef CattScene_hpp
#define CattScene_hpp

#include <vector>
#include <thread>

#import "StructureScene.h"
#import "SceneTemplateView.h"

@interface CattScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;
}

@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;

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

#endif /* CattScene_hpp */
