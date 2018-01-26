//
//  CampanileScene.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/9/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef CampanileScene_h
#define CampanileScene_h

#include <vector>

#import "StructureScene.h"
#include "loadMarker.h"
#include "BezierLine.h"
#include "CircleArrow.h"

@interface CampanileScene: NSObject <StructureScene> {
    id<ARViewController> managingParent;
    SCNView* scnView;
    SCNNode* cameraNode;
    
    enum Scenario {
        wind,
        seismic
    } activeScenario;
    
    LoadMarker windwardSideLoad;

    std::vector<GrabbableArrow> seismicArrows;
    
    GrabbableArrow shearArrow;
    GrabbableArrow axialArrow;
    CircleArrow momentIndicator;
    
    struct WindPressures {
        double windward_base;
        double windward_side_top;
        double windward_roof;
        double leeward_roof;
        double leeward_side;
    } pressures;
    double seismicScaleSg, seismicScaleS1;
    double snappedSliderPos;

    std::vector<std::vector<float>> fullDeflVals;
    std::vector<std::vector<float>> partialDeflVals;
    float seismicPhase;
    
    BezierLine towerL;
    BezierLine towerR;
}

@property (nonatomic, retain) IBOutlet UIView *viewFromNib;

@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *freezeFrameBtn;
// Tracking Mode (indoor/outdoor)
@property (weak, nonatomic) IBOutlet UIButton *changeTrackingBtn;
- (IBAction)changeTrackingBtnPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)sliderReleased:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *sliderValLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *scenarioToggle;


- (IBAction)homeBtnPressed:(id)sender;
- (IBAction)freezePressed:(id)sender;

- (IBAction)sliderChanged:(id)sender;
- (IBAction)scenarioChanged:(id)sender;

- (void)calculatePressuresFrom:(double)velocity;
- (void)calculateForcesWind:(double)velocity;
- (void)calculateForcesSeismic:(size_t)scale_idx;

@end

#endif /* CampanileScene_h */
