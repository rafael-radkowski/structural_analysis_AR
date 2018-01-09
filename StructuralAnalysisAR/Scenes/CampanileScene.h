//
//  CampanileScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/9/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef CampanileScene_hpp
#define CampanileScene_hpp

#include <stdio.h>

#import "StructureScene.h"
#include "loadMarker.h"
#include "BezierLine.h"

@interface CampanileScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;
    
    LoadMarker windwardSideLoad;
    LoadMarker windwardRoofLoad;
    LoadMarker leewardSideLoad;
    LoadMarker leewardRoofLoad;
    
}

@property (nonatomic, retain) IBOutlet UIView *viewFromNib;

@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *freezeFrameBtn;
// Tracking Mode (indoor/outdoor)
@property (weak, nonatomic) IBOutlet UISegmentedControl *trackingModeBtn;


- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)freezePressed:(id)sender;
// When the indoor/outdoor toggle switch is touched. Goes between OpenCV ARManager adn Vuforia ARManager
- (IBAction)trackingModeChanged:(id)sender;

@end

#endif /* CampanileScene_hpp */
