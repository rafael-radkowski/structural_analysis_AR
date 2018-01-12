//
//  CampanileSeismicScene.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/12/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef CampanileSeismicScene_h
#define CampanileSeismicScene_h

#include <vector>

#import "StructureScene.h"
#include "loadMarker.h"
#include "BezierLine.h"

@interface CampanileSeismicScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;

    GrabbableArrow seismicForce1;
    GrabbableArrow seismicForce2;
    GrabbableArrow seismicForce3;
    GrabbableArrow seismicForce4;
    GrabbableArrow seismicForce5;

    std::vector<std::vector<float>> deflVals;
    BezierLine towerL;
    BezierLine towerR;
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

#endif /* CampanileSeismicScene_h */
