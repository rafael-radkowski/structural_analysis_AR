//
//  StaticARManager.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 12/11/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "StaticARManager.h"

#import <GLKit/GLKMatrix4.h>
#import <MetalKit/MetalKit.h>

StaticARManager::StaticARManager(UIView* view, SCNScene* scene) {
    UIImage* bgImage = [UIImage imageNamed:@"skywalk_1920_back.png"];
//    int img_width = bgImage.size.width;
//    int img_height = bgImage.size.height;
    
//    MTLTextureDescriptor* texDescription = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:img_width height:img_height mipmapped:NO];
    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    MTKTextureLoader* texLoader = [[MTKTextureLoader alloc] initWithDevice:gpu];
    // Set as sRGB to be correct color
    NSDictionary* mtkLoaderOptions = @{ MTKTextureLoaderOptionSRGB: @0 };
    NSError* error = [NSError alloc];
    id<MTLTexture> staticBgTex = [texLoader newTextureWithData:UIImagePNGRepresentation(bgImage) options:mtkLoaderOptions error:&error];
    if (error) {
        printf("Failed to load static background image\n");
    }
    
    scene.background.contents = staticBgTex;
    
    
    float aspectScreen = (float)view.frame.size.width / view.frame.size.height;
    projectionMatrix = GLKMatrix4MakePerspective(36.909 * (M_PI / 180.0), aspectScreen, 0.1, 500);
    
    cameraMatrix = GLKMatrix4Make(
                                  -0.987822, -0.009307, 0.155310, 0.000000,
                                  -0.045182, 0.981796, -0.184486, 0.000000,
                                  -0.154240, -0.189710, -0.969649, 0.000000,
                                  -8.753870, -31.452150, -204.253311, 1.000000);
}


GLKMatrix4 StaticARManager::getCameraMatrix() {
    return cameraMatrix;
}

GLKMatrix4 StaticARManager::getProjectionMatrix() {
    return projectionMatrix;
}

