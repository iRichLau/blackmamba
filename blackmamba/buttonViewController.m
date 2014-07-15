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
@property (weak, nonatomic) NSString *latitude;
@property (weak, nonatomic) NSString *longitude;
@end

@implementation buttonViewController {
    @private BOOL isSelected;
    CLLocationManager *locationManager;
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
    
    
    [self findMostRecentLocation];
    
    NSString *emailSubject = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@", @"The last known location of ", [[PFUser currentUser] objectForKey:@"username"], @"is at - latitude: ", _latitude, @" and longitude: ", _longitude];
    
    sendgrid *msg = [sendgrid user:@"" andPass:@""];
    
    NSMutableArray *emailArray = [[NSMutableArray alloc] init];
    for (PFObject *email in emails) {
        [emailArray addObject:[email valueForKey:@"email"]];
    }
    msg.tolist = emailArray;
    msg.subject = @"New Black Mamba Location";
    msg.from = @"richardlau.rlau@gmail.com";
    msg.text = emailSubject;
    NSLog(@"%@", msg.to);
    NSLog(@"%@", msg.from);
    NSLog(@"%@", msg.text);
    NSLog(@"%@", msg.subject);
    
    
    [msg sendWithWeb];
}

-(void)findMostRecentLocation{
    PFQuery *locationsQuery = [PFQuery queryWithClassName:@"location"];
    [locationsQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [locationsQuery orderByDescending:@"createdAt"];
    
    [locationsQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    NSLog(@"%@", object);
        if (object) {
            self.latitude = [object objectForKey:@"latitude"];
            self.longitude =[object objectForKey:@"longitude"];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No locations were found." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
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

- (void)addLocation:(NSString *)latitude longitude: (NSString *)longitude {
    PFObject *newLocation = [PFObject objectWithClassName:@"location"];
    
    [newLocation setObject:latitude forKey:@"latitude"];
    [newLocation setObject:longitude forKey:@"longitude"];
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
        NSString *latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        [self addLocation:latitude longitude:longitude];
        [locationManager stopUpdatingLocation];
        [self alertContacts];
        locationManager.delegate = nil;
    }
}

@end
