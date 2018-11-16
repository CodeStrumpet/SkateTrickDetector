//
//  MainViewController.m
//  DinoLasers
//
//  Created by Paul Mans on 11/19/12.
//  Copyright (c) 2012 DinoLasers. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/glext.h>
#import "MainViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "UDPConnection.h"
#import "LogConnection.h"
#import "MotionController.h"
#import "DinoLaserSettings.h"

#define LOG_BUFFER_SIZE 300


@interface MainViewController ()

@property (nonatomic, strong) MotionController *motionController;
@property (nonatomic, strong) UDPConnection *udpConnection;
@property (nonatomic, strong) LogConnection *logConnection;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) NSString *logString;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) long tag;

@end

@interface MainViewController () {
    float _curRed;
    BOOL _increasing;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    float _rotation;
    GLKMatrix4 _rotMatrix;
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
    
    BOOL _slerping;
    float _slerpCur;
    float _slerpMax;
    GLKQuaternion _slerpStart;
    GLKQuaternion _slerpEnd;
    
    int _currQuaternionIndex;
    float _q0;
    float _q1;
    float _q2;
    float _q3;
    long _time;
    float _ax, _ay, _az;
    float _gx, _gy, _gz;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation MainViewController
@synthesize markerStringTextField;
@synthesize udpConnection;
@synthesize logConnection;
@synthesize isRecording;
@synthesize logString;
@synthesize timer;
@synthesize tag;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isRecording = NO;
    self.tag = 001;
    
    // instantiate MotionController and enable motion tracking
    self.motionController = [[MotionController alloc] init];
    [self.motionController enableMotionTracking];
    
    // Open whatever persistence connections are enabled in settings
    [self updatePersistenceConnections];
    
    // begin timer
    double timeInterval = DEFAULT_UPDATE_INTERVAL;
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
    
    // Make view adjustments
    [self updateToggleRecordingButton];
    
    self.logString = @"";
    self.logTextView.text = nil;
    self.logTextView.layer.cornerRadius = 4;
    self.logTextView.backgroundColor = [UIColor grayColor];
    
    [_rfduino setDelegate:self];
    
}


- (void)updatePersistenceConnections {
    PersistenceMode currPersistenceMode = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_MODES_SETTINGS_KEY];
        
    // setup UDPConnection if enabled
    if (currPersistenceMode & PersistenceModeUDP) {
        if (!self.udpConnection) {
            self.udpConnection = [[UDPConnection alloc] init];
        }
        
        NSString *hostIP = [[NSUserDefaults standardUserDefaults] objectForKey:HOST_IP_KEY];
        if (hostIP) {
            self.udpConnection.socketHost = hostIP;
        }
        
        [self.udpConnection setupSocket];
    } else {
        // kill existing udpConnection if it exists
        [self.udpConnection close];
        self.udpConnection = nil;
    }
    
    // setup LogConnection if enabled
    if (currPersistenceMode & PersistenceModeLogFile) {
        if (!self.logConnection) {
            self.logConnection = [[LogConnection alloc] init];
        }
    } else {
        // kill existing log connection if it exists
        self.logConnection = nil;
    }
}


#pragma mark - IBActions

- (IBAction)toggleRecording:(id)sender {
    isRecording = !isRecording;
    
    [self updateToggleRecordingButton];
    
    NSLog(@"Updating recording state: %@", isRecording ? @"YES" : @"NO");
}

- (IBAction)showInfo:(id)sender {
    
    DinoLaserSettings *settings = [DinoLaserSettings new];
    settings.persistenceModes = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_MODES_SETTINGS_KEY];
    
    NSString *ip = [[NSUserDefaults standardUserDefaults] objectForKey:HOST_IP_KEY];
    if (!ip) {
        ip = DEFAULT_HOST;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:HOST_IP_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    settings.hostIP = ip;
    
    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithDinoLaserSettings:settings];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)markString:(id)sender {
    if ([self.markerStringTextField.text isEqualToString:@""]) {
        self.motionController.markerString = nil;
    } else {
        self.motionController.markerString = self.markerStringTextField.text;
    }
    NSLog(@"Updated Marker String to: %@", self.motionController.markerString);
    [self.markerStringTextField resignFirstResponder];
    
    // start a new logconnection file
    self.logConnection.fileNamePrefix = self.motionController.markerString;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Start new log file?" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil, nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.logConnection beginNewFile];
    }
}


#pragma mark - Timer & Data Processing

// Timer callback
-(void)timerFired:(NSTimer *)theTimer {
    if (isRecording) {
        [self processMotionData];
    }
}

