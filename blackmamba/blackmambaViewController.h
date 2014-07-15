//
//  blackmambaViewController.h
//  blackmamba
//
//  Created by Richard Lau on 7/10/14.
//  Copyright (c) 2014 Richard Lau. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface blackmambaViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)sender;
@property (strong, nonatomic) IBOutlet UIPageControl *handlePage;
@end
