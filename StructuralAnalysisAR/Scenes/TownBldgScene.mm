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

#import <Analytics/SEGAnalytics.h>
#import "TrackingConstants.h"

#include <random>
#include <vector>

using namespace TownCalcs;

// y-position for front occlusion plane
constexpr static float ocPlnPosY = -7.5;

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
    addLight(100, 50, 80, 400);
    addLight(0, 50, 50, 300);
    addLight(00, 0, 55, 400);
    
    // create and add an ambient light to the scene
//    SCNNode *ambientLightNode = [SCNNode node];
//    ambientLightNode.light = [SCNLight light];
//    ambientLightNode.light.type = SCNLightTypeAmbient;
//    ambientLightNode.light.color = [UIColor darkGrayColor];
//    ambientLightNode.light.intensity = 0.8;
//    [rootNode addChildNode:ambientLightNode];
    
    
    // ---------------- 3D model ---------------- //
    NSString* townModelPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"town_model"] ofType:@"obj"];
    NSURL* townModelUrl = [NSURL fileURLWithPath:townModelPath];
    MDLAsset* townModelAsset = [[MDLAsset alloc] initWithURL:townModelUrl];
    townModel = [SCNNode nodeWithMDLObject:[townModelAsset objectAtIndex:0]];
    SCNMaterial* modelMat = [SCNMaterial material];
    modelMat.diffuse.contents = [UIColor colorWithRed:0.836 green:0.7744 blue:0.7 alpha:0.4];
//    modelMat.transparent.contents = [UIColor colorWithWhite:0.5 alpha:1.0];
//    modelMat.lightingModelName = SCNLightingModelLambert;
//    printf("%lu materials\n", [townModel.geometry.materials count]);
//    printf("%lu geom elements\n", [townModel.geometry.geometryElements count]);
    for (int i = 0; i < [townModel.geometry.materials count]; ++i) {
//        townModel.geometry.materials[i] = modelMat;
        [townModel.geometry replaceMaterialAtIndex:i withMaterial:modelMat];
    }
    // Needed for semi-transparent objects to render correctly
//    townModel.geometry.firstMaterial.writesToDepthBuffer = NO;
//    townModel.rotation = SCNVector4Make(0, 1, 0, M_PI / 2);
//    townModel.position = SCNVector3Make(66, -15, -55.7);
    townModel.renderingOrder = -10;
    [rootNode addChildNode:townModel];
    
    // occlusion plane
    auto makeOcclPlane = [] () {
        SCNPlane* occlusionGeom = [SCNPlane planeWithWidth:200 height:50];
        SCNNode* occlPlane = [SCNNode nodeWithGeometry:occlusionGeom];
        //    occlusionPlane.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
        occlPlane.geometry.firstMaterial = [SCNMaterial material];
        occlPlane.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
        occlPlane.renderingOrder = -100;
        occlPlane.geometry.firstMaterial.writesToDepthBuffer = YES;
        
        if (@available(iOS 11.0, *)) {
            occlPlane.geometry.firstMaterial.colorBufferWriteMask = SCNColorMaskAlpha;
        } else {
            //        frontOcclPlane.geometry.firstMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:1.0];
            occlPlane.opacity = 0.00001;
        }
        return occlPlane;
    };
    
    frontOcclPlane = makeOcclPlane();
