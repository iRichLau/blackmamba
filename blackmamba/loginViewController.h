//
//  loginViewController.h
//  blackmamba
//
//  Created by Richard Lau on 7/14/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface loginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)backButton:(id)sender;
- (IBAction)loginButton:(id)sender;
@end
