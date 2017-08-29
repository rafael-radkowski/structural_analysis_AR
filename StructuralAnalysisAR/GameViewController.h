//
//  GameViewController.h
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "grabbableArrow.h"
#import "line3d.h"
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@interface GameViewController : UIViewController {
    // Private vars
    SCNNode *cameraNode;
//    SCNNode *arrowNode;
//    SCNNode *arrowBase;
    SCNNode *targetSphere;
    double arrowScale;
    double arrowWidthFactor;
    bool arrowTop;
    
    double baseRotation;
    double subRotation;
    
    GrabbableArrow arrow;
}

// MARK: Properties
@property (nonatomic, retain) IBOutlet UIView *viewFromNib;
@property (weak, nonatomic) IBOutlet UIStepper *stepperControl;
@property (weak, nonatomic) IBOutlet UISlider *sliderControl;
@property (weak, nonatomic) IBOutlet UISwitch *toggleControl;
@property (weak, nonatomic) IBOutlet UIButton *buttonControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorSelector;
@property (weak, nonatomic) IBOutlet UILabel *topTitle;


// MARK: Actions
- (IBAction)stepperChanged:(id)sender;

- (IBAction)sliderChanged:(id)sender;

- (IBAction)posBtnPressed:(id)sender;

- (IBAction)wideSwitchToggled:(id)sender;

- (IBAction)colorChanged:(id)sender;

// override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

@end