//    sideOcclPlane = makeOcclPlane();
//    sideOcclPlane.position = SCNVector3Make(0, -planeHeight/2 + ocPlnPosUntracked, 0.1);
    
    [rootNode addChildNode:frontOcclPlane];
    
    
    // ---------------- 2D joints ---------------- //
    
    float jointBoxWidth = 300;
    float jointBoxHeight = 585;
    jointBox = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, jointBoxWidth, jointBoxHeight)];
    jointBox.strokeColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    jointBox.fillColor = [UIColor colorWithWhite:0.8 alpha:0.5];
    jointBox.position = CGPointMake(scnView.frame.size.width - jointBoxWidth - 50, scnView.frame.size.height - jointBoxHeight - 50);
    jointBox.zPosition = -1; // Don't cover other nodes
    // Dark background behind title
    float titleBoxHeight = 40;
    SKShapeNode* jointBoxTitleBg = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, jointBoxWidth, titleBoxHeight)];
    jointBoxTitleBg.fillColor = [UIColor colorWithWhite:0.45 alpha:1.0];
    jointBoxTitleBg.strokeColor = [UIColor colorWithWhite:0.0 alpha:0.0]; // no stroke
    jointBoxTitleBg.position = CGPointMake(0, jointBoxHeight - titleBoxHeight);
    jointBoxTitleBg.zPosition = 1;
    [jointBox addChild:jointBoxTitleBg];
    // make title for joint box
    SKLabelNode* jointBoxTitle = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    jointBoxTitle.text = @"Fixed Joints";
    jointBoxTitle.fontColor = [UIColor blackColor];
    jointBoxTitle.fontSize = titleBoxHeight - 5;
    jointBoxTitle.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    jointBoxTitle.position = CGPointMake(150, titleBoxHeight / 2);
    jointBoxTitle.zPosition = 1;
    [jointBoxTitleBg addChild:jointBoxTitle];
    // Grip indicator
    SKSpriteNode* gripper = [SKSpriteNode spriteNodeWithImageNamed:@"grip.png"];
    gripper.anchorPoint = CGPointMake(0, 0.5);
    float gripHeight = titleBoxHeight - 6;
    [gripper scaleToSize:CGSizeMake(gripHeight * 2. / 5, gripHeight)];
    gripper.position = CGPointMake(5, titleBoxHeight / 2);
    [jointBoxTitleBg addChild:gripper];
    gripper.zPosition = 2;
    // make underline for title
    CGPoint titlePoints[2] = {CGPointMake(0, 0), CGPointMake(jointBoxWidth, 0)};
    SKShapeNode* titleUnderline = [SKShapeNode shapeNodeWithPoints:titlePoints count:2];
    titleUnderline.strokeColor = [UIColor blackColor];
    titleUnderline.lineWidth = 2;
    titleUnderline.position = CGPointMake(0, jointBoxHeight - titleBoxHeight);
    [jointBox addChild:titleUnderline];
    
    // Fixed joint corners
    cornerB = [[SKCornerNode alloc] init];
    cornerE = [[SKCornerNode alloc] initWithTextUp:NO];
    [cornerB setPosition:CGPointMake(100, 455)];
    [cornerE setPosition:CGPointMake(200, 200)];
    for (SKCornerNode* corner : {cornerB, cornerE}) {
        [corner setInputRangeF:0 max:30];
        [corner setLengthRangeF:5 max:40];
        [corner setInputRangeV:0 max:30];
        [corner setLengthRangeV:5 max:40];
        [corner setInputRangeM:0 max:25];
        [corner setAngleRangeM:0 max:M_PI];
    }
    
    [jointBox addChild:cornerE];
    [jointBox addChild:cornerB];
    [skScene addChild:jointBox];
    
    // people
    people.addAsChild(rootNode);
    
    
    // ---------------- Load Markers ---------------- //
    float load_thickness = 1.7;
    float rcn_thickness = 1;
    float beam_thickness = 1.2;
    liveLoad = LoadMarker(3, false, 1, 2.0);
    liveLoad.setPosition(GLKVector3Make(0, 10 + Calculator::height, 0));
    liveLoad.setInputRange(0, 2.5);
    liveLoad.setMinHeight(5);
    liveLoad.setMaxHeight(15);
    liveLoad.setEnds(0, Calculator::width * 2);
    liveLoad.setThickness(load_thickness);
    liveLoad.addAsChild(rootNode);
    liveLoad.setScenes(skScene, scnView);
    
    deadLoad = LoadMarker(4);
    deadLoad.setPosition(GLKVector3Make(0, Calculator::height, 0));
    deadLoad.setInputRange(0, 3);
    deadLoad.setMinHeight(10);
    deadLoad.setMaxHeight(10);
    deadLoad.setLoad(3);
    deadLoad.setEnds(0, Calculator::width * 2);
    deadLoad.setThickness(load_thickness);
    deadLoad.addAsChild(rootNode);
    deadLoad.setScenes(skScene, scnView);

    sideLoad = GrabbableArrow(2.0);
    sideLoad.setPosition(GLKVector3Make(0, Calculator::height, 0));
    sideLoad.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
    sideLoad.setThickness(load_thickness);
    sideLoad.setInputRange(0, 8.65);
    sideLoad.setMinLength(5);
    sideLoad.setMaxLength(15);
    sideLoad.addAsChild(rootNode);
    sideLoad.setScenes(skScene, scnView);
    sideLoad.setFormatString(@"%.1f k");

    // beams
    int res = 8;
    std::vector<std::vector<float>> vert_vals, horiz_vals;
    horiz_vals.resize(2);
    vert_vals.resize(2);
    double horiz_step = Calculator::width / (res - 1);
    double vert_step = Calculator::height / (res - 1);
    for (int i = 0; i < res; ++i) {
        horiz_vals[0].push_back(horiz_step * i);
        vert_vals[0].push_back(vert_step * i);
        horiz_vals[1].push_back(0);
        vert_vals[1].push_back(0);
    }
    deflections.col_AB = vert_vals;
    deflections.col_DC = vert_vals;
    deflections.col_FE = vert_vals;
    deflections.beam_BC = horiz_vals;
    deflections.beam_CE = horiz_vals;
    GLKQuaternion vert_ori = GLKQuaternionMakeWithAngleAndAxis(M_PI/2, 0, 0, 1);
    line_AB = BezierLine(deflections.col_AB);
    line_AB.setOrientation(vert_ori);
    // Move the first column over, so 0 is on the left side
    line_AB.setPosition(GLKVector3Make(beam_thickness, 0, 0));
    line_DC = BezierLine(deflections.col_DC);
    line_DC.setPosition(GLKVector3Make(Calculator::width + beam_thickness / 2, 0, 0));
    line_DC.setOrientation(vert_ori);
    line_FE = BezierLine(deflections.col_FE);
    line_FE.setPosition(GLKVector3Make(2 * Calculator::width, 0, 0));
    line_FE.setOrientation(vert_ori);
    line_BC = BezierLine(deflections.beam_BC);
    line_BC.setPosition(GLKVector3Make(0, Calculator::height, 0));
    line_CE = BezierLine(deflections.beam_CE);
    line_CE.setPosition(GLKVector3Make(Calculator::width, Calculator::height, 0));

    std::vector<BezierLine*> beams = {&line_AB, &line_DC, &line_FE, &line_BC, &line_CE};
    for (BezierLine* beam : beams) {
        beam->addAsChild(rootNode);
        beam->setThickness(beam_thickness);
    }

    // Force arrows
    // F_AB and V_AB stay at position (0, 0)
    F_DC.setPosition(GLKVector3Make(Calculator::width, 0, 0));
    V_DC.setPosition(GLKVector3Make(Calculator::width, 0, 0));

    F_FE.setPosition(GLKVector3Make(Calculator::width * 2, 0, 0));
    V_FE.setPosition(GLKVector3Make(Calculator::width * 2, 0, 0));
    
    V_AB.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI/2));
    V_DC.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
    V_FE.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI/2));
    F_AB.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    F_DC.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    F_FE.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));

    std::vector<GrabbableArrow*> rcn_arrows = {&F_AB, &F_DC, &F_FE, &V_AB, &V_DC, &V_FE};
    for (GrabbableArrow* arrow : rcn_arrows) {
        arrow->setThickness(rcn_thickness);
        arrow->setScenes(skScene, scnView);
        arrow->addAsChild(rootNode);
        arrow->setInputRange(0, 100);
        arrow->setFormatString(@"%.1f k");
        arrow->setMinLength(5);
        arrow->setMaxLength(15);
        arrow->setColor(0, 1, 0);
    }
    
    // Moments
    M_DC.setPosition(GLKVector3Make(Calculator::width, 0, 0));
    M_FE.setPosition(GLKVector3Make(Calculator::width * 2, 0, 0));
    for (CircleArrow* moment : {&M_AB, &M_DC, &M_FE}) {
        moment->setThickness(rcn_thickness);
        moment->setRadius(5);
        moment->setInputRange(0, 10);
        moment->setScenes(skScene, scnView);
        moment->addAsChild(rootNode);
        moment->setColor(0, 1, 0);
        moment->setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
        moment->setIntensity(2);
    }

    // default loads
    liveLoad.setLoad(0);
    deadLoad.setLoad(3);
    sideLoad.setIntensity(0);
    calc_inputs.D = 3;
    calc_inputs.F = 0;
    calc_inputs.L = 0;
    [self updateForces];
    return rootNode;
}

