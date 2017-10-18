//
//  ARView.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Vuforia/UIGLViewProtocol.h>
#import <Metal/Metal.h>
#import <SceneKit/Scenekit.h>

#import "SampleApplicationSession.h"


#ifndef ARView_hpp
#define ARView_hpp

@interface ARView : SCNView <UIGLViewProtocol> {
    id<MTLTexture> videoTexture;
    bool textureInitialized;
    
}

@property (nonatomic, weak) SampleApplicationSession * vapp;
@property (nonatomic) bool renderVideo;

- (void)setVuforiaApp:(SampleApplicationSession *) app;
//- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *)app;
- (void)setVideoTexture:(id<MTLTexture>) tex;
- (void)renderFrameVuforia;
@end

#endif /* ARView_hpp */
