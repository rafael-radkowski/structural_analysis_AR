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

-(void)setShear1:(float)shear1 shear2:(float)shear2;

-(void)setMoment1:(float)moment_force1 moment2:(float)moment_force2;

-(void)setInputRangeF:(float)min max:(float)max;

-(void)setInputRangeV:(float)min max:(float)max;

-(void)setInputRangeM:(float)min max:(float)max;

-(void)setLengthRangeF:(float)min max:(float)max;

-(void)setLengthRangeV:(float)min max:(float)max;

-(void)setAngleRangeM:(float)min max:(float)max;

@end


#endif /* SKCornerNode_h */
