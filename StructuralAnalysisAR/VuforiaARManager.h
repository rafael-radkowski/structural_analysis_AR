//
//  VuforiaARManager.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/15/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef VuforiaARManager_hpp
#define VuforiaARManager_hpp

#include <memory>

#import <Metal/Metal.h>

#import <Vuforia/Matrices.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/State.h>
#import <Vuforia/DataSet.h>

#include "ARManager.h"
#include "SampleApplicationSession.h"

#include <stdio.h>

class VuforiaARManager : public ARManager, SampleApplicationControlCpp {
public:
    VuforiaARManager(ARView* view, SCNScene* scene, int VuforiaInitFlags, UIInterfaceOrientation ARViewOrientation);
    ~VuforiaARManager() override;
    void doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) override;
    bool startAR() override;
    size_t stopAR() override;
    void pauseAR() override;
    void startCamera() override;
    void stopCamera() override;
    GLKMatrix4 getCameraMatrix() override;
    GLKMatrix4 getProjectionMatrix() override;
    
    // For SampleApplicationControlCpp
    void onInitARDone(NSError* error) override;
    bool doInitTrackers() override;
    bool doLoadTrackersData() override;
    bool doStartTrackers() override;
    bool doStopTrackers() override;
    bool doUnloadTrackersData() override;
    bool doDeinitTrackers() override;
    
    // get called by Vuforia library
    void onVuforiaUpdate(Vuforia::State* state) override;
private:
    Vuforia::DataSet* loadObjectTrackerDataSet(NSString* dataFile);
    bool activateDataSet(Vuforia::DataSet* theDataSet);
    bool deactivateDataSet(Vuforia::DataSet* thedataSet);
    bool setExtendedTrackingForDataSet(Vuforia::DataSet* theDataSet, bool start);
    
    // utilities
    GLKMatrix4 GLKMatrix4FromQCARMatrix44(const Vuforia::Matrix44F& matrix);
    
    ARView* view;
    SCNScene* scene;
    SampleApplicationSession* vapp;
    
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 cameraMatrix;
    
    id<MTLTexture> videoTexture;
    id<MTLTexture> staticBgTex;
    GLKMatrix4 bgImgScale;
    
    Vuforia::DataSet*  dataSetStonesAndChips = nullptr;
    Vuforia::DataSet*  dataSetCurrent = nullptr;
    bool extendedTrackingEnabled;
};


//class VuforiaARManager : ARManager {
//public:
//    VuforiaARManager(ARView* view, int VuforiaInitFlags, UIInterfaceOrientation ARViewOrientation);
//    virtual void initAR();
//    virtual bool startAR();
//    virtual void stopAR();
//    virtual void pauseAR();
//    virtual id<MTLTexture> getBgTexture();
//    virtual SCNMatrix4 getBgMatrix();
//private:
//    // Private methods
//    bool checkIsRetinaDisplay();
//
//    ARView* view;
//
//
//    Vuforia::VideoMode videoMode;
//    bool isRetinaDisplay;
//    bool cameraIsStarted;
//    Vuforia::Matrix44F projectionMatrix;
//    // Orthographic projection matrix, used when rendering the video background
//    Vuforia::Matrix44F orthoProjMatrix;
//
//    // Viewport geometry
//    @struct tagViewport {
//        int posX;
//        int posY;
//        int sizeX;
//        int sizeY;
//    } viewport;
//
//    UIInterfaceOrientation mARViewOrientation;
//    BOOL mIsActivityInPortraitMode;
//    BOOL cameraIsActive;
//    BOOL mIsMetalRendering;
//    // *** Metal ***
//    // Projection matrix scale factors, used when rendering with Metal if the
//    // aspect ratios of the viewport and video do not match due to the viewport
//    // bounds being limited by the size of the render buffer (screen)
//    //
//    float projectionScaleX;
//    float projectionScaleY;
//    float orthoProjScaleX;
//    float orthoProjScaleY;
//
//
//    // SampleApplicationControl delegate (receives callbacks in response to particular
//    // events, such as completion of Vuforia initialisation)
//    id delegate;
//
//
//    // --- Data private to this unit ---
//
//    // instance of the seesion
//    // used to support the Vuforia callback
//    // there should be only one instance of a session
//    // at any given point of time
//    SampleApplicationSession* instance = nil;
//
//    // Vuforia initialisation flags (passed to Vuforia before initialising)
//    int mVuforiaInitFlags;
//
//    // camera to use for the session
//    Vuforia::CameraDevice::CAMERA_DIRECTION mCamera = Vuforia::CameraDevice::CAMERA_DIRECTION_DEFAULT;
//
//    // class used to support the Vuforia callback mechanism
//    class VuforiaApplication_UpdateCallback : public Vuforia::UpdateCallback {
//        virtual void Vuforia_onUpdate(Vuforia::State& state);
//    } vuforiaUpdate;
//
//    // NSerror domain for errors coming from the Sample application template classes
//    NSString * SAMPLE_APPLICATION_ERROR_DOMAIN = @"vuforia_sample_application";
//
//    const float orthoProjectionMatrix[] =
//    {
//        1.0f, 0.0f, 0.0f, 0.0f,
//        0.0f, 1.0f, 0.0f, 0.0f,
//        0.0f, 0.0f, -1.0f, 0.0f,
//        0.0f, 0.0f, 0.0f, 1.0f
//    };
//}

#endif /* VuforiaARManager_hpp */
