//
//  CampanileScene.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 1/9/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#include "CampanileScene.h"

#include "VuforiaARManager.h"
#include "StaticARManager.h"

@implementation CampanileScene

static const float base_width = 16;
static const float base_height = 89 + 2.f / 12;
static const float roof_height = 20 + 4.5 / 12;
static const float roof_angle = 1.1965977338;

- (id)initWithController:(id<ARViewController>)controller {
    managingParent = controller;
    return [self init];
}

- (SCNNode *)createScene:(SCNView *)the_scnView skScene:(SKScene *)skScene withCamera:(SCNNode *)camera {
    scnView = the_scnView;
    cameraNode = camera;
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
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.8;
    [rootNode addChildNode:ambientLightNode];
    
    float load_min_h = 10; float load_max_h = 35;
    float input_range[2] = {0, 3.5};
    float thickness = 3;

    windwardSideLoad = LoadMarker(5);
    windwardSideLoad.setPosition(GLKVector3Make(-base_width/2, 0, 0));
    windwardSideLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI/2.f, 0, 0, 1));
    windwardSideLoad.setEnds(0, 89 + 2.f/12);

    windwardRoofLoad = LoadMarker(3);
    windwardRoofLoad.setPosition(GLKVector3Make(-base_width/2, base_height, 0));
    windwardRoofLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(roof_angle, 0, 0, 1));
    float roof_length = roof_height / std::sin(roof_angle);
    windwardRoofLoad.setEnds(0, roof_length);
    
    leewardRoofLoad = LoadMarker(3, true);
    leewardRoofLoad.setPosition(GLKVector3Make(base_width/2, base_height, 0));
    leewardRoofLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI - roof_angle, 0, 0, 1));
    leewardRoofLoad.setEnds(0, roof_length);
    
    leewardSideLoad = LoadMarker(5, true);
    leewardSideLoad.setPosition(GLKVector3Make(base_width/2, 0, 0));
    leewardSideLoad.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI/2.f, 0, 0, 1));
    leewardSideLoad.setEnds(0, 89 + 2.f/12);

    std::vector<LoadMarker*> loads = {&windwardSideLoad, &windwardRoofLoad, &leewardSideLoad, &leewardRoofLoad};
    for (LoadMarker* load : loads) {
        load->setScenes(skScene, scnView);
        load->setInputRange(input_range[0], input_range[1]);
        load->setMinHeight(load_min_h);
        load->setMaxHeight(load_max_h);
        load->setThickness(thickness);
        load->addAsChild(rootNode);
        load->setLoad(0.5);
    }
    
    shearArrow.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    shearArrow.setPosition(GLKVector3Make(0, -5, 0));
    
    shearArrow.setMinLength(load_min_h);
    shearArrow.setMaxLength(load_max_h);
    shearArrow.setInputRange(0, 1);
    shearArrow.setThickness(thickness);
    axialArrow.setMinLength(load_min_h);
    axialArrow.setMaxLength(load_max_h);
    axialArrow.setInputRange(154, 156);
    axialArrow.setThickness(thickness);
    
    shearArrow.setScenes(skScene, scnView);
    axialArrow.setScenes(skScene, scnView);
    shearArrow.addAsChild(rootNode);
    axialArrow.addAsChild(rootNode);

    NSString* momentArrowPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"moment_arrow"] ofType:@"obj"];
    NSURL* momentArrowUrl = [NSURL fileURLWithPath:momentArrowPath];
    MDLAsset* momentArrowAsset = [[MDLAsset alloc] initWithURL:momentArrowUrl];
    momentIndicator = [SCNNode nodeWithMDLObject:[momentArrowAsset objectAtIndex:0]];
    momentIndicator.scale = SCNVector3Make(10, 10, 10);
    SCNMaterial* momentMat = [SCNMaterial material];
    momentMat.diffuse.contents = [UIColor colorWithRed:0.0 green:1.0 blue:0 alpha:1.0];
    momentIndicator.geometry.firstMaterial = momentMat;
    momentIndicator.position = SCNVector3Make(0, -10, 0);
    [rootNode addChildNode:momentIndicator];
    
    return rootNode;
}

