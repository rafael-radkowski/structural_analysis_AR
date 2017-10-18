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

//- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app{
//    self = [super initWithFrame:frame];
//    if (self) {
//        vapp = app;
//        
//    }
//    
//    return self;
//}

- (void)setVuforiaApp:(SampleApplicationSession *) app {
    printf("setVuforiaApp\n");
    vapp = app;
}

- (void)setVideoTexture:(id<MTLTexture>) tex {
    videoTexture = tex;
    textureInitialized = false;
}

// TODO: Not sure if it's guaranteed that this is called at the right time during the SceneKit render loop. There could be thread conflicts?
- (void)renderFrameVuforia {
    if (!self.renderVideo || !vapp.cameraIsStarted || !videoTexture) {
        return;
    }
    
    Vuforia::Renderer& renderer = Vuforia::Renderer::getInstance();
    renderer.begin();
    if (!textureInitialized) {
        printf("!!!!!!!!!initializing\n");
//        const Vuforia::VideoBackgroundConfig config = renderer.getVideoBackgroundConfig();
        
//        printf("bg config: pos: (%d, %d), size: (%d, %d)\n", config.mPosition.data[0], config.mPosition.data[1], config.mSize.data[0], config.mSize.data[1]);
        
        Vuforia::MetalTextureData texData(videoTexture);
        renderer.setVideoBackgroundTexture(texData);
        textureInitialized = true;
    }
    static Vuforia::MetalTextureUnit unit;
    unit.mTextureIndex = 0;
    renderer.updateVideoBackgroundTexture(&unit);
    renderer.end();
}
@end
