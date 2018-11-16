/*
 Copyright (c) 2013 OpenSourceRF.com.  All right reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
This is the matching iPhone for the bulk data transfer sketch.  This
application has been included for completeness, and to demonstrate
how you could verify that no data was dropped.  Its really for
educational use only - it's output is to the debug window, and it
doesn't have a UI.

If you would like to test bulk data transfer with one of the existing
apps, you can use the ColorWheel application.  Open the sketch in 
Arduino, compile and open the Serial Monitor.  Open the ColorWheel
application and connect to the sketch.  Once connected, the sketch
will start transferring the data (The ColorWheel application receives
the data, but ignores it).  After the transfer is complete, the
Serial Monitor will display the start time, end time, elapsed time,
and kbps.
*/

#import <QuartzCore/QuartzCore.h>

#import "AppViewController.h"
#import <OpenGLES/ES2/glext.h>
typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    // Front
    {{1, -1, 1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Back
    {{1, 1, -1}, {1, 0, 0, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}, {1, 0}},
    {{1, -1, -1}, {0, 0, 1, 1}, {0, 0}},
    {{-1, 1, -1}, {0, 0, 0, 1}, {1, 1}},
    // Left
    {{-1, -1, 1}, {1, 0, 0, 1}, {1, 0}},
    {{-1, 1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}},
    // Right
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
    {{1, 1, 1}, {0, 0, 1, 1}, {0, 1}},
    {{1, -1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Top
    {{1, 1, 1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, 1, 1}, {0, 0, 0, 1}, {0, 0}},
    // Bottom
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
    {{1, -1, 1}, {0, 1, 0, 1}, {1, 1}},
    {{-1, -1, 1}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

@interface AppViewController () {
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
    float _mx, _my, _mz;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation AppViewController
{
    int packets;
    char ch;
    int packet;
    double start;
}
@synthesize context = _context;
@synthesize effect = _effect;
// Rest of file...

@synthesize rfduino;

+ (void)load
{
    // customUUID = @"c97433f0-be8f-4dc8-b6f0-5343e6100eb4";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIButton *backButton = [UIButton buttonWithType:101];  // left-pointing shape
        [backButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(disconnect:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [[self navigationItem] setLeftBarButtonItem:backItem];
        
        [[self navigationItem] setTitle:@"Skate Trick Detector"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _dataStream = [NSMutableArray new];
    _dataString = [NSMutableString string];
 
    [rfduino setDelegate:self];
    
    UIColor *start = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.15];
    UIColor *stop = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.45];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = [self.view bounds];
    gradient.colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)stop.CGColor, nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    packets = 500;
    ch = 'A';
    packet = 0;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    [self setupGL];
    
    _recordingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_recordingButton setTitle:@"Start" forState:UIControlStateNormal];
    _recordingButton.frame = CGRectMake(200, 200, 150, 50);
    [_recordingButton addTarget:self action:@selector(recordingButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [view addSubview:_recordingButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)disconnect:(id)sender
{
    NSLog(@"disconnect pressed");

    [rfduino disconnect];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (void)recordingButtonPressed:(id)sender {
    _isRecording = !_isRecording;
    [_recordingButton setTitle:_isRecording ? @"Stop" : @"Start" forState:UIControlStateNormal];
    
    if (!_isRecording) {
        NSLog(@"WRITE FILE!!!!!!!!!!!!!!!!!!!!!!!!!");
        
        NSString *path = [[self applicationDocumentsDirectory].path
                          stringByAppendingPathComponent:@"skatetrickdetector.csv"];
        [_dataString writeToFile:path atomically:YES
                       encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)didReceive:(NSData *)data
{
    int length = [data length];
    
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
        
    } else if (specialId == 5) {
        _mx = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _my = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        _mz = (float) *(float *)(bytePtr + offset);
        offset += sizeof(float);
        
        NSString *message = [NSString stringWithFormat:@"%lld,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),  _q0, _q1, _q2, _q3, _ax, _ay, _az, _gx, _gy, _gz, _mx, _my, _mz];
                //NSLog(@"Message: %@", message);
        
//        NSLog(@"UPDATE QUATERNION");
        _slerping = YES;
        _slerpCur = 0;
        _slerpMax = 0.25;
        _slerpStart = _quat;
        _slerpEnd = GLKQuaternionMake(_q0, _q1, _q2, _q3);
        
        if (_isRecording) {
            [_dataString appendString:message];
        }
    }
    
    return;
    
    
    
    
    
    
    if (length == 1) {
        char c;
        [data getBytes:&c length:1];
        NSLog(@"RecievedRX %c", c);
        _currQuaternionIndex = 0;
        
    } else {
        float z;
        [data getBytes:&z length:sizeof(float)];
        NSLog(@"RecievedRX %f", z);
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
        NSLog(@"UPDATE QUATERNION");
        _slerping = YES;
        _slerpCur = 0;
        _slerpMax = 0.25;
        _slerpStart = _quat;
        _slerpEnd = GLKQuaternionMake(_q0, _q1, _q2, _q3);
        
//        [_dataStream addObject:@[[NSNumber numberWithFloat:_q0], _q1, _q2, _q3]];
        [_dataString appendString:[NSString stringWithFormat:@"%lld, %f, %f, %f, %f\n", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),  _q0, _q1, _q2, _q3]];
       
    }

    return;
    
    NSLog([data base64EncodedStringWithOptions:NSUTF8StringEncoding]);
    return;
    /*
    uint8_t *p = (uint8_t*)[data bytes];
    NSUInteger len = [data length];
    
    // NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    // NSLog(@"%d=%@", len, s);
    NSMutableString *s = [[NSMutableString alloc] init];
    
    [s appendFormat:@"%d - ", len];
    
    for (int i = 0; i < len; i++)
      if (isprint(p[i]))
          [s appendFormat:@"%c", p[i]];
      else
          [s appendFormat:@"{%02x}", p[i]];
    
    NSLog(@"%@", s);
    */
    
    if (packet == 0)
    {
        NSLog(@"start");
        start = CACurrentMediaTime();
    }
    
    uint8_t *p = (uint8_t*)[data bytes];
    NSUInteger len = [data length];
    
    if (len != 20)
        NSLog(@"len issue");
    for (int i = 0; i < 20; i++)
    {
        if (p[i] != ch)
            NSLog(@"ch issue");
        ch++;
        if (ch > 'Z')
            ch = 'A';
    }
    packet++;
    if (packet >= packets)
    {
        NSLog(@"end");
        double end = CACurrentMediaTime();
        float secs = (end - start);
        int bps = ((packets * 20) * 8) / secs;
        NSLog(@"start: %f", start);
        NSLog(@"end: %f", end);
        NSLog(@"elapsed: %f", secs);
        NSLog(@"kbps: %f", bps / 1000.0);
    }
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

- (void)setupGL {
    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_CULL_FACE);
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft,
                              nil];
    
    NSError * error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_floor" ofType:@"png"];
    GLKTextureInfo * info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (info == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    self.effect.texture2d0.name = info.name;
    self.effect.texture2d0.enabled = true;
    
    // New lines
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Old stuff
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    // New lines (were previously in draw)
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    
    // New line
    glBindVertexArrayOES(0);
    
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
    
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(_curRed, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
    if (_increasing) {
        _curRed += 1.0 * self.timeSinceLastUpdate;
    } else {
        _curRed -= 1.0 * self.timeSinceLastUpdate;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    if (_slerping) {
        
        _slerpCur += self.timeSinceLastUpdate;
        float slerpAmt = _slerpCur / _slerpMax;
        if (slerpAmt > 1.0) {
            slerpAmt = 1.0;
            _slerping = NO;
        }
        
        _quat = GLKQuaternionSlerp(_slerpStart, _slerpEnd, slerpAmt);
    }
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    //modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
}

- (GLKVector3) projectOntoSurface:(GLKVector3) touchPoint
{
    float radius = self.view.bounds.size.width/3;
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    GLKVector3 P = GLKVector3Subtract(touchPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else
    {
        /*
         P.x *= radius / sqrt(length2);
         P.y *= radius / sqrt(length2);
         P.z = 0;
         */
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    // TODO: Do something with Q_rot...
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectOntoSurface:_current_position];
    
    [self computeIncremental];
    
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    _slerping = YES;
    _slerpCur = 0;
    _slerpMax = 1.0;
    _slerpStart = _quat;
    _slerpEnd = GLKQuaternionMake(0, 0, 0, 1);
    
}


@end
