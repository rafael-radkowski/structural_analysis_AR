//
//  SKInfoBox.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/19/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKInfoBox.h"

@implementation SKInfoBox {
    CGSize boxSize;
    BOOL dragging;
    CGPoint lastDragPt;
}

-(id)initWithTitle:(NSString*)title withSize:(CGSize)size titleSize:(float)titleBoxHeight {
    dragging = NO;
    
    if (self = [super init]) {
        boxSize = size;
        
        self.path = CGPathCreateWithRect(CGRectMake(0, 0, boxSize.width, boxSize.height), NULL);
        
//        mainBox = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, boxSize.width, boxSize.height)];
        self.strokeColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.fillColor = [UIColor colorWithWhite:0.8 alpha:0.5];
    //    mainBox.position = CGPointMake(scnView.frame.size.width - boxSize.width - 50, scnView.frame.size.height - jointBoxHeight - 50);
        
        self.zPosition = -1; // Don't cover other nodes
        // Dark background behind title
//        float titleBoxHeight = 40;
        SKShapeNode* jointBoxTitleBg = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, boxSize.width, titleBoxHeight)];
        jointBoxTitleBg.fillColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        jointBoxTitleBg.strokeColor = [UIColor colorWithWhite:0.0 alpha:0.0]; // no stroke
        jointBoxTitleBg.position = CGPointMake(0, boxSize.height - titleBoxHeight);
        jointBoxTitleBg.zPosition = 1;
        [self addChild:jointBoxTitleBg];
        
        // make title for joint box
        SKLabelNode* jointBoxTitle = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
        jointBoxTitle.text = title;
        jointBoxTitle.fontColor = [UIColor blackColor];
        jointBoxTitle.fontSize = titleBoxHeight - 5;
        jointBoxTitle.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
        jointBoxTitle.position = CGPointMake(boxSize.width / 2, titleBoxHeight / 2);
        jointBoxTitle.zPosition = 1;
        [jointBoxTitleBg addChild:jointBoxTitle];
        
        // Grip indicator
        SKSpriteNode* gripper = [SKSpriteNode spriteNodeWithImageNamed:@"grip.png"];
        gripper.anchorPoint = CGPointMake(0, 0.5);
        float gripHeight = titleBoxHeight - 6;
        [gripper scaleToSize:CGSizeMake(gripHeight * 2. / 5, gripHeight)];
        gripper.position = CGPointMake(5, titleBoxHeight / 2);
        [jointBoxTitleBg addChild:gripper];
        gripper.zPosition = 2;
        
        // make underline for title
        CGPoint titlePoints[2] = {CGPointMake(0, 0), CGPointMake(boxSize.width, 0)};
        SKShapeNode* titleUnderline = [SKShapeNode shapeNodeWithPoints:titlePoints count:2];
        titleUnderline.strokeColor = [UIColor blackColor];
        titleUnderline.lineWidth = 2;
        titleUnderline.position = CGPointMake(0, boxSize.height - titleBoxHeight);
        [self addChild:titleUnderline];
    }
    return self;
}

-(BOOL)touchBegan:(CGPoint)point {
    if ([self containsPoint:point]) {
        dragging = YES;
        lastDragPt = point;
        return YES;
    }
    else {
        return NO;
    }
}

-(void)touchMoved:(CGPoint)point limitTo:(CGRect)bounds {
    if (dragging) {
        CGPoint moved = CGPointMake(point.x - lastDragPt.x, point.y - lastDragPt.y);
        CGPoint newPos = CGPointMake(self.position.x + moved.x, self.position.y + moved.y);
        int rightSide = bounds.origin.x + bounds.size.width;
        int topSide = bounds.origin.y + bounds.size.height;
        // keep box within scene
        newPos.x = MIN(MAX(0., newPos.x), rightSide - self.frame.size.width);
        newPos.y = MIN(MAX(bounds.origin.y, newPos.y), topSide - self.frame.size.height);
        // blah testing stuff
        self.position = newPos;
        lastDragPt = point;
    }
}

-(void)touchEnded {
    dragging = NO;
}


-(void)touchCancelled {
    dragging = NO;
}

@end
