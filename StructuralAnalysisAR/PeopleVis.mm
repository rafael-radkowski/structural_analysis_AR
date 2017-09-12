//
//  PeopleVis.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/11/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "PeopleVis.h"

PeopleVis::PeopleVis(int n, SCNNode* camera) {
    root = [SCNNode node];
//    MDLTexture* texture = [MDLTexture textureNamed:@"stick_man.png"];
    
    for (int i = 0; i < n; ++i) {
        SCNPlane* plane = [SCNPlane planeWithWidth:10 height:10];
//        for (SCNGeometrySource* geomSrc in [plane geometrySourcesForSemantic:@"kGeometrySourceSemanticTexcoord"]) {
//            printf("b/cm: %ld\n", geomSrc.bytesPerComponent);
//            for (int i = 0; i < geomSrc.vectorCount; ++i) {
//                for (int c = 0; c < geomSrc.componentsPerVector; ++c) {
//                    printf("%f ", *(reinterpret_cast<const float*>(static_cast<const Byte*>(geomSrc.data.bytes) + geomSrc.dataOffset + (i * geomSrc.dataStride) + (c * geomSrc.bytesPerComponent)) ));
//                }
//                printf("\n");
//            }
//        }
        SCNNode* billboard = [SCNNode nodeWithGeometry:plane];
        billboard.constraints = [NSArray arrayWithObject:[SCNBillboardConstraint billboardConstraint]];
        
        SCNMaterial* mat = [SCNMaterial material];
//        mat.diffuse.contents = [SCNMaterialProperty materialPropertyWithContents:@"stick_man.png"];
        mat.diffuse.contents = [UIImage imageNamed:@"stick_man.png"];
        mat.lightingModelName = SCNLightingModelConstant;
        billboard.geometry.firstMaterial = mat;
        
        billboards.push_back(billboard);
        [root addChildNode:billboard];
    }
}

void PeopleVis::addAsChild(SCNNode *node) {
    [node addChildNode:root];
}

void PeopleVis::setPosition(GLKVector3 pos) {
    root.position = SCNVector3FromGLKVector3(pos);
}
