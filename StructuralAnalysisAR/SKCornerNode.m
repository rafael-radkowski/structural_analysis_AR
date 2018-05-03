//
//  SKCornerNode.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKCornerNode.h"
#import "SKArrow.h"
#import "SKCircleArrow.h"
#import <math.h>

@implementation SKCornerNode {
    // coordinate bars
    SKSpriteNode *bar1, *bar2;
    // arrow entities
    SKArrow *arrowF1, *arrowF2;
    SKArrow *arrowV1, *arrowV2;
    // moment indicators
    SKCircleArrow *moment1, *moment2;
    float length;
    float width;
    SKLabelNode *labelF1, *labelF2;
    SKLabelNode *labelV1, *labelV2;
    SKLabelNode *labelM1, *labelM2;
}

-(id)init {
    return [self initWithTextUp:YES];
}

-(id)initWithTextUp:(bool)textUp {
    if (self = [super init]) {
        length = 100;
        width = 15;
        float radius = length/3;
        float fontSize = 25;

        bar1 = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(length, width)];
        bar2 = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(length, width)];
        bar2.zRotation = M_PI / 2;
        bar1.anchorPoint = CGPointMake(0, 0);
        bar2.anchorPoint = CGPointMake(0, 1);
        [self addChild:bar1];
        [self addChild:bar2];
        
        // force arrows
        arrowF1 = [[SKArrow alloc] initWithWidth:width];
        arrowF2 = [[SKArrow alloc] initWithWidth:width];
        arrowF1.position = CGPointMake(length, width/2);
        arrowF2.position = CGPointMake(width/2, length);
        arrowF2.zRotation = M_PI / 2;
        [self addChild:arrowF1];
        [self addChild:arrowF2];
        
        // shear arrows
        arrowV1 = [[SKArrow alloc] initWithWidth:width];
        arrowV2 = [[SKArrow alloc] initWithWidth:width];
        arrowV1.position = CGPointMake(length, width/2);
        arrowV2.position = CGPointMake(width/2, length);
        arrowV1.zRotation = -M_PI / 2;
        arrowV2.zRotation = M_PI;
        [self addChild:arrowV1];
        [self addChild:arrowV2];
        

        // moment arrows
        moment1 = [[SKCircleArrow alloc] initWithWidth:width radius:radius];
        moment2 = [[SKCircleArrow alloc] initWithWidth:width radius:radius];
        moment1.position = CGPointMake(length, width/2);
        moment2.position = CGPointMake(width/2, length);
        // have start of moment arrows sit on the inside of the corners
        moment1.zRotation = M_PI / 2;
        [self addChild:moment1];
        [self addChild:moment2];

        // Labels
        labelF1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelF2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelF1.fontColor = [UIColor blackColor];
        labelF2.fontColor = [UIColor blackColor];
        labelV1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelV2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelV1.fontColor = [UIColor blackColor];
        labelV2.fontColor = [UIColor blackColor];
        labelM1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelM2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        labelM1.fontColor = [UIColor blackColor];
        labelM2.fontColor = [UIColor blackColor];
        labelF1.fontSize = labelF2.fontSize = labelV1.fontSize = labelV2.fontSize = labelM1.fontSize = labelM2.fontSize = fontSize;
        if (textUp) {
            labelF1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            labelF2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            labelF1.position = CGPointMake(length + 2, width);
            labelF2.position = CGPointMake(0, length + width/2 + 2);
            labelF2.zRotation = M_PI / 2;
            
            labelV1.position = CGPointMake(length - width/2, -2);
            labelV2.position = CGPointMake(-2, length - fontSize - width/2);
            labelV1.zRotation = M_PI / 2;
            labelV1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            labelV2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            
            labelM1.position = CGPointMake(length + fontSize/2, radius + width + 2);
            labelM2.position = CGPointMake(radius + width/2 + fontSize, length);
            labelM1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            labelM2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            labelM1.zRotation = M_PI / 2;
            labelM2.zRotation = M_PI / 2;
        }
        else {
            labelF1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            labelF2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            labelF1.position = CGPointMake(length + width/2 + 2, 0);
            labelF1.zRotation = M_PI;
            labelF2.position = CGPointMake(-2, length + width/2 + 2);
            labelF2.zRotation = M_PI / 2;
            
            labelV1.position = CGPointMake(length - width/2, -2);
            labelV2.position = CGPointMake(-2, length - width/2);
            labelV1.zRotation = M_PI / 2;
            labelV2.zRotation = M_PI;
            labelV1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            labelV2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            
            labelM1.position = CGPointMake(length, radius + width/2 + fontSize + 2);
            labelM2.position = CGPointMake(radius + width + 2, length + fontSize/2);
            labelM1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            labelM2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            labelM1.zRotation = M_PI;
            labelM2.zRotation = M_PI;
        }
        [self addChild:labelF1];
        [self addChild:labelF2];
        [self addChild:labelV1];
        [self addChild:labelV2];
        [self addChild:labelM1];
        [self addChild:labelM2];
    }

    return self;
}

-(void)setForce1:(float)force1 force2:(float)force2 {
    [arrowF1 setIntensity:force1];
    [arrowF2 setIntensity:force2];

    labelF1.text = [NSString stringWithFormat:@"%.1f k", fabs(force1)];
    labelF2.text = [NSString stringWithFormat:@"%.1f k", fabs(force2)];
}

-(void)setShear1:(float)shear1 shear2:(float)shear2 {
    [arrowV1 setIntensity:-shear1];
    [arrowV2 setIntensity:-shear2];
    
    labelV1.text = [NSString stringWithFormat:@"%.1f k", fabs(shear1)];
    labelV2.text = [NSString stringWithFormat:@"%.1f k", fabs(shear2)];
}
-(void)setMoment1:(float)moment_force1 moment2:(float)moment_force2 {
    [moment1 setIntensity:moment_force1];
    [moment2 setIntensity:moment_force2];
    
    labelM1.text = [NSString stringWithFormat:@"%.1f k", fabs(moment_force1)];
    labelM2.text = [NSString stringWithFormat:@"%.1f k", fabs(moment_force2)];
}

-(void)setInputRangeF:(float)_min max:(float)_max {
    [arrowF1 setInputRange:_min max:_max];
    [arrowF2 setInputRange:_min max:_max];
}

-(void)setInputRangeM:(float)_min max:(float)_max {
    [moment1 setInputRange:_min max:_max];
    [moment2 setInputRange:_min max:_max];
}

-(void)setInputRangeV:(float)_min max:(float)_max {
    [arrowV1 setInputRange:_min max:_max];
    [arrowV2 setInputRange:_min max:_max];
}

-(void)setLengthRangeF:(float)_min max:(float)_max {
    [arrowF1 setLengthRange:_min max:_max];
    [arrowF2 setLengthRange:_min max:_max];
}

-(void)setLengthRangeV:(float)_min max:(float)_max {
    [arrowV1 setLengthRange:_min max:_max];
    [arrowV2 setLengthRange:_min max:_max];
}

-(void)setAngleRangeM:(float)_min max:(float)_max {
    [moment1 setAngleRange:_min max:_max];
    [moment2 setAngleRange:_min max:_max];
}
@end
