//
//  CattScene.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/28/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

// must include cvARManager.h before others, because it includes openCV headers
#include <opencv2/opencv.hpp>
#include "cvARManager.h"
#include "CattScene.h"

#include "VuforiaARManager.h"
#include "StaticARManager.h"
#include "colorConversion.h"

#import <Analytics/SEGAnalytics.h>
#import "TrackingConstants.h"

// Constants
const static double maxSnowDepth = 25;
const static double maxWindSpeed = 150;
const static double dead_load = 325;

@implementation CattScene

- (id)initWithController:(id<ARViewController>)controller {
    managingParent = controller;
    return [self init];
}

- (SCNNode *)createScene:(SCNView *)the_scnView skScene:(SKScene *)the_skScene withCamera:(SCNNode *)camera {
    scnView = the_scnView;
    skScene = the_skScene;
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
    addLight(-30, 50, 100, 700);
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.8;
    [rootNode addChildNode:ambientLightNode];
    
    // particular points in the truss
    GLKVector3 origin = GLKVector3Make(0, 0, 0);
    GLKVector3 pt1 = GLKVector3Make(15.625, 15 + 7./12, 0);
    GLKVector3 pt2 = GLKVector3Make(24.75, 24.75, 0);
    GLKVector3 pt3 = GLKVector3Make(33.875, 15 + 7./12, 0);
    GLKVector3 rightCorner = GLKVector3Make(49.5, 0, 0);
    
    // move the truss members into position
    memb1.move(GLKVector3Make(0, 0, 0), pt1);
    memb2.move(pt1, pt2);
    memb3.move(pt2, pt3);
    memb4.move(pt3, rightCorner);
    memb5.move(origin, pt3);
    memb6.move(pt1, rightCorner);
    memb7.move(pt1, pt3);
    
    for (auto memb : {&memb1, &memb2, &memb3, &memb4, &memb5, &memb6, &memb7}) {
        memb->addAsChild(rootNode);
        memb->setThickness(2);
    }
    
    
    // Joint indicators
    SCNNode* joint1 = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:2]];
    SCNNode* joint2 = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:2]];
    SCNNode* joint3 = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:2]];
    joint1.position = SCNVector3FromGLKVector3(pt1);
    joint2.position = SCNVector3FromGLKVector3(pt2);
    joint3.position = SCNVector3FromGLKVector3(pt3);
    SCNMaterial* jointMat = [SCNMaterial material];
    jointMat.diffuse.contents = [UIColor colorWithWhite:0.5 alpha:1.0];
    joint1.geometry.firstMaterial = jointMat;
    joint2.geometry.firstMaterial = jointMat;
    joint3.geometry.firstMaterial = jointMat;
    [rootNode addChildNode:joint1];
    [rootNode addChildNode:joint2];
    [rootNode addChildNode:joint3];

    // Point load arrows
    pArrow01.setPosition(origin);
    pArrow06.setPosition(origin);
    pArrow1.setPosition(pt1);
    pArrow4.setPosition(pt1);
    pArrow2.setPosition(pt2);
    pArrow5.setPosition(pt2);
    pArrow3.setPosition(pt3);
    pArrow02.setPosition(rightCorner);

    // Pointing right
    pArrow06.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI / 2));
    pArrow4.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI / 2));
    pArrow5.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI / 2));
    
    // Reaction force arrows
    rArrow1.setPosition(origin);
    rArrow2.setPosition(origin);
    rArrow3.setPosition(rightCorner);
    // point up
    rArrow1.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    rArrow3.setRotationAxisAngle(GLKVector4Make(0, 0, 1, M_PI));
    // point left
    rArrow2.setRotationAxisAngle(GLKVector4Make(0, 0, 1, -M_PI / 2));

    float loadThickness = 2;

    for (auto arrow : {&pArrow01, &pArrow02, &pArrow06, &pArrow1, &pArrow2, &pArrow3, &pArrow4, &pArrow5,
                       &rArrow1, &rArrow2, &rArrow3}) {
        arrow->setMinLength(5);
        arrow->setMaxLength(15);
        arrow->setThickness(loadThickness);
        arrow->addAsChild(rootNode);
        arrow->setInputRange(0, 8);
        arrow->setScenes(skScene, scnView);
        arrow->setFormatString(@"%.1f k");
        arrow->setColor(0.376, 0.188, 0.8196);
    }
    rArrow1.setColor(0, 1, 0);
    rArrow2.setColor(0, 1, 0);
    rArrow3.setColor(0, 1, 0);

    // Distributed loads
    loadDead = LoadMarker(5, false, 1, 3);
    loadSnow = LoadMarker(5, false, 1, 3);
    loadWind = LoadMarker(5);

    float dist_load_gap = 2;
    float load_input_max = 0.5;
    float load_min_height = 5;
    float load_max_height = 17.5;
    
    loadDead.setPosition(GLKVector3Make(origin.x, origin.y + 24.75 + dist_load_gap, origin.z));
    loadDead.setInputRange(0, load_input_max);
    loadDead.setMinHeight(load_min_height);
    loadDead.setMaxHeight(load_max_height);
    loadDead.setEnds(0, rightCorner.x - origin.x);
    loadDead.setThickness(loadThickness);
    loadDead.addAsChild(rootNode);
    loadDead.setScenes(skScene, scnView);

    float dead_load_height = ((dead_load / 1000) / load_input_max) * (load_max_height - load_min_height) + load_min_height;
    loadSnow.setPosition(GLKVector3Make(origin.x, origin.y + 24.75 + dist_load_gap + dead_load_height, origin.z));
    loadSnow.setInputRange(0, load_input_max);
    loadSnow.setMinHeight(load_min_height);
    loadSnow.setMaxHeight(load_max_height);
    loadSnow.setEnds(0, rightCorner.x - origin.x);
    loadSnow.setThickness(loadThickness);
    loadSnow.addAsChild(rootNode);
    loadSnow.setScenes(skScene, scnView);

    loadWind.setOrientation(GLKQuaternionMakeWithAngleAndAxis(M_PI / 4, 0, 0, 1));
    loadWind.setPosition(GLKVector3Make(origin.x - dist_load_gap*std::cos(M_PI/4),
                                        origin.y + dist_load_gap*std::sin(M_PI/4),
                                        origin.z));
    loadWind.setInputRange(0, load_input_max);
    loadWind.setMinHeight(load_min_height);
    loadWind.setMaxHeight(load_max_height);
    loadWind.setEnds(0, 35);
    loadWind.setThickness(loadThickness);
    loadWind.addAsChild(rootNode);
    loadWind.setScenes(skScene, scnView);
    
    // Forces Box
    int forcesBoxWidth = 250;
    int forcesBoxHeight = 385;
    int forcesTitleSize = 35;
    int padding = 10;
    
    forcesBox = [[SKInfoBox alloc] initWithTitle:@"Member Forces" withSize:CGSizeMake(forcesBoxWidth, forcesBoxHeight) titleSize:forcesTitleSize];
    forcesBox.position = CGPointMake(scnView.frame.size.width - forcesBoxWidth - 20, scnView.frame.size.height - forcesBoxHeight - 150);
    
    SKSpriteNode* memberKey = [SKSpriteNode spriteNodeWithImageNamed:@"catt_member_key.png"];
    // Place key image to fill box width with 10px padding
    memberKey.anchorPoint = CGPointMake(0, 1);
    float keySize = memberKey.frame.size.width;
    float keyScale = (forcesBoxWidth - (2 * padding)) / keySize;
    memberKey.xScale = memberKey.yScale = keyScale;
    memberKey.position = CGPointMake(padding, forcesBoxHeight - forcesTitleSize - padding);
    [forcesBox addChild:memberKey];
    
    membLabels.resize(7);
    membValues.resize(7);
    float labelHeight = 30;
    float labelsStart = forcesBoxHeight - forcesTitleSize - padding - memberKey.frame.size.height - padding;
    for (int i = 0; i < 7; ++i) {
        // text label to hold value of truss force
        membLabels[i] = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        // "A", or "B", etc. corresponding to memberKey
        SKLabelNode* membTitleLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        membTitleLabel.text = [NSString stringWithFormat:@"%c:", 'A'+i];
        
        // formatting, alignment, etc.
        membTitleLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        membLabels[i].horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        membLabels[i].fontSize = membTitleLabel.fontSize = labelHeight - 5;
        membLabels[i].fontColor = membTitleLabel.fontColor = [UIColor blackColor];
        membLabels[i].verticalAlignmentMode = membTitleLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
        
        // position
        membLabels[i].position = CGPointMake(forcesBoxWidth - padding, labelsStart - i*labelHeight);
        membTitleLabel.position = CGPointMake(padding, labelsStart - i*labelHeight);
        
        // create shading on every other row for readability
        if (i % 2 == 0) {
            SKShapeNode* shadeBox = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, forcesBoxWidth, labelHeight)];
            // Not ideal, just eyeballed to get at 5px offset
            shadeBox.position = CGPointMake(0, labelsStart - (i+1)*labelHeight + 5);
            shadeBox.fillColor = [UIColor colorWithWhite:0.7 alpha:0.7];
            shadeBox.strokeColor = [UIColor colorWithWhite:0 alpha:0];
            shadeBox.zPosition = -1;
            [forcesBox addChild:shadeBox];
        }
        
        [forcesBox addChild:membLabels[i]];
        [forcesBox addChild:membTitleLabel];
    }
    
    [skScene addChild:forcesBox];
    
    return rootNode;
}


