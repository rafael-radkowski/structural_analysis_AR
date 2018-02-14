//
//  CampanileScene.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/9/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

// must include cvARManager.h before others, because it includes openCV headers
#include "cvARManager.h"
#include "CampanileScene.h"

#include "VuforiaARManager.h"
#include "StaticARManager.h"

@implementation CampanileScene

static const float base_width = 16;
static const float base_height = 89 + 2.f / 12;
static const float roof_height = 20 + 4.5 / 12;
static const float roof_angle = (M_PI / 180.0) * 68.56;

static const double MOD_ELASTICITY = 2.016e8;
static const double MOM_OF_INERTIA = 2334;

- (id)initWithController:(id<ARViewController>)controller {
    managingParent = controller;
    seismicPhase = 0;
    return [self init];
}

- (SCNNode *)createScene:(SCNView *)the_scnView skScene:(SKScene *)skScene withCamera:(SCNNode *)camera {
    scnView = the_scnView;
    cameraNode = camera;
    activeScenario = wind;
    SCNNode* rootNode = [SCNNode node];
    
    auto addLight = [rootNode] (float x, float y, float z, float intensity) {
        SCNNode *lightNode = [SCNNode node];
        lightNode.light = [SCNLight light];
        lightNode.light.type = SCNLightTypeOmni;
        lightNode.light.intensity = intensity;
        lightNode.position = SCNVector3Make(x, y, z);
        [rootNode addChildNode:lightNode];
    };
    addLight(100, 50, 50, 700);
    addLight(0, 30, 100, 500);
    addLight(0, -30, 0, 300);
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.8;
    [rootNode addChildNode:ambientLightNode];
    
    // Load overlay model
    auto loadModel = [](NSString* path) {
        NSString* modelPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:path] ofType:@"obj"];
        NSURL* modelUrl = [NSURL fileURLWithPath:modelPath];
        MDLAsset* modelAsset = [[MDLAsset alloc] initWithURL:modelUrl];
        SCNNode* model_node = [SCNNode nodeWithMDLObject:[modelAsset objectAtIndex:0]];
        return model_node;
    };
    SCNNode* campanileInterior = loadModel(@"campanile_interior");
    SCNNode* campanileExterior = loadModel(@"campanile_exterior");
    [rootNode addChildNode:campanileExterior];
    [rootNode addChildNode:campanileInterior];
    SCNMaterial* campanileMatClear = [SCNMaterial material];
    SCNMaterial* campanileMatOpaque = [SCNMaterial material];
    campanileMatClear.diffuse.contents = [UIColor colorWithRed:1.0 green:0.68 blue:0.478 alpha:1.0];
    campanileMatOpaque.diffuse.contents = [UIColor colorWithRed:1.0 green:0.68 blue:0.478 alpha:1.0];
    campanileExterior.geometry.firstMaterial = campanileMatClear;
    campanileInterior.geometry.firstMaterial = campanileMatOpaque;
    campanileExterior.opacity = 0.4;
    campanileInterior.opacity = 0.6;
    // Force a rendering order, otherwise the interior does not appear
    campanileInterior.renderingOrder = 50;
    campanileExterior.renderingOrder = 100;
