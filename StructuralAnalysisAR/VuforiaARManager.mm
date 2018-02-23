//
//  VuforiaARManager.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/15/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <GLKit/GLKMatrix4.h>

#include "VuforiaARManager.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/Image.h>

#include "SampleApplicationUtils.h"


VuforiaARManager::VuforiaARManager(ARView* view, SCNScene* scene, UIInterfaceOrientation ARViewOrientation, NSString* dataset_path, GLKMatrix4 pose_transform)
 : view(view)
 , scene(scene)
 , pose_transform(pose_transform) {
     datasetPath = dataset_path;
     // Get this property here to be used in onInitARDone, since we can only access this from the main thread
     viewSize = view.frame.size;
     vapp = [[SampleApplicationSession alloc] initWithDelegate:this];
     [vapp initAR:Vuforia::METAL orientation:ARViewOrientation];
     
     [view setVuforiaApp:vapp];
}

VuforiaARManager::~VuforiaARManager() {
    stopAR();
}

void VuforiaARManager::doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) {
    
}

void VuforiaARManager::startCamera() {
    NSError* error = [NSError alloc];
    [vapp resumeAR:&error];
    if (error) {printf("Failed to call resumeAR\n");}
    view.renderVideo = true;
}

void VuforiaARManager::stopCamera() {
    NSError* error = [NSError alloc];
    [vapp pauseAR:&error];
    if (error) {printf("Failed to call pauseAR\n");}
    view.renderVideo = false;
}

bool VuforiaARManager::startAR() {
    return false;
}

size_t VuforiaARManager::stopAR() {
    NSError* error;
    [vapp stopAR:&error];
    return error.code;
}

void VuforiaARManager::pauseAR() {
    
}


void VuforiaARManager::onVuforiaUpdate(Vuforia::State* state) {
//    const float kObjectScaleNormal = 1;
    
    projectionMatrix = GLKMatrix4FromQCARMatrix44(vapp.projectionMatrix);
    projectionMatrix.m11 = -projectionMatrix.m11;
    projectionMatrix.m22 = -projectionMatrix.m22;
    projectionMatrix.m23 = -projectionMatrix.m23;
    
    // The number of frames that have not been tracked
    static int missed_frames = 0;
    if (state->getNumTrackableResults()) {
        is_tracked = true;
        missed_frames = 0; // reset missed frames count
        
        const Vuforia::TrackableResult* track_result = state->getTrackableResult(0);
        
        Vuforia::Matrix44F modelViewMatrix = Vuforia::Tool::convertPose2GLMatrix(track_result->getPose());
//        SampleApplicationUtils::translatePoseMatrix(10.0f, -21.0f, 0, &modelViewMatrix.data[0]);
        //        SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
        
        
//        SampleApplicationUtils::rotatePoseMatrix(180, 0, 1, 0, &modelViewMatrix.data[0]);
//        [SampleApplicationUtils::translatePoseMatrix(self.x_stepper_thing.value, self.y_stepper_thing.value, self.z_stepper_thing.value, &modelViewMatrix.data[0]);]
        
        // Calculate inverse matrix and assign it to cameraNode
        GLKMatrix4 extrinsic = GLKMatrix4FromQCARMatrix44(modelViewMatrix);
        bool invertible;
        GLKMatrix4 inverted = GLKMatrix4Invert(extrinsic, &invertible); // inverse matrix!
        inverted = GLKMatrix4Multiply(pose_transform, inverted);
        assert(invertible);
        cameraMatrix = GLKMatrix4Make(inverted.m00,  inverted.m01,   inverted.m02, 0,
                                               -inverted.m10,  -inverted.m11,  -inverted.m12, 0,
                                               -inverted.m20,  -inverted.m21,  -inverted.m22, 0,
                                               inverted.m30, inverted.m31, inverted.m32, 1);
    }
    else {
        missed_frames++;
        // Say that tracking has been lost if we've missed more than 8 frames
        if (missed_frames >= 10) {
            is_tracked = false;
        }
    }
}

GLKMatrix4 VuforiaARManager::getCameraMatrix() {
    return cameraMatrix;
}

GLKMatrix4 VuforiaARManager::getProjectionMatrix() {
    return projectionMatrix;
}