- (void)setupUIWithScene:(SCNView *)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided {
    [[NSBundle mainBundle] loadNibNamed:@"cattView" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    self.viewFromNib.managingParent = managingParent;
    
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.rcnForceView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.forceTypeView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.deadVisView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.snowVisView];
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.windVisView];
    
    // Put bottom bar into the contentView of SceneTemplateView, so the processing curtain is still above it
    [self.viewFromNib.contentView insertSubview:self.bottomBarView aboveSubview:self.viewFromNib.bottomBarView];
    
    [self setVisibilities];
    [self updateLoads];
}

- (void)skUpdate {
    for (auto arrow : {&pArrow01, &pArrow02, &pArrow06, &pArrow1, &pArrow2, &pArrow3, &pArrow4, &pArrow5,
                       &rArrow1, &rArrow2, &rArrow3}) {
        arrow->doUpdate();
    }
    
    
    if (membValuesUpdated) {
        for (int i = 0; i < 7; ++i) {
            membLabels[i].text = [NSString stringWithFormat:@"%.1f kip", membValues[i]];
        }
        membValuesUpdated = false;
    }

    loadDead.doUpdate();
    loadSnow.doUpdate();
    loadWind.doUpdate();
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(24, -3, 170);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.65);
    GLKMatrix4 rot_y_mat = GLKMatrix4MakeYRotation(0.15);