//    MDLObject* exterior = [modelAsset objectAtPath:@"exterior_Basic_Wall_Generic_-_12__Masonry__Brick___527010__Geometry"];

    float load_min_h = 10; float load_max_h = 35;
    float thickness = 3;

    windwardSideLoad = LoadMarker(7, false, 2);
    windwardSideLoad.setPosition(GLKVector3Make(-base_width/2, 0, 0));
    windwardSideLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI/2.f, 0, 0, 1));
    windwardSideLoad.setEnds(0, 89 + 2.f/12);

    windwardSideLoad.setScenes(skScene, scnView);
    windwardSideLoad.setFormatString(@"%.1f psf");
    windwardSideLoad.setInputRange(0, 55);
    windwardSideLoad.setMinHeight(load_min_h);
    windwardSideLoad.setMaxHeight(load_max_h);
    windwardSideLoad.setThickness(thickness);
    windwardSideLoad.addAsChild(rootNode);
    windwardSideLoad.setLoad(0.5);

    shearArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    shearArrow.setPosition(GLKVector3Make(0, -5, 0));
    
    shearArrow.setMinLength(20);
    shearArrow.setMaxLength(50);
    shearArrow.setThickness(thickness);
    axialArrow.setMinLength(5);
    axialArrow.setMaxLength(20);
    axialArrow.setInputRange(0, 1540);
    axialArrow.setThickness(thickness);
    axialArrow.setLabelFollow(false);
    axialArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    
    shearArrow.setFormatString(@"%.2f k");
    axialArrow.setFormatString(@"%.1f k");
    
    shearArrow.setScenes(skScene, scnView);
    axialArrow.setScenes(skScene, scnView);
    shearArrow.addAsChild(rootNode);
    axialArrow.addAsChild(rootNode);

    momentIndicator.addAsChild(rootNode);
    momentIndicator.setInputRange(-100, 4000);
    momentIndicator.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    momentIndicator.setThickness(thickness);
    momentIndicator.setRadius(18);
    momentIndicator.setScenes(skScene, scnView);

    // Tower deflection
    fullDeflVals.resize(2);
    partialDeflVals.resize(2);
    int resolution = 8;
    double step_size = (base_height) / (resolution - 1);
    for (int i = 0; i < resolution; ++i) {
        fullDeflVals[0].push_back(step_size * i);
        fullDeflVals[1].push_back(0);
        partialDeflVals[0].push_back(step_size * i);
        partialDeflVals[1].push_back(0);
    }
    towerL.setPosition(GLKVector3Make(-base_width/2 + thickness/2, 0, 0));
    towerR.setPosition(GLKVector3Make(base_width/2 + thickness/2, 0, 0));
    towerL.setTextLocX(1.1);
    towerR.setTextHidden(true);
    for (BezierLine* tower : {&towerL, &towerR}) {
        tower->setThickness(thickness);
        tower->addAsChild(rootNode);
        tower->setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI/2, 0, 0, 1));
        tower->setScenes(skScene, scnView);
        tower->updatePath(fullDeflVals);
    }

    // Seismic force arrows
    for (int i = 0; i < 5; i++) {
        seismicArrows.emplace_back();
        seismicArrows[i].addAsChild(rootNode);
        seismicArrows[i].setInputRange(10, 800);
        seismicArrows[i].setMinLength(5);
        seismicArrows[i].setMaxLength(30);
        seismicArrows[i].setThickness(thickness);
        seismicArrows[i].setScenes(skScene, scnView);
        seismicArrows[i].setFormatString(@"%.2f k");
        seismicArrows[i].setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    }
    seismicArrows[0].setPosition(GLKVector3Make(base_width/2, 17.75, 0));
    seismicArrows[1].setPosition(GLKVector3Make(base_width/2, 57.5, 0));
    seismicArrows[2].setPosition(GLKVector3Make(base_width/2, 71.5, 0));
    seismicArrows[3].setPosition(GLKVector3Make(base_width/2, 89.16667, 0));
    seismicArrows[4].setPosition(GLKVector3Make(base_width/2, 109.5, 0));

    return rootNode;
}

- (void)scnRendererUpdateAt:(NSTimeInterval)time {
    if (activeScenario == seismic && do_animations) {
        const double period = 0.677;
        static double initial_time = time;
        double scaled_phase = (initial_time - time) * (1 / period) * M_PI * 2;
        double proportion = std::sin(scaled_phase);
        size_t n_steps = fullDeflVals[0].size();
        for (size_t i = 0; i < n_steps; ++i) {
            partialDeflVals[1][i] = fullDeflVals[1][i] * proportion;
        }
        towerL.updatePath(partialDeflVals);
        towerR.updatePath(partialDeflVals);
    }
}

- (void)setCameraLabelPaused:(bool)isPaused {
    if (isPaused) {
        [self.freezeFrameBtn setTitle:@"Resume Camera" forState:UIControlStateNormal];
    }
    else {
        [self.freezeFrameBtn setTitle:@"Pause Camera" forState:UIControlStateNormal];
    }
}

