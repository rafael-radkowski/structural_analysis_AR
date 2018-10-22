//
//  SKInfoBox.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/19/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#ifndef SKInfoBox_h
#define SKInfoBox_h

#import <SpriteKit/SpriteKit.h>

@interface SKInfoBox : SKShapeNode

-(id)initWithTitle:(NSString*)title withSize:(CGSize)size titleSize:(float)titleSize;

// Returns
-(BOOL)touchBegan:(CGPoint)point;

-(void)touchMoved:(CGPoint)point limitTo:(CGRect)bounds;

-(void)touchEnded;

-(void)touchCancelled;

@end

#endif /* SKInfoBox_h */
