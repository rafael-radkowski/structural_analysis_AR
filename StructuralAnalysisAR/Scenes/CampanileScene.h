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
#include <thread>

#import "StructureScene.h"
#import "SceneTemplateView.h"
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
    GrabbableArrow deadLoad;
    CircleArrow momentIndicator;
    
    struct WindPressures {
        double windward_base;
        double windward_side_top;
        double windward_roof;
        double leeward_roof;
        double leeward_side;
    } pressures;
    double seismicSs, seismicS1;
    double snappedSliderPos;

    std::vector<std::vector<float>> fullDeflVals;
    std::vector<std::vector<float>> partialDeflVals;
    float seismicPhase;
    
    BezierLine towerL;
    BezierLine towerR;
    
    SCNNode* campanileInterior;
    SCNNode* campanileExterior;

    bool do_animations;
    bool plotVisible;
}
- (void)updateForces;

@property (nonatomic, retain) IBOutlet SceneTemplateView *viewFromNib;
@property (weak, nonatomic) IBOutlet UISwitch *swayVisSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *modelVisSwitch;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel;

@property (weak, nonatomic) IBOutlet UIView *modelVisView;
@property (weak, nonatomic) IBOutlet UIView *swayVisView;
@property (weak, nonatomic) IBOutlet UIView *scaleLegendView;
@property (weak, nonatomic) IBOutlet UIView *bottomBarView;


@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)sliderReleased:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *sliderValLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *scenarioToggle;

// seismic spectral plot items
@property (weak, nonatomic) IBOutlet UIImageView *plotImgView;
@property (weak, nonatomic) IBOutlet UIView *plotViewBox;
@property (weak, nonatomic) IBOutlet UIButton *seismicPlotBtn;
@property (weak, nonatomic) IBOutlet UILabel *seismicPlotArrow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *plotHeight;
@property (weak, nonatomic) IBOutlet UILabel *fundFreqLabel;
- (IBAction)plotBtnPressed:(id)sender;

// some visualization switch was toggled
- (IBAction)visToggled:(id)sender;

- (IBAction)sliderChanged:(id)sender;
- (IBAction)scenarioChanged:(id)sender;

- (void)calculatePressuresFrom:(double)velocity;
- (void)calculateForcesWind:(double)velocity;
- (void)calculateForcesSeismic:(size_t)scale_idx;

- (void)setVisibilities;

@end

#endif /* CampanileScene_h */
