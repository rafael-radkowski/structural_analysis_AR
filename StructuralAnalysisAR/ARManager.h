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

#import <Metal/Metal.h>
#import <SceneKit/SceneKit.h>

#include "ARView.h"

class ARManager {
public:
    virtual void initAR() = 0;
    virtual bool startAR() = 0;
    virtual size_t stopAR() = 0;
    virtual void pauseAR() = 0;
    virtual GLKMatrix4 getCameraMatrix() = 0;
    virtual GLKMatrix4 getProjectionMatrix() = 0;
    virtual id<MTLTexture> getBgTexture() = 0;
    virtual GLKMatrix4 getBgMatrix() = 0;
};

#endif /* ARManager_hpp */
