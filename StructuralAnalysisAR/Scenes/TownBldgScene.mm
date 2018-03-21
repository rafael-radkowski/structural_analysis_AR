//
//  TownBldgScene.mm
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

// must include cvARManager.h before others, because it includes openCV headers
#include "cvARManager.h"
#include "TownBldgScene.h"

#include "VuforiaARManager.h"
#include "StaticARManager.h"

#include <random>
#include <vector>

using namespace TownCalcs;

@implementation TownBldgScene

- (id)initWithController:(id<ARViewController>)controller {
    managingParent = controller;
    return [self init];
}

- (SCNNode *)createScene:(SCNView *)the_scnView skScene:(SKScene *)the_skScene withCamera:(SCNNode *)camera {
    scnView = the_scnView;
    skScene = the_skScene;
    cameraNode = camera;
    SCNNode* rootNode = [SCNNode node];
    
    // ---------------- Lighting ---------------- //
    
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
    
    
    // ---------------- 2D joints ---------------- //
    
    float jointBoxWidth = 300;
    float jointBoxHeight = 500;
    jointBox = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, jointBoxWidth, jointBoxHeight)];
    jointBox.strokeColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    jointBox.fillColor = [UIColor colorWithWhite:0.8 alpha:0.5];
    jointBox.position = CGPointMake(scnView.frame.size.width - jointBoxWidth - 50, 200);
    jointBox.zPosition = -1; // Don't cover other nodes
    // make title for joint box
    SKLabelNode* jointBoxTitle = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    jointBoxTitle.text = @"Fixed Joint Forces";
    jointBoxTitle.position = CGPointMake(150, jointBoxHeight - jointBoxTitle.fontSize - 3);
    jointBoxTitle.fontColor = [UIColor blackColor];
    [jointBox addChild:jointBoxTitle];
    // make underline for title
    CGPoint titlePoints[2] = {CGPointMake(0, 0), CGPointMake(jointBoxWidth, 0)};
    SKShapeNode* titleUnderline = [SKShapeNode shapeNodeWithPoints:titlePoints count:2];
    titleUnderline.strokeColor = [UIColor blackColor];
    titleUnderline.position = CGPointMake(0, jointBoxHeight - jointBoxTitle.fontSize - 6);
    [jointBox addChild:titleUnderline];
    
    cornerE = [[SKCornerNode alloc] initWithTextUp:NO];
    [cornerE setPosition:CGPointMake(200, 200)];
    cornerB = [[SKCornerNode alloc] init];
    [cornerB setPosition:CGPointMake(100, 420)];
    [cornerE setInputRange:-1 max:1];
    [cornerE setLengthRange:5 max:40];
    
    [jointBox addChild:cornerE];
    [jointBox addChild:cornerB];
    [skScene addChild:jointBox];
    
    
    // ---------------- Load Markers ---------------- //
    float thickness = 1.7;
    liveLoad = LoadMarker(3, false, 1, 2.0);
    liveLoad.setPosition(GLKVector3Make(0, Calculator::height, 0));
    liveLoad.setInputRange(0, 2.5);
    liveLoad.setMinHeight(7);
    liveLoad.setMaxHeight(15);
    liveLoad.setEnds(0, Calculator::width * 2);
    liveLoad.setThickness(thickness);
    liveLoad.addAsChild(rootNode);
    liveLoad.setScenes(skScene, scnView);
    
    sideLoad = GrabbableArrow(2.0);
    sideLoad.setPosition(GLKVector3Make(0, Calculator::height, 0));
    sideLoad.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
    sideLoad.setThickness(thickness);
    sideLoad.setInputRange(0, 8.65);
    sideLoad.setMinLength(5);
    sideLoad.setMaxLength(15);
    sideLoad.addAsChild(rootNode);
    sideLoad.setScenes(skScene, scnView);
    sideLoad.setFormatString(@"%.1f k");
    
    // beams
    constexpr int res = 3;
    std::vector<std::vector<float>> horiz_vals(2), vert_vals(2);
    constexpr double horiz_step = Calculator::width / (res - 1);
    constexpr double vert_step = Calculator::height / (res - 1);
    for (int i = 0; i < res; ++i) {
        horiz_vals[0].push_back(horiz_step * i);
        vert_vals[0].push_back(vert_step * i);
        horiz_vals[1].push_back(0);
        vert_vals[1].push_back(0);
    }
    GLKQuaternion vert_ori = GLKQuaternionMakeWithAngleAndAxis(M_PI/2, 0, 0, 1);
    line_AB = BezierLine(vert_vals);
    line_AB.setOrientation(vert_ori);
    line_DC = BezierLine(vert_vals);
    line_DC.setPosition(GLKVector3Make(Calculator::width, 0, 0));
    line_DC.setOrientation(vert_ori);
    line_FE = BezierLine(vert_vals);
    line_FE.setPosition(GLKVector3Make(2 * Calculator::width, 0, 0));
    line_FE.setOrientation(vert_ori);
    line_BC = BezierLine(horiz_vals);
    line_BC.setPosition(GLKVector3Make(0, Calculator::height, 0));
    line_CE = BezierLine(horiz_vals);
    line_CE.setPosition(GLKVector3Make(Calculator::width, Calculator::height, 0));

    std::vector<BezierLine*> beams = {&line_AB, &line_DC, &line_FE, &line_BC, &line_CE};
    for (BezierLine* beam : beams) {
        beam->addAsChild(rootNode);
        beam->setThickness(0.5);
    }
    
    line_AB.addAsChild(rootNode);
    line_DC.addAsChild(rootNode);
    
    
    F_FE.setPosition(GLKVector3Make(Calculator::width * 2, 0, 0));
    V_FE.setPosition(GLKVector3Make(Calculator::width * 2, 0, 0));
    V_AB.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    V_FE.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
    F_AB.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    F_FE.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));

    std::vector<GrabbableArrow*> rcn_arrows = {&F_AB, &F_FE, &V_AB, &V_FE};
    for (GrabbableArrow* arrow : rcn_arrows) {
        arrow->setThickness(thickness);
        arrow->setScenes(skScene, scnView);
        arrow->addAsChild(rootNode);
        arrow->setInputRange(0, 100);
        arrow->setFormatString(@"%.1f k");
        arrow->setMinLength(5);
        arrow->setMaxLength(15);
    }
    
    calc_inputs.D = 3;
    
    // default loads
    liveLoad.setLoad(0);
    deadLoad.setLoad(3);
    sideLoad.setIntensity(3);
    return rootNode;
}

