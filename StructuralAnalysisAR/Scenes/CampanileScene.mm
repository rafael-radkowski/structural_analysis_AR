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

#include <random>

@implementation CampanileScene

static const float base_width = 16;
static const float base_height = 89 + 2.f / 12;
static const float roof_height = 20 + 4.5 / 12;
static const float roof_angle = (M_PI / 180.0) * 68.56;

static const float f1_h = 17.75;
static const float f2_h = 57.5;
static const float f3_h = 71.5;
static const float f4_h = base_height;

static const float max_vel = 150;

static const float shear_max = 150;
static const float sideload_max = 150;
static const float moment_max = 10000;
static const float defl_magnification = 200;
static const float axial_max = 4000;
static const float seismic_scale_fac = 10;

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
    campanileInterior = loadModel(@"campanile_interior");
    campanileExterior = loadModel(@"campanile_exterior");
//    SCNNode* campanileExteriorWarped = loadModel(@"warped_campanile");
    [rootNode addChildNode:campanileExterior];
    [rootNode addChildNode:campanileInterior];
    SCNMaterial* campanileMatClear = [SCNMaterial material];
    SCNMaterial* campanileMatOpaque = [SCNMaterial material];
    campanileMatClear.diffuse.contents = [UIColor colorWithRed:1.0 green:0.68 blue:0.478 alpha:0.3];
    campanileMatOpaque.diffuse.contents = [UIColor colorWithRed:1.0 green:0.68 blue:0.478 alpha:1.0];
    campanileExterior.geometry.firstMaterial = campanileMatClear;
    // Needed for semi-transparent objects to render correctly
    campanileExterior.geometry.firstMaterial.writesToDepthBuffer = NO;
    campanileInterior.geometry.firstMaterial = campanileMatOpaque;
//    campanileExterior.opacity = 0.5;
//    campanileInterior.opacity = 0.6;
    // Force a rendering order, otherwise the interior does not appear
    campanileInterior.renderingOrder = 50;
    campanileExterior.renderingOrder = 100;
//    MDLObject* exterior = [modelAsset objectAtPath:@"exterior_Basic_Wall_Generic_-_12__Masonry__Brick___527010__Geometry"];
    
//    campanileExterior.morpher = [[SCNMorpher alloc] init];
//    campanileExterior.morpher.targets = [NSArray arrayWithObject:campanileExteriorWarped.geometry];

    float load_min_h = 10; float load_max_h = 55;
    float thickness = 3;

    windwardSideLoad = LoadMarker(7, false, 2, 4);
    windwardSideLoad.setPosition(GLKVector3Make(-base_width/2, 0, 0));
    windwardSideLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI/2.f, 0, 0, 1));
    windwardSideLoad.setEnds(0, base_height);

    windwardSideLoad.setScenes(skScene, scnView);
    windwardSideLoad.setFormatString(@"%.1f psf");
    windwardSideLoad.setInputRange(0, sideload_max);
    windwardSideLoad.setMinHeight(load_min_h);
    windwardSideLoad.setMaxHeight(load_max_h);
    windwardSideLoad.setThickness(thickness);
    windwardSideLoad.addAsChild(rootNode);
    windwardSideLoad.setLoad(0.5);

    // shear reaction force
    shearArrow.setPosition(GLKVector3Make(0, -5, 0));
    shearArrow.setColor(0, 1, 0);
    shearArrow.setMinLength(load_min_h);
    shearArrow.setMaxLength(load_max_h);
    shearArrow.setThickness(thickness);
    // axial reaction force
    axialArrow.setMinLength(load_min_h);
    axialArrow.setMaxLength(load_max_h);
    axialArrow.setIntensity(1400);
    axialArrow.setThickness(thickness);
    axialArrow.setColor(0, 1, 0);
    axialArrow.setLabelFollow(false);
    axialArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    // dead load
    deadLoad.setPosition(GLKVector3Make(0, base_height, 0));
    deadLoad.setMinLength(load_min_h);
    deadLoad.setMaxLength(load_max_h);
    deadLoad.setIntensity(1400);
    deadLoad.setThickness(thickness);

    shearArrow.setFormatString(@"%.0f k");
    axialArrow.setFormatString(@"%.0f k");
    deadLoad.setFormatString(@"%.0f k");
    
    shearArrow.setScenes(skScene, scnView);
    axialArrow.setScenes(skScene, scnView);
    deadLoad.setScenes(skScene, scnView);
    shearArrow.addAsChild(rootNode);
    axialArrow.addAsChild(rootNode);
    deadLoad.addAsChild(rootNode);

    momentIndicator.addAsChild(rootNode);
    momentIndicator.setThickness(thickness);
    momentIndicator.setRadius(18);
    momentIndicator.setColor(0, 1, 0);
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
    for (int i = 0; i < 4; i++) {
        seismicArrows.emplace_back();
        seismicArrows[i].addAsChild(rootNode);
        seismicArrows[i].setInputRange(10, sideload_max * seismic_scale_fac);
        seismicArrows[i].setMinLength(load_min_h);
        seismicArrows[i].setMaxLength(load_max_h);
        seismicArrows[i].setThickness(thickness);
        seismicArrows[i].setScenes(skScene, scnView);
        seismicArrows[i].setFormatString(@"%.2f k");
        seismicArrows[i].setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    }
    seismicArrows[0].setPosition(GLKVector3Make(base_width/2, f1_h, 0));
    seismicArrows[1].setPosition(GLKVector3Make(base_width/2, f2_h, 0));
    seismicArrows[2].setPosition(GLKVector3Make(base_width/2, f3_h, 0));
    seismicArrows[3].setPosition(GLKVector3Make(base_width/2, f4_h, 0));

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
//    static float phase = 0;
//    float weight = 0.5 * (std::sin(phase) + 1);
//    phase += 0.02;
//    [campanileExterior.morpher setWeight:weight forTargetAtIndex:0];
}

