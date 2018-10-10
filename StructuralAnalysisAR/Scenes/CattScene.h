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
#include "line3d.h"
#include "grabbableArrow.h"

@interface CattScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SKScene* skScene;
    SCNNode* cameraNode;
    
    // truss members
    Line3d memb1, memb2, memb3, memb4, memb5 ,memb6, memb7;
    
    // point loads
    GrabbableArrow pArrow01, pArrow02, pArrow06, pArrow1, pArrow2, pArrow3, pArrow4, pArrow5;
    // Reaction forces
    GrabbableArrow rArrow1, rArrow2, rArrow3;
}

@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;

// vis options items
@property (weak, nonatomic) IBOutlet UIView *rcnForceView;

@property (weak, nonatomic) IBOutlet UISwitch *rcnForceSwitch;
@property (weak, nonatomic) IBOutlet UISlider *snowSlider;
@property (weak, nonatomic) IBOutlet UISlider *windSlider;

@property (weak, nonatomic) IBOutlet UILabel *snowDepthLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;
- (IBAction)loadsChanged:(id)sender;


// some visualization switch was toggled
- (IBAction)visToggled:(id)sender;

- (void)setVisibilities;

@end

#endif /* CattScene_hpp */
