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

-(id)initWithTextUp:(bool)textUp;

-(void)setForce1:(float)force1 force2:(float)force2;

-(void)setInputRange:(float)min max:(float)max;

-(void)setLengthRange:(float)min max:(float)max;

@end


#endif /* SKCornerNode_h */
