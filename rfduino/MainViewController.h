//
//  MainViewController.h
//  DinoLasers
//
//  Created by Paul Mans on 11/19/12.
//  Copyright (c) 2012 DinoLasers. All rights reserved.
//

#import "FlipsideViewController.h"
#import "RFduino.h"
#import <GLKit/GLKit.h>

@interface MainViewController : GLKViewController <FlipsideViewControllerDelegate, UIAlertViewDelegate, RFduinoDelegate> {

}

@property (strong, nonatomic) IBOutlet UIButton *toggleLoggingButton;
@property (nonatomic, strong) IBOutlet UITextField *markerStringTextField;
@property (strong, nonatomic) IBOutlet UITextView *logTextView;

@property(strong, nonatomic) RFduino *rfduino;

@end