bool VuforiaARManager::isTracked() {
    return is_tracked;
}


void VuforiaARManager::onInitARDone(NSError* initError) {
    if (initError == nil) {
        NSError * error = nil;
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
        // Create texture for holding video
        MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:vapp.videoMode.mWidth height:vapp.videoMode.mHeight mipmapped:NO];
        id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
        videoTexture = [gpu newTextureWithDescriptor:texDescription];
        staticBgTex = [gpu newTextureWithDescriptor:texDescription];
        [view setVideoTexture:videoTexture];

        
        // Calculate texture coordinate scaling to make video fit
        // Vuforia expects this scaling for augmentations to match
        float aspectVideo = (float)vapp.videoMode.mWidth / vapp.videoMode.mHeight;
        float aspectScreen = (float)viewSize.width / viewSize.height;
        float xScale, yScale;
        xScale = yScale = 1;
        if (aspectVideo > aspectScreen) {
            xScale = aspectScreen / aspectVideo;
        }
        else {
            yScale = aspectVideo / aspectScreen;
        }
        bgImgScale = GLKMatrix4MakeScale(xScale, yScale, 1);
        
//        // Set background to texture with scaling
        scene.background.contents = videoTexture;
        scene.background.contentsTransform = SCNMatrix4FromGLKMatrix4(bgImgScale);
//        [self setAREnabled:YES];
//
//        //        [eaglView updateRenderingPrimitives];
//
//        // by default, we try to set the continuous auto focus mode
//        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
        //[eaglView configureBackground];
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
//        dispatch_async( dispatch_get_main_queue(), ^{
//
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                            message:[initError localizedDescription]
//                                                           delegate:self
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
//        });
    }
}

bool VuforiaARManager::doInitTrackers() {
    // Initialize the object tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

bool VuforiaARManager::doLoadTrackersData() {
    dataSetStonesAndChips = loadObjectTrackerDataSet(datasetPath);
    if (dataSetStonesAndChips == NULL) {
        NSLog(@"Failed to load datasets");
        return NO;
    }
    if (! activateDataSet(dataSetStonesAndChips)) {
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    
    
    return YES;
}

bool VuforiaARManager::doStartTrackers() {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

bool VuforiaARManager::doStopTrackers() {
    // Stop the tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

bool VuforiaARManager::doUnloadTrackersData() {
    deactivateDataSet(dataSetCurrent);
    dataSetCurrent = nil;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    if (!objectTracker->destroyDataSet(dataSetStonesAndChips))
    {
        NSLog(@"Failed to destroy data set Stones and Chips.");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

bool VuforiaARManager::doDeinitTrackers() {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return YES;
}

Vuforia::DataSet* VuforiaARManager::loadObjectTrackerDataSet(NSString *dataFile) {
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}


bool VuforiaARManager::activateDataSet(Vuforia::DataSet* theDataSet) {
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        deactivateDataSet(dataSetCurrent);
    }
    BOOL success = NO;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        setExtendedTrackingForDataSet(dataSetCurrent, extendedTrackingEnabled);
    }
    
    return success;
}


bool VuforiaARManager::deactivateDataSet(Vuforia::DataSet* theDataSet) {
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    setExtendedTrackingForDataSet(theDataSet, NO);
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}


bool VuforiaARManager::setExtendedTrackingForDataSet(Vuforia::DataSet* theDataSet, bool start) {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

//- (void)printMatrix:(GLKMatrix4)mat {
//    printf("%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
//           mat.m[0], mat.m[1], mat.m[2], mat.m[3], mat.m[4], mat.m[5], mat.m[6], mat.m[7], mat.m[8], mat.m[9], mat.m[10], mat.m[11], mat.m[12], mat.m[13], mat.m[14], mat.m[15]);
//}
GLKMatrix4 VuforiaARManager::GLKMatrix4FromQCARMatrix44(const Vuforia::Matrix44F& matrix) {
    GLKMatrix4 glkMatrix;
    
    for(int i=0; i<16; i++) {
        glkMatrix.m[i] = matrix.data[i];
    }
    //    printf("m10: %f, m[1] = %f, m[4] = %f\n", glkMatrix.m10, glkMatrix.m[1], glkMatrix.m[4]);
    
    return glkMatrix;
}

