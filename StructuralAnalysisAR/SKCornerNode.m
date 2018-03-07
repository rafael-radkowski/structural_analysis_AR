//
//  SKCornerNode.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 3/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKCornerNode.h"

@implementation SKCornerNode {
    // coordinate bars
    SKSpriteNode *bar1, *bar2;
    // arrow heads, textures
    SKSpriteNode *arrow1, *arrow2;
    // arrow bodies, will change length
    SKSpriteNode *arrowBody1, *arrowBody2;
    float length;
    float width;
    SKLabelNode *label1, *label2;
    
    float min_input, max_input;
    float min_length, max_length;
}

-(id)init {
    return [self initWithTextUp:YES];
}

-(id)initWithTextUp:(bool)textUp {
    if (self = [super init]) {
        min_input = 0;
        max_input = 1;
        min_length = 0;
        max_length = 1;
        length = 100;
        width = 15;
        float arrowGap = width / 2;

        bar1 = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(length, width)];
        bar2 = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:CGSizeMake(length, width)];
        bar2.zRotation = M_PI / 2;
        bar1.anchorPoint = CGPointMake(0, 0);
        bar2.anchorPoint = CGPointMake(0, 1);
        [self addChild:bar1];
        [self addChild:bar2];
        
        arrow1 = [SKSpriteNode spriteNodeWithImageNamed:@"arrow.png"];
        arrow2 = [SKSpriteNode spriteNodeWithImageNamed:@"arrow.png"];
        float arrowSize = arrow1.frame.size.width;
        float arrowScale = width / arrowSize;
        arrow1.xScale = arrow1.yScale = arrow2.xScale = arrow2.yScale = arrowScale;
        
        arrow1.position = CGPointMake(length + width/2. + arrowGap, width/2);
        arrow2.position = CGPointMake(width/2, length + width/2. + arrowGap);
        arrow2.zRotation = M_PI / 2;
        [self addChild:arrow1];
        [self addChild:arrow2];
        
        arrowBody1 = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(1, width / 2)];
        arrowBody2 = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(1, width / 2)];
        arrowBody1.anchorPoint = CGPointMake(0, 0.5);
        arrowBody1.position = CGPointMake(length + arrowGap + width, width/2);
        arrowBody2.anchorPoint = CGPointMake(0, 0.5);
        arrowBody2.position = CGPointMake(width/2, length + arrowGap + width);
        arrowBody2.zRotation = M_PI / 2;
        [self addChild:arrowBody1];
        [self addChild:arrowBody2];
        
        label1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        label2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        label1.text = @"1.234";
        label2.text = @"1.234";
        label1.fontColor = [UIColor blackColor];
        label2.fontColor = [UIColor blackColor];
        if (textUp) {
            label1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            label2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            label1.position = CGPointMake(length + 2, width);
            label2.zRotation = M_PI / 2;
            label2.position = CGPointMake(0, length + 2);
        }
        else {
            label1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            label2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            label1.position = CGPointMake(length + 2, 0);
            label1.zRotation = M_PI;
            label2.position = CGPointMake(width, length + 2);
            label2.zRotation = -M_PI / 2;
        }
        [self addChild:label1];
        [self addChild:label2];
        
    }

    return self;
}

-(void)setForces:(float)force1 force2:(float)force2 {
    float input_range = max_input - min_input;
    float normalized1 = (force1 - min_input) / input_range;
    float normalized2 = (force2 - min_input) / input_range;
    
    float length_range = max_length - min_length;
    float dist1 = normalized1 * length_range + min_length;
    float dist2 = normalized2 * length_range + min_length;
    
    arrowBody1.xScale = dist1;
    arrowBody2.xScale = dist2;
}

-(void)setInputRange:(float)_min max:(float)_max {
    min_input = _min;
    max_input = _max;
}

-(void)setLengthRange:(float)_min max:(float)_max {
    min_length = _min;
    max_length = _max;
}
@end