- (void)scnRendererUpdateAt:(NSTimeInterval)time {
}


- (void)setupUIWithScene:(SCNView *)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided {
    [[NSBundle mainBundle] loadNibNamed:@"townBldgView" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    self.viewFromNib.managingParent = managingParent;
    
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.liveLoadView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.deadLoadView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.rcnForceView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.modelToggleView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.legendView];
    
    [self setVisibilities];
}

- (void)skUpdate {
    // We update forces if necessary here, because SpriteKit objects are modified in the updateForces function
    if (forcesDirty) {
//    if (true) {
        [self updateForces];
        forcesDirty = false;
    }
    liveLoad.doUpdate();
    deadLoad.doUpdate();
    sideLoad.doUpdate();
//    std::vector<BezierLine*> beams = {&line_AB, &line_DC, &line_FE, &line_BC, &line_CE};
//    for (BezierLine* beam : beams) {
//    std::vector<GrabbableArrow*> rcn_arrows = {&F_AB, &F_DC, &F_FE, &V_AB, &V_DC, &V_FE};
    for (GrabbableArrow* arrow : {&F_AB, &F_DC, &F_FE, &V_AB, &V_DC, &V_FE}) {
        arrow->doUpdate();
    }
    for (CircleArrow* moment : {&M_AB, &M_DC, &M_FE}) {
        moment->doUpdate();
    }
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    float planeHeight = ((SCNPlane*)frontOcclPlane.geometry).height;
    frontOcclPlane.position = SCNVector3Make(0, -planeHeight/2 + ocPlnPosY, 0.1);
    
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(29, 6.5, 90);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.33);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_x_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"town_static.png");
}