//    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(30, 0, 170);
//    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.0);
    GLKMatrix4 rot_mat = GLKMatrix4Multiply(rot_y_mat, rot_x_mat);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"catt_target2.jpg");
}

- (ARManager*)makeIndoorTracker {
//    GLKMatrix4 translation_mat = GLKMatrix4MakeTranslation(0, 50, 0);
//    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.2);
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(25, 0, 5);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.2);
    GLKMatrix4 rot_y_mat = GLKMatrix4MakeYRotation(0.2);
    GLKMatrix4 rot_mat = GLKMatrix4Multiply(rot_y_mat, rot_x_mat);
    GLKMatrix4 transform_mat = GLKMatrix4Multiply(rot_mat, trans_mat);
    return new VuforiaARManager((ARView*)scnView, scnView.scene, UIInterfaceOrientationLandscapeRight, @"catt_hall.xml", transform_mat);
}

- (ARManager*)makeOutdoorTracker {
    GLKMatrix4 rotMat = GLKMatrix4MakeYRotation(0.0);
    return new cvARManager(scnView, scnView.scene, cvStructure_t::catt, rotMat);
}

- (CGPoint)convertTouchToSKScene:(CGPoint)scnViewPt {
    // touch point in SkScene.view coordinate system
    CGPoint pointSkView = [scnView convertPoint:scnViewPt toView:skScene.view];
    // touch point in skScene coordinate system
    CGPoint pointSkScene = [skScene convertPointFromView:pointSkView];
    return pointSkScene;
}

- (void)touchesBegan:(CGPoint)p farHitIs:(GLKVector3)farClipHit {
    // ------ 2D Touch Handling ------ //
    CGPoint pointSkScene = [self convertTouchToSKScene:p];
    BOOL on_box = [forcesBox touchBegan:pointSkScene];
    
    // ------ 3D Touch Handling ------ //
    if (!on_box) {
        GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
        loadSnow.touchBegan(cameraPos, farClipHit);
        loadWind.touchBegan(cameraPos, farClipHit);
    }
}

