//
//  SKArrow.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 4/10/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKArrow.h"

@implementation SKArrow {
    SKNode* root;
    
    // arrow heads, textures
    SKSpriteNode *arrowTip;
    // arrow bodies, will change length
    SKSpriteNode *arrowBody;

    float width;
    float min_input, max_input;
    float min_length, max_length;
}

-(id)initWithWidth:(float)_width {
    if (self = [super init]) {
        min_input = 0;
        max_input = 1;
        min_length = 0;
        max_length = 1;
        width = _width;
        float arrowGap = width / 2;
        
        root = [SKNode node];
        
        arrowTip = [SKSpriteNode spriteNodeWithImageNamed:@"arrow.png"];
        float arrowSize = arrowTip.frame.size.width;
        float arrowScale = width / arrowSize;
        arrowTip.xScale = arrowTip.yScale = arrowScale;
        arrowTip.position = CGPointMake(width/2. + arrowGap, 0);
        [root addChild:arrowTip];
        
        arrowBody = [SKSpriteNode spriteNodeWithColor:[UIColor greenColor] size:CGSizeMake(1, width / 2)];
        arrowBody.anchorPoint = CGPointMake(0, 0.5);
        arrowBody.position = CGPointMake(arrowGap + width, 0);
        
        [root addChild:arrowBody];
        
        [self addChild:root];
    }
    return self;
}

-(void)setIntensity:(float)value {
    float input_range = max_input - min_input;
    float normalized = (value - min_input) / input_range;
    
    root.zRotation = (normalized < 0) ? M_PI : 0;
    
    float length_range = max_length - min_length;
    float dist = fabs(normalized) * length_range + min_length;
    
    root.position = CGPointMake(normalized < 0 ? dist + 2*width : 0, 0);
    arrowBody.xScale = dist;
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
