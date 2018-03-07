//
//  SKCornerNode.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//
#ifndef SKCornerNode_h
#define SKCornerNode_h

#import <SpriteKit/SpriteKit.h>

@interface SKCornerNode : SKNode

-(id)init;

-(void)setForces:(float)force1 force2:(float)force2;

@end


#endif /* SKCornerNode_h */