- (void)setupUIWithScene:(SCNView *)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided {
    [[NSBundle mainBundle] loadNibNamed:@"campanileView" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    CGColor* textColor = [UIColor colorWithRed:0.08235 green:0.49412 blue:0.9843 alpha:1.0].CGColor;
    // Setup home button style
    self.homeBtn.layer.borderWidth = 1.5;
    self.homeBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.homeBtn.layer.borderColor = textColor;
    self.homeBtn.layer.cornerRadius = 5;
    
    // Setup freeze frame button
    self.freezeFrameBtn.layer.borderWidth = 1.5;
    self.freezeFrameBtn.layer.borderColor = textColor;
    self.freezeFrameBtn.layer.cornerRadius = 5;
    
    // Setup change tracking button
    self.changeTrackingBtn.layer.borderWidth = 1.5;
    self.changeTrackingBtn.layer.borderColor = textColor;
    self.changeTrackingBtn.layer.cornerRadius = 5;
    
    // Processing curtain view
    self.processingCurtainView.hidden = YES;
    self.processingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    
    // Set initial wind speed and notify so callback gets called
    [self.slider setValue:0.5];
    [self.scenarioToggle sendActionsForControlEvents:UIControlEventValueChanged];
    [self setVisibilities];
}

- (void)skUpdate {
    windwardSideLoad.doUpdate();
    shearArrow.doUpdate();
    axialArrow.doUpdate();
    towerL.doUpdate();
    towerR.doUpdate();
    momentIndicator.doUpdate();
    for (GrabbableArrow& arrow : seismicArrows) {
        arrow.doUpdate();
    }
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(0, 37, 230);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.3);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_x_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"campanile_static.JPG");
}

- (ARManager*)makeIndoorTracker {
    GLKMatrix4 translation_mat = GLKMatrix4MakeTranslation(0, 50, 0);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.2);
    GLKMatrix4 transform_mat = GLKMatrix4Multiply(rot_x_mat, translation_mat);
    return new VuforiaARManager((ARView*)scnView, scnView.scene, UIInterfaceOrientationLandscapeRight, @"campanile.xml", transform_mat);
}

- (ARManager*)makeOutdoorTracker {
    GLKMatrix4 rotMat = GLKMatrix4MakeYRotation(0.0);
    return new cvARManager(scnView, scnView.scene, cvStructure_t::campanile, rotMat);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}


- (IBAction)freezePressed:(id)sender {
    [managingParent freezePressed:sender freezeBtn:self.freezeFrameBtn curtain:self.processingCurtainView];
}

- (IBAction)swapVisToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
    do_animations = self.swayVisSwitch.on;
    if (!do_animations) {
        // Just toggled off. set towers to max deflections
        towerL.updatePath(fullDeflVals);
        towerR.updatePath(fullDeflVals);
    }
}

- (IBAction)homeBtnPressed:(id)sender {
    return [managingParent homeBtnPressed:sender];
}

- (IBAction)changeTrackingBtnPressed:(id)sender {
    CGRect frame = [self.changeTrackingBtn.superview convertRect:self.changeTrackingBtn.frame toView:scnView];
    [managingParent changeTrackingMode:frame];
    [self setCameraLabelPaused:NO];
}

- (IBAction)sliderChanged:(id)sender {
    float slider_val = self.slider.value;
    switch (activeScenario) {
        case wind: {
            double vel = slider_val * 150;
            [self calculateForcesWind:vel];
            towerL.updatePath(fullDeflVals);
            towerR.updatePath(fullDeflVals);
            break;
        }
        case seismic: {
            const double Ss_vals[8] = {0.05, 0.25, 0.5, 0.75, 1, 1.25, 2, 3};
            const size_t n_elems = sizeof(Ss_vals) / sizeof(Ss_vals[0]);
            double scaled_val = slider_val * (Ss_vals[n_elems - 1] - Ss_vals[0]) + Ss_vals[0];
            auto closest_elem = std::min_element(&Ss_vals[0], &Ss_vals[n_elems],
                 [&] (double a, double b) {
                    return std::abs(a - scaled_val) < std::abs(b - scaled_val);
            });
            size_t closest_idx = closest_elem - Ss_vals;
            
            // Find nearest value
            double Ss = Ss_vals[closest_idx];
            snappedSliderPos  = (Ss - Ss_vals[0]) / (Ss_vals[n_elems - 1] - Ss_vals[0]);
            // Allow the actual slider position to "rubber-band" to the sticky positions
            const double alpha = 0.7;
            double ss_slider_stretched = (alpha * snappedSliderPos) + ((1 - alpha) * slider_val);
            [self.slider setValue:ss_slider_stretched animated:NO];
            [self calculateForcesSeismic:closest_idx];
            break;
        }
        default: {
            assert(false);
            break;
        }
    }
}

- (IBAction)sliderReleased:(id)sender {
    if (activeScenario == seismic) {
        // Have slider go to final position when released (Don't want it to remain at rubber-band location)
        [self.slider setValue:snappedSliderPos animated:YES];
    }
}

