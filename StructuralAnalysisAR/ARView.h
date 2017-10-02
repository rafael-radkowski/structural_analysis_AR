//
//  ARView.hpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/29/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#ifndef ARView_hpp
#define ARView_hpp

#import <UIKit/UIKit.h>

#import <Vuforia/UIGLViewProtocol.h>

#import "Texture.h"
#import "SampleApplicationSession.h"
#import "SampleApplication3DModel.h"
#import "SampleGLResourceHandler.h"
#import "SampleAppRenderer.h"


// EAGLView is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
//@interface ImageTargetsEAGLView : UIView <UIGLViewProtocol, SampleGLResourceHandler, SampleAppRendererControl> {
//@private
//    // OpenGL ES context
//    EAGLContext *context;
//    
//    // The OpenGL ES names for the framebuffer and renderbuffers used to render
//    // to this view
//    GLuint defaultFramebuffer;
//    GLuint colorRenderbuffer;
//    GLuint depthRenderbuffer;
//    
//    // Shader handles
//    GLuint shaderProgramID;
//    GLint vertexHandle;
//    GLint normalHandle;
//    GLint textureCoordHandle;
//    GLint mvpMatrixHandle;
//    GLint texSampler2DHandle;
//    
//    // Texture used when rendering augmentation
//    Texture* augmentationTexture[kNumAugmentationTextures];
//    
//    BOOL offTargetTrackingEnabled;
//    SampleApplication3DModel * buildingModel;
//    
//    SampleAppRenderer * sampleAppRenderer;
//}
//
//@property (nonatomic, weak) SampleApplicationSession * vapp;
//
//- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app;
//
//- (void)finishOpenGLESCommands;
//- (void)freeOpenGLESResources;
//
//- (void) setOffTargetTrackingMode:(BOOL) enabled;
//- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight;
//- (void) updateRenderingPrimitives;
//@end


#endif /* ARView_hpp */