- (void)touchesMoved:(CGPoint)p farHitIs:(GLKVector3)farClipHit {
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));

    if (loadSnow.draggingMode() & LoadMarker::vertically) {
        double dragValue = 1000 * loadSnow.getDragValue(cameraPos, touchRay);
        double snow_depth_in = dragValue * (12./200);
        [self.snowSlider setValue:(snow_depth_in / maxSnowDepth)];
        [self updateLoads];
    }
    if (loadWind.draggingMode() & LoadMarker::vertically) {
        double dragValue = 1000 * loadWind.getDragValue(cameraPos, touchRay);
        double c = 0.00256 * 0.915 * 0.85 * 10 * std::cos(M_PI/4) * 0.85;
        double v2 = dragValue / c;
        double v = std::sqrt(v2);
        [self.windSlider setValue:v / maxWindSpeed];
        [self updateLoads];
    }

    // ------ 2D Touch Handling ------ //
    CGPoint pointSkScene = [self convertTouchToSKScene:p];
    CGRect skBounds = CGRectMake(0,
                                 self.bottomBarView.frame.size.height,
                                 skScene.size.width,
                                 skScene.size.height - self.bottomBarView.frame.size.height);
    [forcesBox touchMoved:pointSkScene limitTo:skBounds];
}

- (void)touchesCancelled {
    loadSnow.touchCancelled();
    loadWind.touchCancelled();
    
    [forcesBox touchCancelled];
}

- (void)touchesEnded {
    loadSnow.touchEnded();
    loadWind.touchEnded();
    
    [forcesBox touchEnded];
}

- (void)scnRendererUpdateAt:(NSTimeInterval)time {
    
}

- (IBAction)visToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
    bool point_loads_hidden = [self.forceTypeToggle selectedSegmentIndex] != 0;
    bool distributed_loads_hidden = !point_loads_hidden;
    
    for (auto arrow : {&pArrow01, &pArrow02, &pArrow06, &pArrow1, &pArrow2, &pArrow3, &pArrow4, &pArrow5}) {
        arrow->setHidden(point_loads_hidden);
    }
    
    bool reaction_force_hidden = !self.rcnForceSwitch.on;

    for (auto arrow : {&rArrow1, &rArrow2, &rArrow3}) {
        arrow->setHidden(reaction_force_hidden);
    }

    loadDead.setHidden(distributed_loads_hidden || !self.deadVisSwitch.on);
    loadSnow.setHidden(distributed_loads_hidden || !self.snowVisSwitch.on);
    loadWind.setHidden(distributed_loads_hidden || !self.windVisSwitch.on);
    
    // Disable distributed load visibility switches if not active
    [self.deadVisSwitch setEnabled:!distributed_loads_hidden];
    [self.snowVisSwitch setEnabled:!distributed_loads_hidden];
    [self.windVisSwitch setEnabled:!distributed_loads_hidden];

}

- (IBAction)loadsChanged:(id)sender {
    [self updateLoads];
}

