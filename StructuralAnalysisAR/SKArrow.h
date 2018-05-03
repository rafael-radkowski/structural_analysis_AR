//
//  SKArrow.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 4/10/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef SKArrow_h
#define SKArrow_h

#import <SpriteKit/SpriteKit.h>

@interface SKArrow : SKNode

-(id)initWithWidth:(float)_width;

-(void)setIntensity:(float)value;

-(void)setInputRange:(float)min max:(float)max;

-(void)setLengthRange:(float)min max:(float)max;

@end

#endif /* SKArrow_h */
