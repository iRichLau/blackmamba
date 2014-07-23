//
//  buttonViewController.m
//  blackmamba
//
//  Created by Richard Lau on 7/14/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import "buttonViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "sendgrid.h"
#import "AFNetworking.h"

@interface buttonViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSString *address;
@end

@implementation buttonViewController {
    @private BOOL isSelected;
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [self personEmail:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}


- (IBAction)addContactsButton:(id)sender {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)personEmail:(ABRecordRef)person
{
    NSString* email;
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    
    if (ABMultiValueGetCount(emails) > 0){
        
        email = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(emails, 0);
        
        [self addContact:email];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Contact does not have an email. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    CFRelease(emails);
}

- (void)addContact:(NSString *)email{
    PFQuery *contactsQuery = [PFQuery queryWithClassName:@"Contact"];
    
    [contactsQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [contactsQuery whereKey:@"email" equalTo:email];
    
    [contactsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Server Busy. Please Try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        if ([objects count] > 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot add. This contact has already been added." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
        } else {
            
            PFObject *newContact = [PFObject objectWithClassName:@"Contact"];
            
            [newContact setObject:email forKey:@"email"];
            
            [newContact setObject:[PFUser currentUser] forKey:@"user"];
            
            [newContact saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not add Contact. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }];
    }
    }];
}

- (IBAction)logOutButton:(id)sender {
    [PFUser logOut];
    [self performSegueWithIdentifier:@"main" sender:self];
    
}

- (void)onState:sender {
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"on-background.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    UIImage * buttonImage = [UIImage imageNamed:@"button-on"];
    
    [sender setImage:buttonImage forState:UIControlStateNormal];
    
    _paragraph.textColor = [UIColor whiteColor];
}

- (void)offState:sender {
    self.view.backgroundColor = [UIColor blackColor];
    _paragraph.textColor = [UIColor grayColor];
    
    UIImage * offButtonImage = [UIImage imageNamed:@"power-button"];
    [sender setImage:offButtonImage forState:UIControlStateNormal];
    
}

-(void)alertContacts {
    PFQuery *contactsQuery = [PFQuery queryWithClassName:@"Contact"];
    
    [contactsQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    
    [contactsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self sendEmail:objects];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No contacts were found. Please add contacts." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}
- (void)sendEmail:(NSArray *)emails {
    
    NSString *emailSubject = [NSString stringWithFormat:@"Please be advised. The last known location of %@ was at latitude: %@ and longitude: %@. Based on this information the approximate address of this location is: %@. Please provide this information to the appropriate authorities.", [[PFUser currentUser] objectForKey:@"username"], _latitude, _longitude, _address];
    
    SendGrid *sendgrid = [SendGrid apiUser:@"" apiKey:@""];
    
    NSMutableArray *emailContacts = [[NSMutableArray alloc] init];
        for (PFObject *email in emails) {
        [emailContacts addObject:[email valueForKey:@"email"]];
    }

    
    SendGridEmail *sgEmail = [[SendGridEmail alloc] init];
    
    [sgEmail setTos:emailContacts];
    sgEmail.subject = @"Black Mamba Rescue Beacon Location ALERT";
    sgEmail.from = @"richardlau.rlau@gmail.com";
    sgEmail.text = emailSubject;
   
    [sendgrid sendWithWeb:sgEmail];

}

- (IBAction)alertButton:(id)sender {
    isSelected = !isSelected;
    if (isSelected == true) {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        [locationManager startUpdatingLocation];
        [self onState:sender];
        
    } else {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        [locationManager startUpdatingLocation];
        [self offState:sender];
    }
}

- (void)saveLocation{
    PFObject *newLocation = [PFObject objectWithClassName:@"location"];
    
    [newLocation setObject:_latitude forKey:@"latitude"];
    [newLocation setObject:_longitude forKey:@"longitude"];
    [newLocation setObject:[PFUser currentUser] forKey:@"user"];
    
    [newLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not save your location. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    
}


#pragma mark CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not find your location. Check your settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currentLocation = [locations lastObject];
    if (currentLocation != nil) {
        self.latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        self.longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        [self saveLocation];
    }

    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            self.address = [NSString stringWithFormat:@"%@ %@ %@, %@, %@, %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.postalCode, placemark.locality, placemark.administrativeArea, placemark.country];
            [self alertContacts];
            [locationManager stopUpdatingLocation];
            locationManager.delegate = nil;
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    }];
    
    
}

@end
