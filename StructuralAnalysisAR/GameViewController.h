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
#include "PeopleVis.h"
#include "BezierLine.h"
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>

#include <vector>

@interface GameViewController : UIViewController <SKSceneDelegate> {
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
    long activeScenario;
    
    PeopleVis people;
    BezierLine beam1, beam2, beam3;
    
    std::vector<std::vector<float>> beamVals1, beamVals2, beamVals3;
}
// SKSceneDelegate implementations
- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene;

- (void)setVisibilities;
- (void)setupVisualizations;

- (void)calculateDeflection:(std::vector<float>&)deflection forValues:(const std::vector<float>&)vals beamStarts:(double)beamStart beamEnds:(double)beamEnds loadStarts:(double)loadStart loadEnds:(double)loadEnd loadMagnitude:(double)totalLoad;
- (void)updateBeamDeflection;

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
