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
}


-(id)init {
    if (self = [super init]) {
        length = 100;
        width = 15;
        float arrowSpacing = width / 2;
        float arrowMaxLength = length / 2;
        
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
        
        arrow1.position = CGPointMake(length + width/2. + arrowSpacing, width/2);
        arrow2.position = CGPointMake(width/2, length + width/2. + arrowSpacing);
        arrow2.zRotation = M_PI / 2;
        [self addChild:arrow1];
        [self addChild:arrow2];
        
        arrowBody1 = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(arrowMaxLength, width / 2)];
        arrowBody2 = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(arrowMaxLength, width / 2)];
        arrowBody1.anchorPoint = CGPointMake(0, 0.5);
        arrowBody1.position = CGPointMake(length + arrowSpacing + width, width/2);
        arrowBody2.anchorPoint = CGPointMake(0, 0.5);
        arrowBody2.position = CGPointMake(width/2, length + arrowSpacing + width);
        arrowBody2.zRotation = M_PI / 2;
        [self addChild:arrowBody1];
        [self addChild:arrowBody2];
        
        label1 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        label2 = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        label1.text = @"1.234";
        label2.text = @"1.234";
        label1.fontColor = [UIColor blackColor];
        label2.fontColor = [UIColor blackColor];
        label1.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        label2.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        label1.position = CGPointMake(length + 2, width);
        label2.zRotation = M_PI / 2;
        label2.position = CGPointMake(0, length + 2);
        [self addChild:label1];
        [self addChild:label2];
    }

    return self;
}

-(void)setForces:(float)force1 force2:(float)force2 {
    arrowBody1.xScale = force1;
    arrowBody2.xScale = force2;
}

@end
