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
    
    
    // Import the arrow object
    NSString *arrowPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"arrow"] ofType:@"obj"];
    NSURL *arrowUrl = [NSURL fileURLWithPath:arrowPath];
    MDLAsset *arrowAsset = [[MDLAsset alloc] initWithURL:arrowUrl];
    arrowNode = [SCNNode nodeWithMDLObject:[arrowAsset objectAtIndex:0]];
    
    // Make material for arrow
    SCNMaterial *arrowMat = [SCNMaterial material];
    arrowMat.diffuse.contents = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0];
    arrowNode.geometry.firstMaterial = arrowMat;
    
    // Create a parent object for the arrow
    arrowBase = [SCNNode node];
    [scene.rootNode addChildNode:arrowBase];
    [arrowBase addChildNode:arrowNode];
    
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

- (IBAction)buttonPressed:(id)sender
{
    GLKQuaternion movement = GLKQuaternionMakeWithAngleAndAxis(0.2, 0, 0, 1.0);
    SCNQuaternion curOrientation = arrowNode.orientation;
    GLKQuaternion curOrientationQuat = GLKQuaternionMake(curOrientation.x, curOrientation.y, curOrientation.z, curOrientation.w);
    
    GLKQuaternion newOrientation = GLKQuaternionMultiply(curOrientationQuat, movement);
    arrowNode.orientation = SCNVector4Make(newOrientation.x, newOrientation.y, newOrientation.z, newOrientation.w);
    
    printf("Position: %f, %f, %f\n", arrowNode.position.x, arrowNode.position.y, arrowNode.position.z);
    printf("Pivot: %f, %f, %f\n", arrowNode.pivot.m14, arrowNode.pivot.m24, arrowNode.pivot.m34);
}

- (IBAction)stepperChanged:(id)sender {
    double new_value = self.stepperControl.value;
    
//    GLKQuaternion movement = GLKQuaternionMakeWithAngleAndAxis(0.2, 0, 0, 1.0);
//    SCNQuaternion curOrientation = arrowNode.orientation;
//    GLKQuaternion curOrientationQuat = GLKQuaternionMake(curOrientation.x, curOrientation.y, curOrientation.z, curOrientation.w);
    
//    GLKQuaternion newOrientation = GLKQuaternionMultiply(curOrientationQuat, movement);
    GLKQuaternion newOrientation = GLKQuaternionMakeWithAngleAndAxis(-new_value, 0, 0, 1.0);
    
    arrowNode.orientation = SCNVector4Make(newOrientation.x, newOrientation.y, newOrientation.z, newOrientation.w);
}

- (IBAction)sliderChanged:(id)sender {
    double new_value = self.sliderControl.value;
    
    // adjust scale
    arrowScale = ((new_value - 0.5) * 0.6) + 1;
    arrowNode.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
    
    // adjust color
    double reverse_value = 1 - new_value;
    double hue = 0.667 * reverse_value;
    arrowNode.geometry.firstMaterial.diffuse.contents = [[UIColor alloc] initWithHue:hue saturation:1.0 brightness:0.8 alpha:1.0];
}

- (IBAction)posBtnPressed:(id)sender {
    arrowTop = !arrowTop;
    if (arrowTop) {
        arrowBase.rotation = SCNVector4Make(0, 0, 1, 0);
        arrowBase.position = SCNVector3Make(0, 1, 0);
    }
    else {
        arrowBase.rotation = SCNVector4Make(0, 0, 1, 3.1415);
        arrowBase.position = SCNVector3Make(0, -0.15, 0);
    }
}

- (IBAction)wideSwitchToggled:(id)sender {
    arrowWidthFactor = self.toggleControl.on ? 1.5 : 1.0;
    arrowNode.scale = SCNVector3Make(arrowScale * arrowWidthFactor, arrowScale, arrowScale * arrowWidthFactor);
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
@end
