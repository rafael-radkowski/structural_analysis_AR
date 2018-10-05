//
//  SceneTemplateView.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/3/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Scenes/StructureScene.h"

IB_DESIGNABLE
@interface SceneTemplateView : UIView

// Set this when initializing scene so the buttons in this view work
@property id<ARViewController> managingParent;

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenshotBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *changeTrackingBtn;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (weak, nonatomic) IBOutlet UIStackView *visOptionsBox;
@property (weak, nonatomic) IBOutlet UIView *screenshotInfoBox;
@property (weak, nonatomic) IBOutlet UIView *processingCurtainView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingSpinner;


- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)screenshotBtnPressed:(id)sender;
- (IBAction)pauseCamBtnpressed:(id)sender;
- (IBAction)changeTrackingBtnPressed:(id)sender;

@end
