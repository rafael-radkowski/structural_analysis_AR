//
//  LoginViewController.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/6/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import "LoginViewController.h"
#import <Analytics/SEGAnalytics.h>
#import "AppDelegate.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.loginButton setEnabled:NO];
    self.idTextField.delegate = self;
    
    // login button style
    self.loginButton.layer.borderWidth = 1.5;
    self.loginButton.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.loginButton.layer.borderColor = [UIColor colorWithRed:0.08235 green:0.49412 blue:0.9843 alpha:1.0].CGColor;
    self.loginButton.layer.cornerRadius = 5;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // clear last participant ID
    self.idTextField.text = @"";
    [self.loginButton setEnabled:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
#ifdef LOGIN_VIEW_SKIP
    [self performSegueWithIdentifier:@"mainPageSegue" sender:self];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)submitParticipantId {
    [[SEGAnalytics sharedAnalytics] identify:self.idTextField.text];
    
    // set the session start time
    AppDelegate* app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    app.session_start = [NSDate date];
    NSLog(@"Resetting session");
    
    [self performSegueWithIdentifier:@"mainPageSegue" sender:self];
}

- (IBAction)loginButtonUp:(id)sender {
    [self submitParticipantId];
}


- (IBAction)idTextChanged:(id)sender {
    if (self.idTextField.text.length > 0) {
        [self.loginButton setEnabled:YES];
    }
    else {
        [self.loginButton setEnabled:NO];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self submitParticipantId];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // allow backspace
    if (!string.length)
    {
        return YES;
    }
    
    // Prevent invalid character input, if keyboard is numberpad
    if (textField.keyboardType == UIKeyboardTypeNumberPad)
    {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound)
        {
            // BasicAlert(@"", @"This field accepts only numeric entries.");
            return NO;
        }
    }
    
//    // verify max length has not been exceeded
//    NSString *proposedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
//
//    if (proposedText.length > 4) // 4 was chosen for SSN verification
//    {
//        // suppress the max length message only when the user is typing
//        // easy: pasted data has a length greater than 1; who copy/pastes one character?
//        if (string.length > 1)
//        {
//            // BasicAlert(@"", @"This field accepts a maximum of 4 characters.");
//        }
//
//        return NO;
//    }
//
//    // only enable the OK/submit button if they have entered all numbers for the last four of their SSN (prevents early submissions/trips to authentication server)
//    self.answerButton.enabled = (proposedText.length == 4);
    
    return YES;
}
@end