- (void)scnRendererUpdateAt:(NSTimeInterval)time {
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
    [[NSBundle mainBundle] loadNibNamed:@"townBldgView" owner:self options: nil];
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
}

- (void)skUpdate {
    liveLoad.doUpdate();
    sideLoad.doUpdate();
//    std::vector<BezierLine*> beams = {&line_AB, &line_DC, &line_FE, &line_BC, &line_CE};
//    for (BezierLine* beam : beams) {
    std::vector<GrabbableArrow*> rcn_arrows = {&F_AB, &F_FE, &V_AB, &V_FE};
    for (GrabbableArrow* arrow : rcn_arrows) {
        arrow->doUpdate();
    }
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(37, 7, 110);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.33);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_x_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"town_static.png");
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

- (CGPoint)convertTouchToSKScene:(CGPoint)scnViewPt {
    // touch point in SkScene.view coordinate system
    CGPoint pointSkView = [scnView convertPoint:scnViewPt toView:skScene.view];
    // touch point in skScene coordinate system
    CGPoint pointSkScene = [skScene convertPointFromView:pointSkView];
    return pointSkScene;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    
    // ------ 3D Touch Handling ------ //
    liveLoad.touchBegan(SCNVector3ToGLKVector3(cameraNode.position), farClipHit);
    sideLoad.touchBegan(SCNVector3ToGLKVector3(cameraNode.position), farClipHit);
    
    // ------ 2D Touch Handling ------ //
    CGPoint pointSkScene = [self convertTouchToSKScene:p];
    if ([jointBox containsPoint:pointSkScene]) {
        draggingJointBox = true;
        lastDragPt = pointSkScene;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // ------ 3D Touch Handling ------ //
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));
    
    if (liveLoad.draggingMode() != LoadMarker::none) {
        float dragValue = liveLoad.getDragValue(cameraPos, touchRay);
        liveLoad.setLoad(dragValue);
        std::pair<float, float> sideDragPosition = liveLoad.getDragPosition(cameraPos, touchRay);
        // Limit left to the range of [0, width*2 - 2]
        sideDragPosition.first = std::min<float>(std::max<float>(0, sideDragPosition.first), Calculator::width*2 - 2);
        // Limit right to the range of [2, width*2 - 2]
        sideDragPosition.second = std::max<float>(std::min<float>(Calculator::width*2, sideDragPosition.second), 2);
        // Dont let bar collapse
        if (sideDragPosition.second - sideDragPosition.first >= 5) {
            liveLoad.setEnds(sideDragPosition.first, sideDragPosition.second);
    //        [self updateBeamForces];
        }
        calc_inputs.x1 = sideDragPosition.first;
        calc_inputs.x2 = sideDragPosition.second;
        calc_inputs.L = dragValue;
    }
    
    if (sideLoad.dragging) {
        GLKVector3 cameraDir = GLKVector3Make(cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
        float dragValue = sideLoad.getDragValue(cameraPos, touchRay, cameraDir);
        sideLoad.setIntensity(dragValue);
        calc_inputs.F = dragValue;
    }
    
    [self updateForces];
    
    // ------ 2D Touch Handling ------ //
    CGPoint pointSkScene = [self convertTouchToSKScene:p];
    if (draggingJointBox) {
        CGPoint moved = CGPointMake(pointSkScene.x - lastDragPt.x, pointSkScene.y - lastDragPt.y);
        CGPoint newPos = CGPointMake(jointBox.position.x + moved.x, jointBox.position.y + moved.y);
        // keep box within scene
        newPos.x = std::min(std::max(0., newPos.x), skScene.size.width - jointBox.frame.size.width);
        newPos.y = std::min(std::max(self.bottomBarView.frame.size.height, newPos.y), skScene.size.height - jointBox.frame.size.height);
        // blah testing stuff
        jointBox.position = newPos;
        lastDragPt = pointSkScene;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    liveLoad.touchCancelled();
    sideLoad.touchCancelled();
    
    draggingJointBox = false;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    liveLoad.touchEnded();
    sideLoad.touchEnded();
    
    draggingJointBox = false;
}

- (IBAction)freezePressed:(id)sender {
    [managingParent freezePressed:sender freezeBtn:self.freezeFrameBtn curtain:self.processingCurtainView];
}

- (IBAction)visToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
}

- (IBAction)screenshotBtnPressed:(id)sender {
    return [managingParent screenshotBtnPressed:sender infoBox:self.screenshotInfoBox];
}

- (IBAction)homeBtnPressed:(id)sender {
    return [managingParent homeBtnPressed:sender];
}

- (IBAction)changeTrackingBtnPressed:(id)sender {
    CGRect frame = [self.changeTrackingBtn.superview convertRect:self.changeTrackingBtn.frame toView:scnView];
    [managingParent changeTrackingMode:frame];
}

- (void)updateForces {
//    calc_inputs.L = 2.5;
//    calc_inputs.x1 = 16.8;
//    calc_inputs.x2 = 30;
//    calc_inputs.F = 5.62 * 0.985;
    Output_t results = Calculator::calculate(calc_inputs);
    F_AB.setIntensity(results.F_AB);
    V_AB.setIntensity(results.V_AB);
    F_FE.setIntensity(results.F_FE);
    V_FE.setIntensity(results.V_FE);
    
    double rot_scale = 400;
    cornerB.zRotation = -M_PI/2 + results.theta_B * rot_scale;
    cornerE.zRotation = M_PI + results.theta_E * rot_scale;
}

@end