- (ARManager*)makeIndoorTracker {
    float planeHeight = ((SCNPlane*)frontOcclPlane.geometry).height;
    frontOcclPlane.position = SCNVector3Make(0, -planeHeight/2 + ocPlnPosY, 0.1);
    
    GLKMatrix4 translation_mat = GLKMatrix4MakeTranslation(15, 9.5, 0);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.0);
    GLKMatrix4 transform_mat = GLKMatrix4Multiply(rot_x_mat, translation_mat);
    return new VuforiaARManager((ARView*)scnView, scnView.scene, UIInterfaceOrientationLandscapeRight, @"town.xml", transform_mat);
}

- (ARManager*)makeOutdoorTracker {
    float planeHeight = ((SCNPlane*)frontOcclPlane.geometry).height;
    frontOcclPlane.position = SCNVector3Make(0, -planeHeight/2 + ocPlnPosY - 5, 15);
    
    GLKMatrix4 rotMat = GLKMatrix4MakeXRotation(0.15);
    return new cvARManager(scnView, scnView.scene, cvStructure_t::town, rotMat);
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
        }
        calc_inputs.x1 = sideDragPosition.first;
        calc_inputs.x2 = sideDragPosition.second;
        calc_inputs.L = dragValue;
        double length = sideDragPosition.second - sideDragPosition.first;
        people.setPosition(GLKVector3Make(sideDragPosition.first, 4 + Calculator::height, 0));
        people.setLength(length);
    }
    
    if (sideLoad.dragging) {
        GLKVector3 cameraDir = GLKVector3Make(cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
        float dragValue = sideLoad.getDragValue(cameraPos, touchRay, cameraDir);
        sideLoad.setIntensity(dragValue);
        calc_inputs.F = dragValue;
    }
    
    forcesDirty = true;
//    [self updateForces];
    
    // ------ 2D Touch Handling ------ //
    CGPoint pointSkScene = [self convertTouchToSKScene:p];
    if (draggingJointBox) {
        CGPoint moved = CGPointMake(pointSkScene.x - lastDragPt.x, pointSkScene.y - lastDragPt.y);
        CGPoint newPos = CGPointMake(jointBox.position.x + moved.x, jointBox.position.y + moved.y);
        // keep box within scene
        newPos.x = std::min<double>(std::max<double>(0., newPos.x), skScene.size.width - jointBox.frame.size.width);
        newPos.y = std::min<double>(std::max<double>(self.bottomBarView.frame.size.height, newPos.y), skScene.size.height - jointBox.frame.size.height);
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
    if (liveLoad.draggingMode() != LoadMarker::none) {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        // set people weight and shuffle after touch release
        auto ends = liveLoad.getDragPosition();
        people.setWeight(1000 * (ends.second - ends.first) * liveLoad.getDragValue());
        people.shuffle();
        [SCNTransaction commit];
        
        [[SEGAnalytics sharedAnalytics] track:trk_town_loadSetTouch
                                   properties:@{ @"values": @{
                                                         @"direction": @"top",
                                                         @"leftX": [NSNumber numberWithFloat:liveLoad.getStartPos().x],
                                                         @"rightX": [NSNumber numberWithFloat:liveLoad.getEndPos().x],
                                                         @"load": [NSNumber numberWithFloat:liveLoad.getLoad(0)]
                                                         }
                                                 }];
    }
    
    if (sideLoad.dragging) {
        [[SEGAnalytics sharedAnalytics] track:trk_town_loadSetTouch
                                   properties:@{ @"values": @{
                                                         @"direction": @"side",
                                                         @"load": [NSNumber numberWithFloat:sideLoad.lastArrowValue]
                                                         }
                                                 }];
    }
    
    
    liveLoad.touchEnded();
    sideLoad.touchEnded();
    
    draggingJointBox = false;
}

- (IBAction)visToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
    liveLoad.setHidden(!self.liveLoadSwitch.on);
    sideLoad.setHidden(!self.liveLoadSwitch.on);
    deadLoad.setHidden(!self.deadLoadSwitch.on);
    townModel.hidden = !self.modelSwitch.on;
    for (GrabbableArrow* arrow : {&F_AB, &F_DC, &F_FE, &V_AB, &V_DC, &V_FE}) {
        arrow->setHidden(!self.rcnForceSwitch.on);
    }
    for (CircleArrow* moment : {&M_AB, &M_DC, &M_FE}) {
        moment->setHidden(!self.rcnForceSwitch.on);
    }
    
    [[SEGAnalytics sharedAnalytics] track:trk_setVisibilities
                               properties:@{ @"scene": NSStringFromClass(self.class),
                                             @"items": @{
                                                     @"liveLoad": [NSNumber numberWithBool:self.liveLoadSwitch.on],
                                                     @"deadLoad": [NSNumber numberWithBool:self.deadLoadSwitch.on],
                                                     @"rcnForce": [NSNumber numberWithBool:self.rcnForceSwitch.on],
                                                     @"modelVisible": [NSNumber numberWithBool:self.modelSwitch.on]
                                                     }
                                             }];
}

