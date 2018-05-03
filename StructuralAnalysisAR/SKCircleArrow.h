//
//  SKCircleArrow.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 4/10/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef SKCircleArrow_h
#define SKCircleArrow_h

#import <SpriteKit/SpriteKit.h>

@interface SKCircleArrow : SKNode

-(id)initWithWidth:(float)_width radius:(float)_radius;

-(void)setIntensity:(float)value;

-(void)setInputRange:(float)min max:(float)max;

-(void)setAngleRange:(float)min max:(float)max;

@end

#endif /* SKCircleArrow_h */