- (void)setCameraLabelPaused:(bool)isPaused isEnabled:(bool)enabled {
    if (isPaused) {
        [self.freezeFrameBtn setTitle:@"Resume Camera" forState:UIControlStateNormal];
    }
    else {
        [self.freezeFrameBtn setTitle:@"Pause Camera" forState:UIControlStateNormal];
    }
    self.freezeFrameBtn.enabled = enabled;
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
    
    // Setup screenshot button style
    self.screenshotBtn.layer.borderWidth = 1.5;
    self.screenshotBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.screenshotBtn.layer.borderColor = textColor;
    self.screenshotBtn.layer.cornerRadius = 5;
    
    // Setup screenshot info box
    self.screenshotInfoBox.layer.cornerRadius = self.screenshotInfoBox.bounds.size.height / 2;
    
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
    
    // seismic spectral plot image
//    self.plotImgView.layer.borderWidth = 2;
//    self.plotImgView.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1].CGColor;
    plotVisible = false;
    
    self.seismicPlotBtn.layer.borderWidth = 1.5;
    self.seismicPlotBtn.layer.borderColor = UIColor.grayColor.CGColor;
    self.plotViewBox.layer.borderWidth = 1.5;
    self.plotViewBox.layer.borderColor = UIColor.grayColor.CGColor;
    self.plotHeight.constant = 50;
    self.fundFreqLabel.layer.borderWidth = 1.5;
    self.fundFreqLabel.layer.borderColor = UIColor.grayColor.CGColor;
    
    
    // Set initial wind speed and notify so callback gets called
    [self.slider setValue:0.5];
    [self.scenarioToggle sendActionsForControlEvents:UIControlEventValueChanged];
    [self setVisibilities];
    
//    breakerThread = std::thread([self] () {
//        using namespace std::chrono_literals;
//        std::random_device rnd_dev;
//        std::uniform_real_distribution<float> dist(0, 1);
//        std::mt19937 generator(rnd_dev());
//        while(1) {
//            @autoreleasepool {
//                float val = dist(generator);
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    [self.slider setValue:val];
//                    [self.slider sendActionsForControlEvents:UIControlEventValueChanged];
//                }];
//            }
//            std::this_thread::sleep_for(20ms);
//        }
//    });
}