-(void)updateLoads {
    double snow_depth_in = self.snowSlider.value * maxSnowDepth;
    [self.snowDepthLabel setText:[NSString stringWithFormat:@"%.0f in.", snow_depth_in]];
    
    double wind_speed_mph = self.windSlider.value * maxWindSpeed;
    [self.windSpeedLabel setText:[NSString stringWithFormat:@"%.0f mph", wind_speed_mph]];
    
    double snow_load = snow_depth_in * (200./12);
    double load_p1s = 16.96 * snow_load;
    double load_p2s = 9.167 * snow_load;
    double load_p3s = 16.96 * snow_load;
    double load_p01s = 7.792 * snow_load;
    double load_p02s = 7.792 * snow_load;
    
    // dead loads
    double load_p1d = 16.96 * dead_load;
    double load_p2d = 9.167 * dead_load;
    double load_p3d = 16.96 * dead_load;
    double load_p01d = 7.792 * dead_load;
    double load_p02d = 7.792 * dead_load;
    
    // vertical laods
    // TODO: Should there be parentheses around the summations?
    double load_p1 = (load_p1s + load_p1d) / 1000.;
    double load_p2 = (load_p2s + load_p2d) / 1000.;
    double load_p3 = (load_p3s + load_p3d) / 1000.;
    double load_p01 = (load_p01s + load_p01d) / 1000.;
    double load_p02 = (load_p02s + load_p02d) / 1000.;
    
    // wind loads
    double qz = 0.00256 * 0.915 * 1.0 * 0.85 * 10 * wind_speed_mph * wind_speed_mph;
    double load_wind1 = qz * 0.85 * 0.4 * std::cos(M_PI / 4);
    double load_wind2 = qz * 0.85 * 0.6 * std::cos(M_PI / 4);
    double load_p4 = (load_wind1 + load_wind2) * 17.5 / 1000.;
    double load_p5 = (load_wind1 + load_wind2) * 6.47 / 1000.;
    double load_p06 = (load_wind1 + load_wind2) * 11.03 / 1000.;

    loadSnow.setLoad(snow_load / 1000);
    loadDead.setLoad(dead_load / 1000);
    loadWind.setLoad((load_wind1 + load_wind2) / 1000);
    
    double A_data[100] = {
    //           F1      F2      F3      F4      F5      F6      F7      R1      R2      R3
    /* F1 */     0.707,  0,      0,      0,      0.905,  0,      0,      0,     -1,      0,
    /* F2 */     0.707,  0,      0,      0,      0.417,  0,      0,      1,      0,      0,
    /* F3 */    -0.707,  0.707,  0,      0,      0,      0.908,  1,      0,      0,      0,
    /* F4 */    -0.707,  0.707,  0,      0,      0,     -0.417,  0,      0,      0,      0,
    /* F5 */     0,     -0.707,  0.707,  0,      0,      0,      0,      0,      0,      0,
    /* F6 */     0,     -0.707, -0.707,  0,      0,      0,      0,      0,      0,      0,
    /* F7 */     0,      0,     -0.707,  0.707, -0.908,  0,     -1,      0,      0,      0,
    /* R1 */     0,      0,      0.707, -0.707, -0.417,  0,      0,      0,      0,      0,
    /* R2 */     0,      0,      0,     -0.707,  0,     -0.908,  0,      0,      0,      0,
    /* R3 */     0,      0,      0,      0.707,  0,      0.417,  0,      0,      0,      1
    };
    double c_data[10] = {-load_p06, load_p01, -load_p4, load_p1, -load_p5, load_p2, 0, load_p3, 0, load_p02};
    cv::Mat A(10, 10, CV_64F, A_data);
    cv::Mat b(10, 1, CV_64F, c_data);
    cv::Mat c(10, 1, CV_64F);
    bool has_solution = cv::solve(A, b, c);
    assert(has_solution);
    if (!has_solution) {
        NSLog(@"No solution to truss member calculations");
        return;
    }
    
    double F1 = c.at<double>(0, 0);
    double F2 = c.at<double>(1, 0);
    double F3 = c.at<double>(2, 0);
    double F4 = c.at<double>(3, 0);
    double F5 = c.at<double>(4, 0);
    double F6 = c.at<double>(5, 0);
    double F7 = c.at<double>(6, 0);
    double R1 = c.at<double>(7, 0);
    double R2 = c.at<double>(8, 0);
    double R3 = c.at<double>(9, 0);
    
    for (int i = 0; i < 7; ++i) {
        membValues[i] = c.at<double>(i, 0);
    }
    membValuesUpdated = true;
    
    
    // Update arrows with calculated forces
    pArrow01.setIntensity(load_p01);
    pArrow02.setIntensity(load_p02);
    pArrow06.setIntensity(load_p06);
    pArrow1.setIntensity(load_p1);
    pArrow2.setIntensity(load_p2);
    pArrow3.setIntensity(load_p3);
    pArrow4.setIntensity(load_p4);
    pArrow5.setIntensity(load_p5);
    
    rArrow1.setIntensity(R1);
    rArrow2.setIntensity(R2);
    rArrow3.setIntensity(R3);
    
    // Colors of trusses for showing intensity
    const float MAX_MAG = 40;
    auto color_member = [&](Line3d& memb, float val) {
        float normalized = val / MAX_MAG;
        // clamp to [-1, +1]
        normalized = std::max<float>(-1, std::min<float>(1, normalized));
        // 0 is green, negative is red, positive is blue
        float hue = normalized * 120 + 120;
        hsv color_in;
        // Have saturation also follow magnitude some
        color_in.s = std::abs(normalized) * 0.75 + 0.25;
        color_in.v = 1;
        color_in.h = hue;
        rgb color = hsv2rgb(color_in);
        memb.setColor(color.r, color.g, color.b);
    };
    color_member(memb1, F1);
    color_member(memb2, F2);
    color_member(memb3, F3);
    color_member(memb4, F4);
    color_member(memb5, F5);
    color_member(memb6, F6);
    color_member(memb7, F7);
}


@end
