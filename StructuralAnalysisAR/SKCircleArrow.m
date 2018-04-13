//
//  SKCircleArrow.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 4/10/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <CoreGraphics/CGPath.h>
#import "SKCircleArrow.h"
#import <math.h>

@implementation SKCircleArrow {
    SKShapeNode* arcStroke;
    SKSpriteNode* arrowTip;
    float width, radius;
    float min_input, max_input;
    float min_angle, max_angle;
    
}

-(id)initWithWidth:(float)_width radius:(float)_radius {
    if (self = [super init]) {
        min_input = 0;
        max_input = 1;
        min_angle = 0;
        max_angle = M_PI;
        width = _width;
        radius = _radius;


//        arcStroke = [SKShapeNode shapeNodeWithPath:CFAutorelease(CGPathCreateMutable())];
        arcStroke = [SKShapeNode shapeNodeWithPath:CGPathCreateMutable()];
        arcStroke.fillColor = [UIColor greenColor];
        arcStroke.lineWidth = 0;
        [self addChild:arcStroke];
        
        arrowTip = [SKSpriteNode spriteNodeWithImageNamed:@"arrow.png"];
        arrowTip.anchorPoint = CGPointMake(1, 0.5);
        float arrowSize = arrowTip.frame.size.width;
        float arrowScale = width / arrowSize;
        arrowTip.xScale = arrowTip.yScale = arrowScale;
//        arrowTip.position = CGPointMake(width/2. + arrowGap, 0);
        [self addChild:arrowTip];
        
        [self setIntensity:0];

    }
    
    return self;
}

-(void)setIntensity:(float)value {
//    static float to_angle = 0;
//    to_angle += 0.005;
    float input_range = max_input - min_input;
    float angle_range = max_angle - min_angle;
    float normalized = (value - min_input) / input_range;
    
    float angle = normalized * angle_range + min_angle;
//    float angle = to_angle;
//    printf("angle: %f\n", angle);
    
    // make new path
    bool positive = angle >= 0;
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGPathMoveToPoint(path, NULL, radius - width/4, 0);
//    CGPathAddArc(path, NULL, 0, 0, radius - (width / 4), 0, angle, !positive);
//    CGPathAddArc(path, NULL, 0, 0, radius + (width / 4), angle, 0, positive);
//    CGPathCloseSubpath(path);
//    // Assignment to SKShapeNode.path creates a copy of CGMutablePathRef
//    arcStroke.path = path;
//    // CoreFoundation objects are not automatically memory-managed by ARC, so free path now that it has been copied
//    CGPathRelease(path);

    // move tip
    float tip_x = (radius) * cos(angle);
    float tip_y = (radius) * sin(angle);
    arrowTip.position = CGPointMake(tip_x, tip_y);
    if (positive) {
        arrowTip.zRotation = angle - M_PI/2;
    }
    else {
        arrowTip.zRotation = angle + M_PI/2;
    }
}

-(void)setInputRange:(float)_min max:(float)_max {
    min_input = _min;
    max_input = _max;
}

-(void)setAngleRange:(float)_min max:(float)_max {
    min_angle = _min;
    max_angle = _max;
}

@end
