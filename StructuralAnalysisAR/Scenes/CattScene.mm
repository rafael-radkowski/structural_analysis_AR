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
const static double maxWindSpeed = 100;

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

    for (auto arrow : {&pArrow01, &pArrow02, &pArrow06, &pArrow1, &pArrow2, &pArrow3, &pArrow4, &pArrow5,
                       &rArrow1, &rArrow2, &rArrow3}) {
        arrow->setMinLength(5);
        arrow->setMaxLength(15);
        arrow->setThickness(2);
        arrow->addAsChild(rootNode);
        arrow->setInputRange(0, 8);
        arrow->setScenes(skScene, scnView);
        arrow->setFormatString(@"%.1f k");
        arrow->setColor(0.376, 0.188, 0.8196);
    }
    rArrow1.setColor(0, 1, 0);
    rArrow2.setColor(0, 1, 0);
    rArrow3.setColor(0, 1, 0);
    
    return rootNode;
}


- (void)setupUIWithScene:(SCNView *)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided {
    [[NSBundle mainBundle] loadNibNamed:@"cattView" owner:self options: nil];
    self.viewFromNib.frame = screenRect;
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    self.viewFromNib.managingParent = managingParent;
    
    [self.viewFromNib.visOptionsBox addArrangedSubview:self.rcnForceView];
    
    [self setVisibilities];
}

- (void)skUpdate {
    for (auto arrow : {&pArrow01, &pArrow02, &pArrow06, &pArrow1, &pArrow2, &pArrow3, &pArrow4, &pArrow5,
                       &rArrow1, &rArrow2, &rArrow3}) {
        arrow->doUpdate();
    }
}


// Make various AR Managers
- (ARManager*)makeStaticTracker {
    GLKMatrix4 trans_mat = GLKMatrix4MakeTranslation(74, -39, 260);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.3);
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(rot_x_mat, trans_mat);
    return new StaticARManager(scnView, scnView.scene, cameraMatrix, @"catt_target.jpg");
}

- (ARManager*)makeIndoorTracker {
    GLKMatrix4 translation_mat = GLKMatrix4MakeTranslation(0, 50, 0);
    GLKMatrix4 rot_x_mat = GLKMatrix4MakeXRotation(0.2);
    GLKMatrix4 transform_mat = GLKMatrix4Multiply(rot_x_mat, translation_mat);
    return new VuforiaARManager((ARView*)scnView, scnView.scene, UIInterfaceOrientationLandscapeRight, @"catt_hall.xml", transform_mat);
}

- (ARManager*)makeOutdoorTracker {
    GLKMatrix4 rotMat = GLKMatrix4MakeYRotation(0.0);
    return new cvARManager(scnView, scnView.scene, cvStructure_t::campanile, rotMat);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}

- (void)scnRendererUpdateAt:(NSTimeInterval)time {
    
}

- (IBAction)visToggled:(id)sender {
    [self setVisibilities];
}

- (void)setVisibilities {
}

- (IBAction)loadsChanged:(id)sender {
    double snow_depth_in = self.snowSlider.value * maxSnowDepth;
    [self.snowDepthLabel setText:[NSString stringWithFormat:@"%.0f in.", snow_depth_in]];
    
    double wind_speed_mph = self.windSlider.value * maxWindSpeed;
    [self.windSpeedLabel setText:[NSString stringWithFormat:@"%.0f mph", wind_speed_mph]];
    
    // TODO: Should snow_depth be in inches or feet?
    double snow_load = snow_depth_in * (1./12) * 20 * 10;
    double load_p1s = 16.96 * snow_load;
    double load_p2s = 9.167 * snow_load;
    double load_p3s = 16.96 * snow_load;
    double load_p01s = 7.792 * snow_load;
    double load_p02s = 7.792 * snow_load;
    
    // dead loads
    double dead_load = 325;
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
    double qz = 0.00256 * 0.915 * 1.0 * 0.35 * wind_speed_mph * wind_speed_mph;
    double load_wind1 = qz * 0.85 * 0.4 * std::cos(M_PI / 4);
    double load_wind2 = qz * 0.85 * 0.6 * std::cos(M_PI / 4);
    double load_p4 = (load_wind1 + load_wind2) * 17.5 / 1000.;
    double load_p5 = (load_wind1 + load_wind2) * 6.47 / 1000.;
    double load_p06 = (load_wind1 + load_wind2) * 11.03 / 1000.;
    
    double A_data[100] = {
    //           F1      F2      F3      F4      F5      F6      F7      R1      R2      R3
    /* F1 */     0.707,  0,      0,      0,      0.905,  0,      0,      0,     -1,      0,
    /* F2 */     0.707,  0,      0,      0,      0.915,  0,      0,      1,      0,      0,
    /* F3 */    -0.707,  0.707,  0,      0,      0,      0.908,  1,      0,      0,      0,
    /* F4 */    -0.707,  0.707,  0,      0,      0,     -0.416,  0,      0,      0,      0,
    /* F5 */     0,     -0.707,  0.707,  0,      0,      0,      0,      0,      0,      0,
    /* F6 */     0,     -0.707, -0.707,  0,      0,      0,      0,      0,      0,      0,
    /* F7 */     0,      0,     -0.707,  0.707, -0.908,  0,     -1,      0,      0,      0,
    /* R1 */     0,      0,      0.707, -0.707, -0.415,  0,      0,      0,      0,      0,
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
        // float mag = std::abs(val);
        // mag = std::min(max_mag, mag);
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