- (void)skUpdate {
    windwardSideLoad.doUpdate();
    shearArrow.doUpdate();
    axialArrow.doUpdate();
    deadLoad.doUpdate();
    towerL.doUpdate();
    towerR.doUpdate();
    momentIndicator.doUpdate();
    for (GrabbableArrow& arrow : seismicArrows) {
        arrow.doUpdate();
    }
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(0, 40, 230);
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
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);

    windwardSideLoad.touchBegan(SCNVector3ToGLKVector3(cameraNode.position), farClipHit);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));

    if (windwardSideLoad.draggingMode() & LoadMarker::vertically) {
        float dragValue = windwardSideLoad.getDragValue(cameraPos, touchRay);
        // calculate wind velocity from dragged value
        double height_frac = windwardSideLoad.getDragPoint(cameraPos, touchRay) / base_height;
        double a = 0.000843;
        double b = 0.0014;
        double c = -0.00093;
        double v2 = dragValue / ((1. - height_frac)*a + height_frac*b - c);
        double v = std::sqrt(v2);
        [self.slider setValue:(v / max_vel)];
        [self updateForces];
        // Set intensities
        windwardSideLoad.setLoadInterpolate(pressures.windward_base - pressures.leeward_side, pressures.windward_side_top - pressures.leeward_side);
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    windwardSideLoad.touchCancelled();
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    windwardSideLoad.touchEnded();
}

- (void)updateForces {
    float slider_val = self.slider.value;
    switch (activeScenario) {
        case wind: {
            double vel = slider_val * max_vel;
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
            // do animation since seismic is in discrete steps
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.3];
            [self calculateForcesSeismic:closest_idx];
            [SCNTransaction commit];
            
            // Set deflection if not animating
            if (!do_animations) {
                towerL.updatePath(fullDeflVals);
                towerR.updatePath(fullDeflVals);
            }
            
            // set spectral plot image
            NSArray* img_names = @[@"0.05.png", @"0.25.png", @"0.5.png", @"0.75.png", @"1.0.png", @"1.25.png", @"2.0.png", @"3.0.png"];
            self.plotImgView.image = [UIImage imageNamed:img_names[closest_idx]];
            break;
        }
        default: {
            assert(false);
            break;
        }
    }
}

- (IBAction)freezePressed:(id)sender {
    [managingParent freezePressed:sender freezeBtn:self.freezeFrameBtn curtain:self.processingCurtainView];
}

- (IBAction)visToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
    do_animations = self.swayVisSwitch.on;
    if (!do_animations) {
        // Just toggled off. set towers to max deflections
        towerL.updatePath(fullDeflVals);
        towerR.updatePath(fullDeflVals);
    }
    campanileInterior.hidden = !self.modelVisSwitch.on;
    campanileExterior.hidden = !self.modelVisSwitch.on;
}

- (IBAction)screenshotBtnPressed:(id)sender {
    return [managingParent screenshotBtnPressed:sender infoBox:self.screenshotInfoBox];
}

- (IBAction)plotBtnPressed:(id)sender {
    plotVisible = !plotVisible;
    if (plotVisible) {
        self.plotHeight.constant = 330;
        self.seismicPlotArrow.transform = CGAffineTransformMakeRotation(M_PI);
    }
    else {
        self.plotHeight.constant = 50;
        self.seismicPlotArrow.transform = CGAffineTransformMakeRotation(0);
    }
    [UIView animateWithDuration:0.3 animations:^{
        [scnView layoutIfNeeded];
    }];
}

- (IBAction)homeBtnPressed:(id)sender {
    return [managingParent homeBtnPressed:sender];
}

- (IBAction)changeTrackingBtnPressed:(id)sender {
    CGRect frame = [self.changeTrackingBtn.superview convertRect:self.changeTrackingBtn.frame toView:scnView];
    [managingParent changeTrackingMode:frame];
}

