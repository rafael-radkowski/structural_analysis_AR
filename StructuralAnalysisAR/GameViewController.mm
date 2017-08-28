//
//  GameViewController.m
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "GameViewController.h"
#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>
#import <GLKit/GLKQuaternion.h>

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize scene
//    SCNScene *scene = [SCNScene sceneNamed:@"arrow.obj"];
    SCNScene *scene = [SCNScene scene];
    scene.background.contents = [UIImage imageNamed:@"skywalk.jpg"];
    
    [scene.rootNode addChildNode:arrow.root];
    
//    // Make a sphere
//    targetSphere = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:0.3]];
//    targetSphere.geometry.firstMaterial = [SCNMaterial material];
//    targetSphere.geometry.firstMaterial.diffuse.contents = [UIColor blueColor];
//    [scene.rootNode addChildNode:targetSphere];
    
    // Make a camera
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    // move the camera
    cameraNode.position = SCNVector3Make(0, 0, 5);
    
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    ambientLightNode.light.intensity = 0.7;
    [scene.rootNode addChildNode:ambientLightNode];
    
    
    // Get the view and set our scene to it
    SCNView *scnView = (SCNView *)self.view;
    scnView.scene = scene;
    
    // scnView.showsStatistics = YES;
    
    
    [[NSBundle mainBundle] loadNibNamed:@"View" owner:self options: nil];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.viewFromNib.frame = screenRect;
    printf("w: %f, h: %f\n", screenRect.size.width, screenRect.size.height);
    self.viewFromNib.contentMode = UIViewContentModeScaleToFill;
    [scnView addSubview:self.viewFromNib];
    
    arrowScale = 1.0;
    arrowWidthFactor = 1.0;
    arrowTop = NO;
    // Initialize results from UI defaults
    [self.sliderControl sendActionsForControlEvents:UIControlEventValueChanged];
    [self.stepperControl sendActionsForControlEvents:UIControlEventValueChanged];
    [self.toggleControl sendActionsForControlEvents:UIControlEventValueChanged];
    [self.buttonControl sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self.colorSelector sendActionsForControlEvents:UIControlEventValueChanged];
    
//    // Add UI stuff
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [button setTitle:@"Press me!" forState:UIControlStateNormal];
//    button.frame = CGRectMake(50, 100, 100, 50);
//    [scnView addSubview:button];
    
    
//    // retrieve the ship node
//    SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
//    
//    // animate the 3d object
//    [ship runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:1]]];
//    
//    // retrieve the SCNView
//    SCNView *scnView = (SCNView *)self.view;
//    
//    // set the scene to the view
//    scnView.scene = scene;
//    
//    // allows the user to manipulate the camera
//    scnView.allowsCameraControl = YES;
//
//    // configure the view
//    scnView.backgroundColor = [UIColor blackColor];
//    
//    // add a tap gesture recognizer
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    NSMutableArray *gestureRecognizers = [NSMutableArray array];
//    [gestureRecognizers addObject:tapGesture];
//    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
//    scnView.gestureRecognizers = gestureRecognizers;
}

- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            
            material.emission.contents = [UIColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [UIColor redColor];
        
        [SCNTransaction commit];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//- (IBAction)buttonPressed:(id)sender
//{
//    GLKQuaternion movement = GLKQuaternionMakeWithAngleAndAxis(0.2, 0, 0, 1.0);
//    SCNQuaternion curOrientation = arrow.root.orientation;
//    GLKQuaternion curOrientationQuat = GLKQuaternionMake(curOrientation.x, curOrientation.y, curOrientation.z, curOrientation.w);
//    
//    GLKQuaternion newOrientation = GLKQuaternionMultiply(curOrientationQuat, movement);
//    arrow.root.orientation = SCNVector4Make(newOrientation.x, newOrientation.y, newOrientation.z, newOrientation.w);
//    
//    printf("Position: %f, %f, %f\n", arrow.root.position.x, arrow.root.position.y, arrow.root.position.z);
//    printf("Pivot: %f, %f, %f\n", arrow.root.pivot.m14, arrow.root.pivot.m24, arrow.root.pivot.m34);
//}

- (IBAction)stepperChanged:(id)sender {
    double new_value = self.stepperControl.value;
    
//    GLKQuaternion movement = GLKQuaternionMakeWithAngleAndAxis(0.2, 0, 0, 1.0);
//    SCNQuaternion curOrientation = arrowNode.orientation;
//    GLKQuaternion curOrientationQuat = GLKQuaternionMake(curOrientation.x, curOrientation.y, curOrientation.z, curOrientation.w);
    
//    GLKQuaternion newOrientation = GLKQuaternionMultiply(curOrientationQuat, movement);
    subRotation = -new_value;
    GLKQuaternion newOrientation = GLKQuaternionMakeWithAngleAndAxis(subRotation + baseRotation, 0, 0, 1.0);
    
    [SCNTransaction begin];
    arrow.root.orientation = SCNVector4Make(newOrientation.x, newOrientation.y, newOrientation.z, newOrientation.w);
    [SCNTransaction commit];
}

- (IBAction)sliderChanged:(id)sender {
    double new_value = self.sliderControl.value;
    arrow.setIntensity(new_value);
}

- (IBAction)posBtnPressed:(id)sender {
    arrowTop = !arrowTop;
    if (arrowTop) {
        baseRotation = 0;
        arrow.root.position = SCNVector3Make(0, 1, 0);
    }
    else {
        baseRotation = 3.1415;
        arrow.root.position = SCNVector3Make(0, -0.15, 0);
    }
    arrow.root.rotation = SCNVector4Make(0, 0, 1, subRotation + baseRotation);
}

- (IBAction)wideSwitchToggled:(id)sender {
    arrow.setWide(self.toggleControl.on);
//    arrowWidthFactor = self.toggleControl.on ? 1.5 : 1.0;
    // Make scale change part of an animation
}

- (IBAction)colorChanged:(id)sender {
    switch (self.colorSelector.selectedSegmentIndex) {
        case 0:
            self.topTitle.textColor = UIColor.redColor;
            break;
        case 1:
            self.topTitle.textColor = UIColor.greenColor;
            break;
        case 2:
            self.topTitle.textColor = UIColor.blueColor;
            break;
        default:
            break;
    }
}

// Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    NSAssert(touches.count == 1, @"number of touches != 1");
    
    CGPoint p = [[touches anyObject] locationInView:scnView];
    // check what nodes are tapped
//    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
//    for (SCNHitTestResult *hit in hitResults) {
//        const char* the_name = hit.node.name != nil ? [hit.node.name UTF8String] : "<unknown>";
//        printf("Hit node %s\n", the_name);
//    }
    arrow.touchBegan(hitResults.firstObject);
    return;
}


- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    SCNView *scnView = (SCNView *)self.view;
    
    NSAssert(touches.count == 1, @"number of touches != 1");
    
    CGPoint p = [[touches anyObject] locationInView:scnView];
    GLKVector3 farClipHit = SCNVector3ToGLKVector3([scnView unprojectPoint:SCNVector3Make(p.x, p.y, 1.0)]);
    GLKVector3 cameraPos = SCNVector3ToGLKVector3(cameraNode.position);
    GLKVector3  touchRay = GLKVector3Normalize(GLKVector3Subtract(farClipHit, cameraPos));
    
    GLKVector3 cameraDir = GLKVector3Make(cameraNode.transform.m13, cameraNode.transform.m23, cameraNode.transform.m33);
    float dragValue = arrow.getDragValue(cameraPos, touchRay, cameraDir);
    arrow.setIntensity(dragValue);
    self.sliderControl.value = dragValue;
}

- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    arrow.touchEnded();
}
- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event {
    arrow.touchCancelled();
}

@end
