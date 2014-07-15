//
//  buttonViewController.h
//  blackmamba
//
//  Created by Richard Lau on 7/14/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>


@interface buttonViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate>
- (IBAction)addContactsButton:(id)sender;
- (IBAction)logOutButton:(id)sender;
- (IBAction)alertButton:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *paragraph;
@property (weak, nonatomic) IBOutlet UIImageView *outerCircle;
@end
