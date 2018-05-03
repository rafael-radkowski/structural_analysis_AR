//
//  StaticARManager.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 12/11/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef StaticARManager_hpp
#define StaticARManager_hpp

#include "ARManager.h"

class StaticARManager : public ARManager {
public:
    StaticARManager(UIView* view, SCNScene* scene, GLKMatrix4 desiredPose, NSString* bgImagePath);
    ~StaticARManager() override {};
    void doFrame(int n_avg, std::function<void(CB_STATE)> cb_func) override {};
    bool startAR() override {return false;};
    size_t stopAR() override {return 0;};
    void pauseAR() override {};
    int startCamera() override {return 0;};
    void stopCamera() override {};
    virtual GLKMatrix4 getCameraMatrix() override;
    virtual GLKMatrix4 getProjectionMatrix() override;
    bool isTracked() override { return true; }
    // Background never changes, so we never have to redraw
    void drawBackground() override {};
private:
    GLKMatrix4 cameraMatrix, projectionMatrix;
};
#endif /* StaticARManager_hpp */