- (void)calculateForcesWind:(double)velocity {
    //    label.text = [NSString stringWithFormat:@"%.1f k/ft", 123.3f];
    [self.sliderValLabel setText:[NSString stringWithFormat:@"%.0f mph", velocity]];
    [self calculatePressuresFrom:velocity];
    
    // Set intensities
    windwardSideLoad.setLoadInterpolate(pressures.windward_base - pressures.leeward_side, pressures.windward_side_top - pressures.leeward_side);

    // breakdown roof pressures into components
    
    // convenience
    const double h1 = base_height;
    const double h2 = roof_height;
    const double ww1 = pressures.windward_base;
    const double ww2 = pressures.windward_side_top;
    const double wl = -pressures.leeward_side;
    
    const double h1_2 = h1 * h1;
    const double h1_3 = h1_2 * h1;
    // Calculate shear, axial, and moment
    double shear = (16./1000) * (h1*(ww1/2 + ww2/2 + wl));
    double axial = 1540;
    double moment = (16./1000) *
        (h1_2/2 * (ww1 + wl) +
         h1_2/2 * (ww2 - ww1));

    // Update indicators
    shearArrow.setIntensity(shear);
    axialArrow.setIntensity(axial);
    momentIndicator.setIntensity(moment);
    
    // Calculate deflection
    size_t resolution = fullDeflVals[0].size();
    for (int i = 0; i < resolution; ++i) {
        double x = fullDeflVals[0][i] - fullDeflVals[0][0];
        double x2 = x * x;
        double x3 = x2 * x;

        double defl1, defl2, defl3;
        if (x <= h1) {
            double defl13_common = 4*h1*x - x2 - 6*h1_2;
            defl1 = (2*ww1*x2 / 3) * defl13_common;
            defl3 = (2*wl*x2 / 3) * defl13_common;
            
            defl2 = (2*(ww2-ww1)*x2 / 15) * (10*h1*x - x3/h1 - 20*h1_2);
            
//            double defl45_common = x2 * (x + 1.5*h2 + 3*h1);
//            defl4 = (-8 * h2 * wd1 * cotan / 3) * defl45_common;
//            defl5 = (-8 * h2 * wd2 * cotan / 3) * defl45_common;
            
            //            defl1 = 2*ww1*x2 * (356.67*x - x2 - 47704.5) / 3;
            //            defl2 = (2./15) * (ww2 - ww1) * x2 * (891.67*x - 0.0112*x3 - 159015.08);
            //            defl3 = 2*wl*x2 * (356.67*x - x2 - 47704.5) / 3;
            //            defl4 = -21.34 * wd1 * x2 * (x + 298.06);
            //            defl5 = -21.34  *wd2 * x2 * (x + 298.06);
        }
        else if (x <= (h1 + h2)) {
            defl1 = 2 * ww1 * h1_3 * (-4*x + h1) / 3;
            defl2 = 8 * h1_3 * (ww2 - ww1) * (h1/15 - x/4);
            defl3 = 2 * wl * h1_3 * (-4*x + h1) / 3;
            
//            double defl45_common = x3*h2/6 - x4/24 + x2*(h1_2-h2_2)/4 + x*(h2_2*h1 + h1_2*h2 - h1_3/3) - h2_2*h1_2/2 + h1_4/8 - h1_3*h2/2;
//            defl4 = -16 * cotan * wd1 * defl45_common;
//            defl5 = -16 * cotan * wd2 * defl45_common;
            
            //            defl1 = 472629.92 * ww1 * (-4*x + 89.167);
            //            defl2 = 5671558.98 * (ww2 - ww1) * (5.94 - 0.25 * x);
            //            defl3 = 472629.92 * wl * (-4*x + 89.167);
            //            double defl45_common = (3.4 * x3 - 0.042 * x4 + 1883.9 * x2 - 37301.5 * x - 970905.42);
            //            defl4 = -6.28 * wd1 * defl45_common;
            //            defl5 = -6.28 * wd2 * defl45_common;
        }
        else {assert(false);}
        double sum_defl = defl1 + defl2 + defl3;
        double defl_ft = sum_defl / (MOD_ELASTICITY * MOM_OF_INERTIA);
        //        double defl_in = sum_defl / (2.016e8. * 2334. / 12.);
        fullDeflVals[1][i] = defl_ft;
    }
}