- (void)updateForces {
//    calc_inputs.L = 2.5;
//    calc_inputs.x1 = 16.8;
//    calc_inputs.x2 = 30;
//    calc_inputs.F = 5.62 * 0.985;
    const Output_t results = Calculator::calculateForces(calc_inputs);
    F_AB.setIntensity(results.F_AB);
    F_DC.setIntensity(results.F_DC);
    F_FE.setIntensity(results.F_FE);
    V_AB.setIntensity(results.V_AB);
    V_DC.setIntensity(results.V_DC);
    V_FE.setIntensity(results.V_FE);
    M_AB.setIntensity(results.M_AB);
    M_DC.setIntensity(results.M_DC);
    M_FE.setIntensity(results.M_FE);
    
    double defl_scale = 200;
    Calculator::calculateDeflections(calc_inputs, results.delta, deflections, defl_scale);
//    self.setLabel.text = [NSString stringWithFormat:@"Set = %d", set];
    line_AB.updatePath(deflections.col_AB);
    line_DC.updatePath(deflections.col_DC);
    line_FE.updatePath(deflections.col_FE);
    line_BC.updatePath(deflections.beam_BC);
    line_CE.updatePath(deflections.beam_CE);
    
//    printf("\n");
    [cornerB setForce1:-results.F_BA force2:-results.F_BC];
    [cornerE setForce1:-results.F_EC force2:-results.F_EF];
    [cornerB setShear1:-results.V_BA shear2:-results.V_BC];
    [cornerE setShear1:-results.V_EC shear2:-results.V_EF];
    [cornerB setMoment1:-results.M_BA moment2:-results.M_BC];
    [cornerE setMoment1:-results.M_EC moment2:-results.M_EF];
    
    double rot_scale = 400;
    cornerB.zRotation = -M_PI/2 + results.theta_B * rot_scale;
    cornerE.zRotation = M_PI + results.theta_E * rot_scale;
}

- (IBAction)planeMoved:(id)sender {
}
@end
