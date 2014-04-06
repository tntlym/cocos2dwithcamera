//
//  TestCamera.m
//  TestAv
//
//  Created by bluemol on 3/27/14.
//  Copyright 2014 rockyee. All rights reserved.
//

#import "TestCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"

#import "AVCamPreviewView.h"

@implementation TestCamera

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;
id runtimeErrorHandlingObserver;

AVCaptureSession *session;
AVCamPreviewView *previewView;
UIBackgroundTaskIdentifier backgroundRecordingID;
AVCaptureDeviceInput *videoDeviceInput;

dispatch_queue_t sessionQueue;

CCLayerColor *colorLayer;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	TestCamera *layer = [TestCamera node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
        self.touchEnabled = YES;
        
        ccColor4B color =  {255, 90, 0, 255};
        colorLayer = [CCLayerColor layerWithColor:color];
        [self addChild:colorLayer z:0];
        
//        CCMenuItemSprite *camMenuSprite = [CCMenuItemImage itemWithNormalImage:@"Icon-72.png"
//                                                           selectedImage:@"Icon-72.png" block:^(id sender){
//                                                               NSLog(@"ready for camera");
//                                                               
//                                                               
//        }];
//        [camMenuSprite.selectedImage setColor:ccGRAY];
//        
//        CCMenu *camMenu = [CCMenu menuWithItems:camMenuSprite, nil];
//        camMenu.position = ccp([[CCDirector sharedDirector] winSize].width/2, [[CCDirector sharedDirector] winSize].height/2);
//        [self addChild:camMenu z:1];
        
        [self setupCamera];
    }
    
    return self;
}



-(void)setupCamera
{
	session = [[AVCaptureSession alloc] init];
//    previewView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0,
//                                                                     0,
//                                                                     [[UIScreen mainScreen] applicationFrame].size.width,
//                                                                     [[UIScreen mainScreen] applicationFrame].size.height)];
    previewView = [[AVCamPreviewView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    previewView.session = session;
    
//    CCUIViewWrapper *wrapperCamera = [CCUIViewWrapper wrapperForUIView:previewView];
//    wrapperCamera.contentSize = previewView.frame.size;
//    //[wrapperCamera updateUIViewTransform];
//    [self addChild:wrapperCamera z:0];

    //[[[CCDirector sharedDirector] view] addSubview:previewView];
    AppController *appDelegate = (AppController *)[[UIApplication sharedApplication] delegate];
    [appDelegate.overlay addSubview:previewView];
    
    [self checkDeviceAuthorizationStatus];
    
    sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(sessionQueue, ^{
		backgroundRecordingID = UIBackgroundTaskInvalid;
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error) {
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput]) {
			[session addInput:videoDeviceInput];
            
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
				[[(AVCaptureVideoPreviewLayer *)[previewView layer] connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
                
                NSLog(@"start running");
                [session startRunning];
                
                CCMenuItemSprite *camMenuSprite = [CCMenuItemImage itemWithNormalImage:@"Icon-72.png"
                                                                         selectedImage:@"Icon-72.png" block:^(id sender){
                                                                             NSLog(@"ready for camera");
                                                                             
                                                                             [colorLayer removeFromParent];
                                                                         }];
                [camMenuSprite.selectedImage setColor:ccGRAY];
                
                CCMenu *camMenu = [CCMenu menuWithItems:camMenuSprite, nil];
                camMenu.position = ccp([[CCDirector sharedDirector] winSize].width/2, [[CCDirector sharedDirector] winSize].height/2);
                [self addChild:camMenu z:10];
			});
		}
		
	});


}


-(void) onEnter
{
    [super onEnter];
    
//    dispatch_async(sessionQueue, ^{
//		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
//		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
//		[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[videoDeviceInput device]];
		
//		[runtimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:session queue:nil usingBlock:^(NSNotification *note) {
//			dispatch_async(sessionQueue, ^{
//				// Manually restarting the session since it must have been stopped due to an error.
//				[session startRunning];
//			});
//		}]];

//	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			//[self runStillImageCaptureAnimation];
		}
	}
	else if (context == RecordingContext)
	{
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
//			if (isRecording)
//			{
//				[[self cameraButton] setEnabled:NO];
//				[[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
//				[[self recordButton] setEnabled:YES];
//			}
//			else
//			{
//				[[self cameraButton] setEnabled:YES];
//				[[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
//				[[self recordButton] setEnabled:YES];
//			}
		});
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
//			if (isRunning)
//			{
//				[[self cameraButton] setEnabled:YES];
//				[[self recordButton] setEnabled:YES];
//				[[self stillButton] setEnabled:YES];
//			}
//			else
//			{
//				[[self cameraButton] setEnabled:NO];
//				[[self recordButton] setEnabled:NO];
//				[[self stillButton] setEnabled:NO];
//			}
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async(sessionQueue, ^{
		AVCaptureDevice *device = [videoDeviceInput device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}


- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			//Granted access to mediaType
			//[self setDeviceAuthorized:YES];
		}
		else
		{
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCam!"
											message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				//[self setDeviceAuthorized:NO];
			});
		}
	}];
}





- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}





#pragma mark - Touch Events

-(void) registerWithTouchDispatcher
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}


- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint posUI = [touch locationInView:[touch view]];
    CGPoint pos = [[CCDirector sharedDirector] convertToGL:posUI];
    
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    
    CGPoint posUI = [touch locationInView:[touch view]];
    CGPoint pos = [[CCDirector sharedDirector] convertToGL:posUI];
    
    CGPoint prev = [touch previousLocationInView:[touch view]];
    prev = [[CCDirector sharedDirector] convertToGL:prev];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}




@end
