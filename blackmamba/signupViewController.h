//
//  signupViewController.h
//  blackmamba
//
//  Created by Richard Lau on 7/13/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface signupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
- (IBAction)registerAction:(id)sender;
- (IBAction)backButton:(id)sender;
@end