- (void)scnRendererUpdate { 
    
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
}

- (void)skUpdate { 
    windwardSideLoad.doUpdate();
    windwardRoofLoad.doUpdate();
    leewardSideLoad.doUpdate();
    leewardRoofLoad.doUpdate();
    shearArrow.doUpdate();
    axialArrow.doUpdate();
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(0, 40, 210);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.3);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_x_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix);
}

- (ARManager*)makeIndoorTracker {
    return nullptr;
}

- (ARManager*)makeOutdoorTracker {
    return nullptr;
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
    // TODO
//    [managingParent freezePressed:sender freezeBtn:self.freezeFrameBtn curtain:self.processingCurtainView];
}

- (IBAction)homeBtnPressed:(id)sender {
    return [managingParent homeBtnPressed:sender];
}

- (IBAction)trackingModeChanged:(id)sender {
    enum TrackingMode new_mode = static_cast<TrackingMode>(self.trackingModeBtn.selectedSegmentIndex);
    // temporarily disable button to indicate we are switching
    self.trackingModeBtn.enabled = NO;
    
    [managingParent setTrackingMode:new_mode];
    [self setCameraLabelPaused:NO];
    
    self.trackingModeBtn.enabled = YES;
}

- (IBAction)windSpeedChanged:(id)sender {
    float slider_val = self.windSpeedSlider.value;
    float v = slider_val * 50;
    [self calculatePressuresFrom:v];
    
    // Set intensities
    windwardSideLoad.setLoadInterpolate(pressures.windward_base, pressures.windward_side_top);
    windwardRoofLoad.setLoad(pressures.windward_roof);
    leewardRoofLoad.setLoad(-pressures.leeward_roof);
    leewardSideLoad.setLoad(-pressures.leeward_side);
    
    // breakdown roof pressures into components

    // convenience
    const double h1 = base_height;
    const double h2 = roof_height;
    const double ww1 = pressures.windward_base;
    const double ww2 = pressures.windward_side_top;
    const double wd1 = pressures.windward_roof;
    const double wd2 = pressures.leeward_roof;
    const double wl = pressures.leeward_side;
    
    double cos_theta = std::cos(roof_angle);
    double sin_theta = std::sin(roof_angle);
//    double wd1h = cos_theta * wd1;
//    double wd1v = sin_theta * wd1;
//    double wd2h = cos_theta * wd2;
//    double wd2v = sin_theta * wd2;
    
    double h1_2 = h1*h2;
    // Calculate shear, axial, and moment
    double shear = (16./1000) * (h1*(ww1/2 + ww2/2 + wl) * h2 * (cos_theta/sin_theta) * (wd1 + wd2));
    double axial = (16./1000) * h2 * (wd1 - wd2) + 154;
    double moment = (16./1000) *
        (h1_2/2 * (ww1 + wl) +
         h1_2/2 * (ww2 - ww1) +
         h2 * (cos_theta/sin_theta) * (wd1 + wd2) * (h1 + h2/2));
    
    // Update indicators
    shearArrow.setIntensity(shear);
    axialArrow.setIntensity(axial);
    double moment_scale = 1;
    double min_moment_scale = 10;
    momentIndicator.scale = SCNVector3Make(min_moment_scale + moment_scale * moment, min_moment_scale + moment_scale * moment, min_moment_scale + moment_scale * moment);
}

// velocity in mph
- (void)calculatePressuresFrom:(double)velocity {
    double v2 = velocity * velocity;
    
    // In pounds / square foot
    pressures.windward_base = 0.000843 * v2;
    pressures.windward_side_top = 0.0014 * v2;
    pressures.leeward_side = -0.00093 * v2;
    pressures.windward_roof = 0.00128 * v2;
    pressures.leeward_roof = -0.0012 * v2;
}

@end
