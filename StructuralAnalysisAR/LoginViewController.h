//
//  LoginViewController.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *idTextField;
- (IBAction)loginButtonUp:(id)sender;
- (IBAction)idTextChanged:(id)sender;

@end