- (void)processMotionData {
    NSString *motionString = [self.motionController currentMotionString];
    
    NSLog(@"motionString: %@", motionString);
    [self appendToLog:motionString];
    
    // pass update to udpConnection if it exists
    //[self.udpConnection sendMessage:motionString withTag:tag];
    
    // pass update to logConnection if it exists
    [self.logConnection printLineToLog:motionString];
    
    // increment the tag
    self.tag++;
}


#pragma mark - FlipsideViewDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)flipsideViewController:(FlipsideViewController *)controller didUpdateSettings:(DinoLaserSettings *)settings {
    
    // Save new settings info in defaults
    [[NSUserDefaults standardUserDefaults] setInteger:settings.persistenceModes forKey:PERSISTENCE_MODES_SETTINGS_KEY];
    if (settings.hostIP) {
        [[NSUserDefaults standardUserDefaults] setObject:settings.hostIP forKey:HOST_IP_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // update the persistent connections with the changes
    [self updatePersistenceConnections];
}

#pragma mark - Scrolling OnScreen Log 

- (void)appendToLog:(NSString *)suffix {
    logString = [logString stringByAppendingString:suffix];
    if (logString.length >= LOG_BUFFER_SIZE) {
        logString = [logString substringFromIndex:logString.length - LOG_BUFFER_SIZE];
    }
    
    self.logTextView.text = logString;
    
    NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
    [self.logTextView scrollRangeToVisible:range];
}


#pragma mark - Misc View setup

- (void)updateToggleRecordingButton {
    NSString *text = isRecording ? @"Pause" : @"Play";
    [self.toggleLoggingButton setTitle:text forState:UIControlStateNormal];
}


#pragma mark RFDuino setup
- (void)didReceive:(NSData *)data
{
    int length = [data length];
    NSLog(@"Received Data %d: %@", length, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
//    int offset = 0;
//
//    unsigned int marker;
//    [data getBytes:&marker range:NSMakeRange(0, sizeof(unsigned int))];
//
//    NSLog(@"Marker %d", marker);
    
    
    char *bytePtr = (char *)[data bytes];
    unsigned int specialId = (unsigned int)*bytePtr;
    int offset = 1;
    
    if (specialId == 1) {
        
//        _time = (long) *(long *)(bytePtr + offset);
//        offset += sizeof(long);
        
        _q0 = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _q1 = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);

    } else if (specialId == 2) {
        
        _q2 = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _q3 = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
    } else if (specialId == 3) {
        
        _ax = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _ay = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _az = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
    } else if (specialId == 4) {
        _gx = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _gy = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _gz = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        
        NSString *message = [NSString stringWithFormat:@"%lld,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%@\n", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),  _q0, _q1, _q2, _q3, _ax, _ay, _az, _gx, _gy, _gz, self.motionController.markerString];
        
        NSLog(@"Message: %@", message);
    }
        
//
//        NSString *message = [NSString stringWithFormat:@"%lld,%f,%f,%f,%f,%@\n", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),  _q0, _q1, _q2, _q3, self.motionController.markerString];
//
//        NSLog(@"Message: %@", message);
//    }
    
    return;
    
    if (length == 1) {
        char c;
        [data getBytes:&c length:1];
//        NSLog(@"Recieved Marker %c", c);
        _currQuaternionIndex = 0;
        
    } else {
        float z;
        [data getBytes:&z length:sizeof(float)];
//        NSLog(@"RecievedRX %f", z);
        if (_currQuaternionIndex == 0) {
            _q0 = z;
            _currQuaternionIndex++;
        } else if (_currQuaternionIndex == 1) {
            _q1 = z;
            _currQuaternionIndex++;
        } else if (_currQuaternionIndex == 2) {
            _q2 = z;
            _currQuaternionIndex++;
        } else if (_currQuaternionIndex == 3) {
            _q3 = z;
            _currQuaternionIndex++;
        }
//        NSLog(@"UPDATE QUATERNION");
        _slerping = YES;
        _slerpCur = 0;
        _slerpMax = 0.25;
        _slerpStart = _quat;
        _slerpEnd = GLKQuaternionMake(_q0, _q1, _q2, _q3);
        
        NSString *message = [NSString stringWithFormat:@"%lld,%f,%f,%f,%f,%@\n", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),  _q0, _q1, _q2, _q3, self.motionController.markerString];
        
        if (isRecording) {
            
            [self appendToLog:message];
            // pass update to logConnection if it exists
            [self.logConnection printLineToLog:message];
            
            // increment the tag
            self.tag++;
            
            [self.udpConnection sendMessage:message withTag:tag];
        }
    }
}

@end