- (IBAction)sliderChanged:(id)sender {
    [self updateForces];
    
    // Set intensities
    windwardSideLoad.setLoadInterpolate(pressures.windward_base - pressures.leeward_side, pressures.windward_side_top - pressures.leeward_side);
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
    double moment = (16./1000) *
        (h1_2/2 * (ww1 + wl) +
         h1_2/2 * (ww2 - ww1));

    // Update indicators
    shearArrow.setIntensity(shear);
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
    const double V_vals[8]= {44.76, 223.8, 373, 503.55, 596.8, 699.37, 1118.99, 1678.49};
    const double F1_vals[8]= {0.74, 3.72, 6.19, 8.36, 9.91, 11.61, 18.58, 27.87};
    const double F2_vals[8]= {8.69, 43.43, 72.39, 97.73, 115.82, 135.73, 217.17, 325.76};
    const double F3_vals[8]= {13.66, 68.29, 113.81, 153.64, 182.1, 213.39, 341.43, 512.14};
    const double F4_vals[8]= {21.67, 108.36, 180.6, 243.81, 288.96, 338.63, 541.81, 812.71};

    double F1 = F1_vals[scale_idx];
    double F2 = F2_vals[scale_idx];
    double F3 = F3_vals[scale_idx];
    double F4 = F4_vals[scale_idx];
    double V = V_vals[scale_idx];
    double Ss = Ss_vals[scale_idx];
    double S1 = S1_vals[scale_idx];
    
    shearArrow.setIntensity(V);
    seismicArrows[0].setIntensity(F1);
    seismicArrows[1].setIntensity(F2);
    seismicArrows[2].setIntensity(F3);
    seismicArrows[3].setIntensity(F4);

    float moment = f1_h*F1 + f2_h*F2 + f3_h*F3 + f4_h*F4;
    momentIndicator.setIntensity(moment);
    
    [self.sliderValLabel setText:[NSString stringWithFormat:@"Ss=%.2f S1=%.2f", Ss, S1]];
    
    size_t resolution = fullDeflVals[0].size();
    for (int i = 0; i < resolution; ++i) {
        double x = fullDeflVals[0][i] - fullDeflVals[0][0];
        double x2 = x * x;
        double defl_sum = 0;
        if (x < f1_h) {
            defl_sum += (53.25 - x) * F1 * x2 / 6;
        }
        else {
            defl_sum += (3*x - f1_h) * 52.5 * F1;
        }
        if (x < f2_h) {
            defl_sum += (172.5 - x) * F2 * x2 / 6;
        }
        else {
            defl_sum += (3*x - f2_h) * 551.04 * F2;
        }
        if (x < f3_h) {
            defl_sum += (214.5 - x) * F3 * x2 / 6;
        }
        else {
            defl_sum += (3*x - f3_h) * 852.04 * F3;
        }
        if (x < f4_h) {
            defl_sum += (267.6 - x) * F4 * x2 / 6;
        }
        else {
            defl_sum += (3*x - f4_h) * 1326.11 * F4;
        }
//        if (x < 109.54) {
//            defl_sum += (328.62 - x) * F5 * x2 / 6;
//        }
//        else {
//            defl_sum += (3*x - 109.54) * 1999.84 * F5;
//        }
        double defl_ft = 1000 * defl_sum / (MOD_ELASTICITY * MOM_OF_INERTIA);
        fullDeflVals[1][i] = defl_ft;
    }
}

- (IBAction)scenarioChanged:(id)sender {
    switch ([self.scenarioToggle selectedSegmentIndex]) {
        case 0:
            activeScenario = wind;
            shearArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
            shearArrow.setInputRange(0, shear_max);
            axialArrow.setInputRange(0, axial_max);
            deadLoad.setInputRange(0, axial_max);
            towerL.setMagnification(defl_magnification);
            towerR.setMagnification(defl_magnification);
            momentIndicator.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
            momentIndicator.setInputRange(-100, moment_max);
            windwardSideLoad.setHidden(false);
            for (GrabbableArrow& arrow : seismicArrows) {
                arrow.setHidden(true);
            }
            [self.sliderLabel setText:@"Wind Speed"];
            [self.swayVisSwitch setEnabled:NO];
            self.plotViewBox.hidden = YES;
            self.scaleLabel.text = @"100%";
            break;
        case 1:
            activeScenario  = seismic;
            shearArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
            shearArrow.setInputRange(0, shear_max * seismic_scale_fac);
            axialArrow.setInputRange(0, axial_max * seismic_scale_fac);
            deadLoad.setInputRange(0, axial_max * seismic_scale_fac);
            towerL.setMagnification(defl_magnification / seismic_scale_fac);
            towerR.setMagnification(defl_magnification / seismic_scale_fac);
            momentIndicator.setRotationAxisAngle(GLKVector4Make(1, 0, 0, M_PI));
            momentIndicator.setInputRange(-100, moment_max * seismic_scale_fac);
            windwardSideLoad.setHidden(true);
            for (GrabbableArrow& arrow : seismicArrows) {
                arrow.setHidden(false);
            }
            [self.sliderLabel setText:@"Intensity"];
            [self.swayVisSwitch setEnabled:YES];
            self.plotViewBox.hidden = NO;
            self.scaleLabel.text = @"10%";
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
