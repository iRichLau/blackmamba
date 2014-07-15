//
//  blackmambaViewController.m
//  blackmamba
//
//  Created by Richard Lau on 7/10/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import "blackmambaViewController.h"
#import <Parse/Parse.h>

@interface blackmambaViewController ()

@end

@implementation blackmambaViewController

@synthesize imageView;
@synthesize handlePage;

int imageIndex = 2;

- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)sender {

    NSArray *images=[[NSArray alloc] initWithObjects:
                      @"awaitrescue.png",
                      @"turnon 2",
                      @"Hello", nil];
    
    UISwipeGestureRecognizerDirection direction =
    [(UISwipeGestureRecognizer *) sender direction];
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.5;
    animation.type = kCATransitionPush;
    
    switch (direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            imageIndex --;
            animation.subtype = kCATransitionFromRight;
            break;
        case UISwipeGestureRecognizerDirectionRight:
            imageIndex ++;
            animation.subtype = kCATransitionFromLeft;
            break;
        default:
            break;
    }
    imageIndex = (imageIndex < 0) ? ([images count] - 1):
    imageIndex % [images count];
    [imageView.layer addAnimation:animation forKey:@"imageTransition"];
    imageView.image = [UIImage imageNamed:[images objectAtIndex:imageIndex]];
    handlePage.currentPage = 2 - imageIndex;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        }

- (void)viewDidAppear:(BOOL)animated
{
    PFUser *user = [PFUser currentUser];
    
    if (user != nil) {
        [self performSegueWithIdentifier:@"theButton" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
