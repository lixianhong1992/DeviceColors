//
//  FTViewController.m
//  DeviceColors
//
//  Copyright (C) 2013 by Ortwin Gentz, FutureTap GmbH
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "FTViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#include <sys/utsname.h>

@interface FTViewController ()
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *horizontalSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageBottomConstraint;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *labelContainerView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *modelLabel;
@property (strong, nonatomic) IBOutlet UILabel *deviceColorLabel;
@property (strong, nonatomic) IBOutlet UIWebView *deviceColorWebView;
@property (strong, nonatomic) IBOutlet UIWebView *deviceEnclosureColorWebView;

@property (strong, nonatomic) NSString *deviceColor;
@property (strong, nonatomic) NSString *deviceEnclosureColor;
@end

@implementation FTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];
	
	self.deviceColorWebView.scrollView.scrollEnabled = NO;
	self.deviceColorWebView.layer.borderColor = [UIColor grayColor].CGColor;
	self.deviceColorWebView.layer.borderWidth = 1;

	self.deviceEnclosureColorWebView.scrollView.scrollEnabled = NO;
	self.deviceEnclosureColorWebView.layer.borderColor = [UIColor grayColor].CGColor;
	self.deviceEnclosureColorWebView.layer.borderWidth = 1;
	
	UIDevice *device = [UIDevice currentDevice];
	NSString *modelCode = [self hardwareModel];
	NSString *modelName = @"";
	
	SEL selector = NSSelectorFromString(@"deviceInfoForKey:");
	if (![device respondsToSelector:selector]) {
		selector = NSSelectorFromString(@"_deviceInfoForKey:");
	}
	
	if ([device respondsToSelector:selector]) {
		// private API! Do not use in App Store builds!
		self.deviceColor = [device performSelector:selector withObject:@"DeviceColor"];
		self.deviceEnclosureColor = [device performSelector:selector withObject:@"DeviceEnclosureColor"];
	} else {
		[[[UIAlertView alloc] initWithTitle:@"selector not found" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}
	NSString *color = self.deviceEnclosureColor && ![self.deviceEnclosureColor isEqualToString:@"unknown"] ? self.deviceEnclosureColor : self.deviceColor;
	color = [color stringByReplacingOccurrencesOfString:@"#" withString:@""];
	
	NSArray *models = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]][@"UTExportedTypeDeclarations"];
	for (NSDictionary *modelDict in models) {
		if ([(NSArray*)modelDict[@"UTTypeTagSpecification"][@"com.apple.device-model-code"] containsObject:modelCode]) {
			if ([modelDict[@"UTTypeIdentifier"] hasSuffix:color]) {
				NSString *imageName = [modelDict[@"UTTypeIconFile"] stringByReplacingOccurrencesOfString:@".icns" withString:@".jpg"];
				self.imageView.image = [UIImage imageNamed:imageName];
				
				modelName = modelDict[@"UTTypeDescription"];
			}
		}
	}

	self.nameLabel.text = modelName;
	self.modelLabel.text = modelCode;

	NSString *htmlStringFormat = @"<html><body style=\"margin: 5px; font: 13px '%@', Helvetica; background-color: %@; color: %@;\">%@</body></html>";
	
	NSString *fontName = self.deviceColorLabel.font.fontName;
	
	NSArray *darkColors = @[@"black", @"#3b3b3c", @"#99989b"];
	NSString *deviceForegroundColor = [darkColors containsObject:self.deviceColor] ? @"white" : @"black";
	NSString *deviceColorHTML = [NSString stringWithFormat:htmlStringFormat, fontName, self.deviceColor, deviceForegroundColor, self.deviceColor];
	
	NSString *deviceEnclosureForegroundColor = [darkColors containsObject:self.deviceEnclosureColor] ? @"white" : @"black";
	NSString *deviceEnclosureColorHTML = [NSString stringWithFormat:htmlStringFormat, fontName, self.deviceEnclosureColor, deviceEnclosureForegroundColor, self.deviceEnclosureColor];
	
	[self.deviceColorWebView loadHTMLString:deviceColorHTML baseURL:nil];
	[self.deviceEnclosureColorWebView loadHTMLString:deviceEnclosureColorHTML baseURL:nil];
}

- (IBAction)share:(id)sender {
	NSArray *activityItems = @[[NSString stringWithFormat:@"DeviceColor Report\n\n%@ (%@)\nDeviceColor: %@\nDeviceEnclosureColor: %@\n", self.nameLabel.text, self.modelLabel.text, self.deviceColor, self.deviceEnclosureColor],
							   [NSURL URLWithString:@"https://github.com/futuretap/DeviceColors"]];
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	[self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	self.horizontalSpaceConstraint.constant = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 40 -self.view.frame.size.width : 20;
	self.imageBottomConstraint.constant = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? self.labelContainerView.frame.size.height + 40 : 20;
}

- (NSString*)hardwareModel {
	struct utsname u;

	uname(&u);
	
	return @(u.machine);
}

@end
