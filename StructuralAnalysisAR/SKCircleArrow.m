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
    
    // A semicircle for the arrow arc
    SKSpriteNode *semicircle;
    // A crop mask, determining which part of the semicircle to show
    SKCropNode* circleMask;
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
//        arcStroke = [SKShapeNode shapeNodeWithPath:CGPathCreateMutable()];
//        arcStroke.fillColor = [UIColor greenColor];
//        arcStroke.lineWidth = 0;
//        [self addChild:arcStroke];
        
        arrowTip = [SKSpriteNode spriteNodeWithImageNamed:@"arrow.png"];
        arrowTip.anchorPoint = CGPointMake(1, 0.5);
        float arrowSize = arrowTip.frame.size.width;
        float arrowScale = width / arrowSize;
        arrowTip.xScale = arrowTip.yScale = arrowScale;
//        arrowTip.position = CGPointMake(width/2. + arrowGap, 0);
        [self addChild:arrowTip];
        
        // draw the semicircle
//        semicircle = [[SKShapeNode alloc] init];
//        semicircle.fillColor = [UIColor greenColor];
//        semicircle.lineWidth = 0;
//        CGMutablePathRef path = CGPathCreateMutable();
//        CGPathMoveToPoint(path, NULL, radius - width/4, 0);
//        CGPathAddArc(path, NULL, 0, 0, radius - (width / 4), 0, M_PI, NO);
//        CGPathAddArc(path, NULL, 0, 0, radius + (width / 4), M_PI, 0, YES);
//        CGPathCloseSubpath(path);
//     Assignment to SKShapeNode.path creates a copy of CGMutablePathRef
//        semicircle.path = path;
//     CoreFoundation objects are not automatically memory-managed by ARC, so free path now that it has been copied
//        CGPathRelease(path);
        
        semicircle = [SKSpriteNode spriteNodeWithImageNamed:@"semicircle.png"];
        // texture designed for 128x128 resoultion when radius = 100/3
        float texScale = (128. / semicircle.frame.size.width) * ((100. / 3) / radius);
        semicircle.xScale = semicircle.yScale = texScale;

        // set up the semicircle mask
        circleMask = [[SKCropNode alloc] init];
        // A rectangle mask can be spun around to show the arc at different angles
        SKShapeNode* rectMask = [SKShapeNode shapeNodeWithRect:CGRectMake(-(radius + width/2), 0, 2*(radius + width/2), 2*(radius + width/2))];
        
        if (@available(iOS 11.0, *)) {
            rectMask.fillColor = [UIColor whiteColor];
        } else {
            // iOS 10 SKShapeNode is so broken... Unless I set alpha to a very small value, the mask will render
            rectMask.fillColor = [UIColor colorWithWhite:1.0 alpha:0.00001];
        }
        rectMask.lineWidth = 0;
        circleMask.maskNode = rectMask;
        [circleMask addChild:semicircle];
        [self addChild:circleMask];

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
    if (fabsf(angle) > M_PI) {
        // If more than a semicircle is needed, you could make a second semicircle rotated 180 degrees
        printf("Warning: Angle > PI in SKCircleArrow. Will not be drawn correctly\n");
    }

    // move the mask to show the right amount of arc
    bool positive = angle >= 0;
    circleMask.zRotation = positive ? 0 : M_PI;
    circleMask.maskNode.zRotation = angle - M_PI;
    
    // The reason not to redraw an arc like below (commented out), is because iOS 10 has a bug in SKSpriteNode
    //     where updating the path causes a memory error. Fine in iOS 11. Turning on "Malloc Scribble" in the debug settings
    //     makes the crash more repeatable
    
    // make new path
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGPathMoveToPoint(path, NULL, radius - width/4, 0);
//    CGPathAddArc(path, NULL, 0, 0, radius - (width / 4), 0, angle, !positive);
//    CGPathAddArc(path, NULL, 0, 0, radius + (width / 4), angle, 0, positive);
//    CGPathCloseSubpath(path);
    // Assignment to SKShapeNode.path creates a copy of CGMutablePathRef
//    arcStroke.path = path;
    // CoreFoundation objects are not automatically memory-managed by ARC, so free path now that it has been copied
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
