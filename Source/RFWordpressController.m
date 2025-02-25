//
//  RFWordpressController.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFWordpressController.h"

#import "RFXMLRPCRequest.h"
#import "RFXMLRPCParser.h"
#import "RFMacros.h"
#import "RFSettings.h"
#import "SAMKeychain.h"
#import "NSAlert+Extras.h"

@implementation RFWordpressController

- (instancetype) initWithWebsite:(NSString *)websiteURL rsdURL:(NSString *)rsdURL
{
	self = [super initWithWindowNibName:@"Wordpress"];
	if (self) {
		self.websiteURL = websiteURL;
		self.rsdURL = rsdURL;
	}
	
	return self;
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	
	self.websiteField.stringValue = [self normalizeURL:self.websiteURL];
}

- (NSString *) normalizeURL:(NSString *)url
{
	NSString* s = url;
	if (![s containsString:@"http"]) {
		s = [@"http://" stringByAppendingString:s];
	}
	
	return s;
}

- (void) saveAccountWithEndpointURL:(NSString *)xmlrpcEndpointURL blogID:(NSString *)blogID
{
	[RFSettings setString:self.usernameField.stringValue forKey:kExternalBlogUsername];
	[RFSettings setString:xmlrpcEndpointURL forKey:kExternalBlogEndpoint];
	[RFSettings setString:blogID forKey:kExternalBlogID];
	[RFSettings setBool:YES forKey:kExternalBlogIsPreferred];
	[SAMKeychain setPassword:self.passwordField.stringValue forService:@"ExternalBlog" account:self.usernameField.stringValue];
	
	if ([xmlrpcEndpointURL containsString:@"xmlrpc.php"]) {
		[RFSettings setString:@"WordPress" forKey:kExternalBlogApp];
	}
	else {
		[RFSettings setString:@"Other" forKey:kExternalBlogApp];
	}
}

- (void) verifyUsername:(NSString *)username password:(NSString *)password forEndpoint:(NSString *)xmlrpcEndpoint withCompletion:(void (^)())handler
{
	NSString* method_name = @"blogger.getUserInfo";
	NSString* app_key = @"";
	NSArray* params = @[ app_key, username, password ];
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpcEndpoint];
	[request sendMethod:method_name params:params completion:^(UUHttpResponse* response) {
		RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
		RFDispatchMainAsync ((^{
			if (xmlrpc.responseFault) {
				NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
				[NSAlert rf_showOneButtonAlert:@"Error Signing In" message:s button:@"OK" completionHandler:NULL];
				[self.progressSpinner stopAnimation:nil];
			}
			else {
				handler();
			}
		}));
	}];
}

#pragma mark -

- (IBAction) cancel:(id)sender
{
	[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction) finish:(id)sender
{
	[self.progressSpinner startAnimation:nil];
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:self.rsdURL];
	[request discoverEndpointWithCompletion:^(NSString* xmlrpcEndpointURL, NSString* blogID) {
		RFDispatchMainAsync (^{
			[self.progressSpinner stopAnimation:nil];
			if (xmlrpcEndpointURL && blogID) {
				[self verifyUsername:self.usernameField.stringValue password:self.passwordField.stringValue forEndpoint:xmlrpcEndpointURL withCompletion:^{
					[self saveAccountWithEndpointURL:xmlrpcEndpointURL blogID:blogID];

					[RFSettings removeObjectForKey:kExternalMicropubMe];

					[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
				}];
			}
			else {
				[NSAlert rf_showOneButtonAlert:@"Error Discovering Settings" message:@"Could not find the XML-RPC endpoint or Micropub API for your weblog." button:@"OK" completionHandler:NULL];
			}
		});
	}];
}

@end
