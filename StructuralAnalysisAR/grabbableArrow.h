//
//  grabbableArrow.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/24/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef grabbableArrow_h
#define grabbableArrow_h

#import <Scenekit/Scenekit.h>
#import <ModelIO/ModelIO.h>
#import <Scenekit/ModelIO.h>
#import <GLKit/GLKit.h>

class GrabbableArrow {
public:
    GrabbableArrow();
    void touchBegan(SCNHitTestResult* hitTestResult);
    float getDragValue(GLKVector3 origin, GLKVector3 touchRay, GLKVector3 cameraDir);
    void touchEnded();
    void touchCancelled();
    
    void setIntensity(float value);
    void setWide(bool wide);
    float widthScale = 1.0;
    
    // Root node for entire arrow
    SCNNode* root;
    
    bool dragging = false;
    
private:
    SCNNode* arrowHead;
    SCNNode* arrowBase;
};

#endif /* grabbableArrow_h */
