//
//  SceneTemplateView.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/3/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SceneTemplateView : UIView

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenshotBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *changeTrackingBtn;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (weak, nonatomic) IBOutlet UIView *visOptionsBox;
@property (weak, nonatomic) IBOutlet UIView *screenshotInfoBox;
@property (weak, nonatomic) IBOutlet UIView *processingCurtainView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingSpinner;
@end
