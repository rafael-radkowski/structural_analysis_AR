//
//  ARManager.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 11/14/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef ARManager_hpp
#define ARManager_hpp

#include <stdio.h>
#include <functional>

#import <Metal/Metal.h>
#import <SceneKit/SceneKit.h>

#include "ARView.h"

class ARManager {
public:
    virtual ~ARManager() {};
    virtual bool startAR() = 0;
    enum CB_STATE {
        DONE_CAPTURING // When all frames to be captured have been saved, but not necessarily processed yet
    };
    virtual void doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) = 0;
    virtual size_t stopAR() = 0;
    virtual void pauseAR() = 0;
    virtual void startCamera() = 0;
    virtual void stopCamera() = 0;
    virtual GLKMatrix4 getCameraMatrix() = 0;
    virtual GLKMatrix4 getProjectionMatrix() = 0;
    virtual bool isTracked() = 0;
};

#endif /* ARManager_hpp */
