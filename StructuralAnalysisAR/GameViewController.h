//
//  GameViewController.h
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "grabbableArrow.h"
#import "line3d.h"
#include "loadMarker.h"
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>

#include <vector>

@interface GameViewController : UIViewController {
    // Private vars
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
    int activeScenario;
}

- (void)setVisibilities;
- (void)setupVisualizations;

// MARK: Properties
@property (nonatomic, retain) IBOutlet UIView *viewFromNib;

@property (weak, nonatomic) IBOutlet UISwitch *liveLoadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *deadLoadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rcnForceSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *loadPresetBtn;



// MARK: Actions
// One of the visualization switches was toggled
- (IBAction)visSwitchToggled:(id)sender;
- (IBAction)loadPresetSet:(id)sender;


// override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event;

@end