- (void)calculateForcesSeismic:(size_t)scale_idx {
    const double Ss_vals[8] = {0.05, 0.25, 0.5, 0.75, 1, 1.25, 2, 3};
    const double S1_vals[8] = {0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.8, 1.2};
    const double V_vals[8]= {49.26, 246.28, 410.46, 554.12, 656.74, 769.62, 1231.38, 1847.08};
    const double F1_vals[8]= {0.49, 2.46, 4.10, 5.54, 6.57, 7.70, 12.31, 18.47};
    const double F2_vals[8]= {5.47, 27.34, 45.56, 61.51, 72.90, 85.43, 136.68, 205.03};
    const double F3_vals[8]= {8.62, 43.10, 71.83, 96.97, 114.93, 134.68, 215.49, 323.24};
    const double F4_vals[8]= {13.69, 68.46, 114.11, 154.05, 182.57, 213.95, 342.32, 513.49};
    const double F5_vals[8]= {20.98, 104.91, 174.86, 236.06, 279.77, 327.86, 524.57, 786.85};
    
    double F1 = F1_vals[scale_idx];
    double F2 = F2_vals[scale_idx];
    double F3 = F3_vals[scale_idx];
    double F4 = F4_vals[scale_idx];
    double F5 = F5_vals[scale_idx];
    double V = V_vals[scale_idx];
    double Ss = Ss_vals[scale_idx];
    double S1 = S1_vals[scale_idx];
    
    shearArrow.setIntensity(V);
    seismicArrows[0].setIntensity(F1);
    seismicArrows[1].setIntensity(F2);
    seismicArrows[2].setIntensity(F3);
    seismicArrows[3].setIntensity(F4);
    seismicArrows[4].setIntensity(F5);
    
    [self.sliderValLabel setText:[NSString stringWithFormat:@"Ss=%.2f S1=%.2f", Ss, S1]];
    
    size_t resolution = fullDeflVals[0].size();
    for (int i = 0; i < resolution; ++i) {
        double x = fullDeflVals[0][i] - fullDeflVals[0][0];
        double x2 = x * x;
        double defl_sum = 0;
        if (x < 17.75) {
            defl_sum += (53.25 - x) * F1 * x2 / 6;
        }
        else {
            defl_sum += (3*x - 17.75) * 52.5 * F1;
        }
        if (x < 57.5) {
            defl_sum += (172.5 - x) * F2 * x2 / 6;
        }
        else {
            defl_sum += (3*x - 57.5) * 551.04 * F2;
        }
        if (x < 71.5) {
            defl_sum += (214.5 - x) * F3 * x2 / 6;
        }
        else {
            defl_sum += (3*x - 71.5) * 852.04 * F2;
        }
        if (x < 89.2) {
            defl_sum += (267.6 - x) * F4 * x2 / 6;
        }
        else {
            defl_sum += (3*x - 89.2) * 1326.11 * F4;
        }
        if (x < 109.54) {
            defl_sum += (328.62 - x) * F5 * x2 / 6;
        }
        else {
            defl_sum += (3*x - 109.54) * 1999.84 * F5;
        }
        double defl_ft = defl_sum / (MOD_ELASTICITY * MOM_OF_INERTIA);
        fullDeflVals[1][i] = defl_ft;
    }
}

- (IBAction)scenarioChanged:(id)sender {
    switch ([self.scenarioToggle selectedSegmentIndex]) {
        case 0:
            activeScenario = wind;
            shearArrow.setInputRange(0, 66);
            towerL.setMagnification(500);
            towerR.setMagnification(500);
            axialArrow.setHidden(false);
            momentIndicator.setHidden(false);
            windwardSideLoad.setHidden(false);
            for (GrabbableArrow& arrow : seismicArrows) {
                arrow.setHidden(true);
            }
            [self.sliderLabel setText:@"Wind Speed"];
            break;
        case 1:
            activeScenario  = seismic;
            shearArrow.setInputRange(0, 2000);
            towerL.setMagnification(8000);
            towerR.setMagnification(8000);
            axialArrow.setHidden(true);
            momentIndicator.setHidden(true);
            windwardSideLoad.setHidden(true);
            for (GrabbableArrow& arrow : seismicArrows) {
                arrow.setHidden(false);
            }
            [self.sliderLabel setText:@"Intensity"];
            break;
        default:
            assert(false);
            break;
    }
    
    // Trigger re-calculation of forces
    [self.slider sendActionsForControlEvents:UIControlEventValueChanged];
}

// velocity in mph
- (void)calculatePressuresFrom:(double)velocity {
    double v2 = velocity * velocity;
    
    // In pounds / square foot
    pressures.windward_base = 0.000843 * v2;
    pressures.windward_side_top = 0.0014 * v2;
    pressures.leeward_side = -0.00093 * v2;
    pressures.windward_roof = 0.00128 * v2;
    pressures.leeward_roof = -0.00112 * v2;
}
@end
