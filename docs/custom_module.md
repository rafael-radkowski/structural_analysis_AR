---
layout: page
title: Adding your own module
---
# Adding a custom scene

You may want to extend the app to work with your own buildings, or display your own lessons.
To do so, you will have to implement your desired behavior.
The code is structured so that to add a new module, you only need to subclass StructureScene and implement the necessary methods.
GameViewController will initialize your scene and handle managing all the augmented reality aspects.

## StructureScene class

### `- (id) initWithController:(id<ARViewController>)controller`
Initializer for your module.
You don't need to do anything here, but you may want to store a handle to `controller`, in case you want to let it know things like the main menu or screenshot button were pressed.

### `- (SCNNode*) createScene:(SCNView*)scnView skScene:(SKScene*)skScene withCamera:(SCNNode*)camera`
This is where to do all your 3D scene creation, using the ScneKit APIs and possibly pre-made objects like `GrabbableArrow`, `BezierLine`, or others.
You also need to set up the lighting and any other scenegraph manipulation.

### `- (void) setupUIWithScene:(SCNView*)scnView screenBounds:(CGRect)screenRect isGuided:(bool)guided`
Here you will create the 2D user interface using UIKit.
Typically this will involve loading a Nib that you have created in the XCode [Interface Builder](https://developer.apple.com/xcode/interface-builder/).

### `- (void) skUpdate`
This function is called every time SpriteKit (2D graphics renderer) updates.
This is important to know, because if using 2D overlays, such as `OverlayLabel`, they need their `doUpdate()` method called during this phase.
Modifying Spritekit objects at a different time can cause the app to become unstable.

### `- (void) scnRendererUpdateAt:(NSTimeInterval)time`
Similar to skUpdate, but for the SceneKit (3D) renderer.
If using a BezierLine that you want to modify in real-time, here is when you should call its `updatePath()` method.
Unlike SpriteKit objects, it's fine to change SceneKit objects' transformations outside of this method.

### `- (void)setCameraLabelPaused:(bool)isPaused isEnabled:(bool)enabled`
Called to inform this module that thei "Pause Camera" UI button should be updated, either to indicate the scene is paused, and/or to indicate the button should be disabled.

### `- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event`
Callback for the start of a touch on the 3d scene.
If using draggable objects, can pass on the touch event to them with their `touchBegan` method.

### `- (void)touchesMoved:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event`
Callback for a touch moving (dragging).

### `- (void)touchesEnded:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event`
Callback for a touch ending (finger lifted).

### `- (void)touchesCancelled:(NSSet<UITouch *> *) touches withEvent:(UIEvent *)event`
Callback for a touch being cancelled, e.g. a phone call was received during dragging.

### `- (ARManager*)makeStaticTracker`
Should return a new instance of an ARManager for no tracking.
Can instantiate StaticARManager with a pose and background image to do this.

### `- (ARManager*)makeIndoorTracker`
Should return an ARManager for indoor tracking.
Can instantiate a VuforiaARManager with a Vuforia target and transformation offset.

### `- (ARManager*)makeOutdoorTracker`
Need to return an ARManager for outdoor tracking.
cvARManager is intended for outdoor tracking and can be used here.
See the following section for info on how to extend it for your own buildings.

## Extending cvARManager
TODO

## Linking in custom scene
Once a new StructureScene subclass has been created, the only thing left to do is add a button on the "Main" storyboard, add a segue for your module to GameViewController, and modify `MainPageViewController::prepareForSegue` to set your class as the `viewController.sceneClass` before seguing.
