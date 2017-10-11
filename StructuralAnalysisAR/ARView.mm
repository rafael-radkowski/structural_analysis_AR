//
//  ARView.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "ARView.h"

#include <Vuforia/Vuforia.h>
#include <Vuforia/Vuforia_iOS.h>
#include <Vuforia/State.h>
#include <Vuforia/Frame.h>
#include <Vuforia/Renderer.h>
#include <Vuforia/MetalRenderer.h>
#include <Vuforia/VideoBackgroundTextureInfo.h>

@implementation ARView
@synthesize vapp = vapp;

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app backgroundTex:(id<MTLTexture>) tex {
    self = [super initWithFrame:frame];
    if (self) {
        vapp = app;
        videoTexture = tex;
        
    }
    
    return self;
}

- (void)renderFrameVuforia {
    if (! vapp.cameraIsStarted) {
        printf("failing\n");
        return;
    }
    
    Vuforia::Renderer& renderer = Vuforia::Renderer::getInstance();
    static bool once = false;
    if (!once) {
        Vuforia::MetalTextureData texData(videoTexture);
        renderer.setVideoBackgroundTexture(texData);
        once = true;
    }
    printf("render\n");
    static Vuforia::MetalTextureUnit unit;
    unit.mTextureIndex = 0;
    renderer.updateVideoBackgroundTexture(&unit);
}
@end
