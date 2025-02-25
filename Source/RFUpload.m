//
//  RFUpload.m
//  Snippets
//
//  Created by Manton Reece on 7/14/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFUpload.h"

@implementation RFUpload

- (instancetype) initWithURL:(NSString *)url
{
	self = [super init];
	if (self) {
		self.url = url;
	}
	
	return self;
}

- (NSString *) filename
{
	return [self.url lastPathComponent];
}

- (BOOL) isPhoto
{
	NSString* e = [[[self filename] pathExtension] lowercaseString];
	return ([e isEqualToString:@"jpg"] || [e isEqualToString:@"jpeg"] || [e isEqualToString:@"png"] || [e isEqualToString:@"gif"] || [e isEqualToString:@"webp"]);
}

- (BOOL) isVideo
{
	NSString* e = [[[self filename] pathExtension] lowercaseString];
	return ([e isEqualToString:@"mov"] || [e isEqualToString:@"m4v"] || [e isEqualToString:@"mp4"]);
}

- (BOOL) isAudio
{
	NSString* e = [[[self filename] pathExtension] lowercaseString];
	return ([e isEqualToString:@"mp3"] || [e isEqualToString:@"m4a"]);
}

@end
