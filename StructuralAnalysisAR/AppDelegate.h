//
//  AppDelegate.h
//  sceneKitTest
//
//  Created by David Wehr on 8/18/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
};

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSDate* session_start;

-(void)checkSessionOnEnter;


@end

