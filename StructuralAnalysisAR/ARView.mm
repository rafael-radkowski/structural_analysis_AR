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
#include <Vuforia/VideoBackgroundConfig.h>

@implementation ARView
@synthesize vapp = vapp;

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app{
    self = [super initWithFrame:frame];
    if (self) {
        vapp = app;
        
    }
    
    return self;
}

- (void)setVideoTexture:(id<MTLTexture>) tex {
    videoTexture = tex;
}

- (void)renderFrameVuforia {
    if (! vapp.cameraIsStarted || !videoTexture) {
        printf("failing\n");
        return;
    }
    
    Vuforia::Renderer& renderer = Vuforia::Renderer::getInstance();
    renderer.begin();
    static bool once = false;
    if (!once) {
//        const Vuforia::VideoBackgroundConfig config = renderer.getVideoBackgroundConfig();
        
//        printf("bg config: pos: (%d, %d), size: (%d, %d)\n", config.mPosition.data[0], config.mPosition.data[1], config.mSize.data[0], config.mSize.data[1]);
        
        Vuforia::MetalTextureData texData(videoTexture);
        renderer.setVideoBackgroundTexture(texData);
        once = true;
    }
    static Vuforia::MetalTextureUnit unit;
    unit.mTextureIndex = 0;
    renderer.updateVideoBackgroundTexture(&unit);
    renderer.end();
}
@end
