//
//  main.m
//  html2pdf
//
//  Created by Samantha Marshall on 8/23/15.
//  Copyright (c) 2015 Samantha Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#include <iso646.h>

@interface WebView2PDF : NSObject <WebFrameLoadDelegate, WebResourceLoadDelegate>

- (instancetype)initWithURL:(NSURL *)url andBase:(NSURL *)baseDirURL;
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;
- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

@end

@interface WebView2PDF () {
	NSString *_outputPath;
	NSString *_baseDir;
}
@end

@implementation WebView2PDF

- (instancetype)initWithURL:(NSURL *)url andBase:(NSURL *)baseDirURL
{
	self = [super init];
	if (self != nil) {
		_outputPath = [[url path] stringByDeletingPathExtension];
		_baseDir = [baseDirURL path];
	}
	return self;
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	NSURL *localURL = [request URL];
	if ([localURL checkResourceIsReachableAndReturnError:nil] == NO and [localURL isFileURL] == YES) {
		NSString *localPath = [_baseDir stringByAppendingPathComponent:[localURL path]];
		NSURL *newURL = [NSURL fileURLWithPath:localPath];
		
		request = [NSURLRequest requestWithURL:newURL];
	}
	return request;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	NSLog(@"%@", error);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSView *pageView = [[[sender mainFrame] frameView] documentView];
	NSData *pdfData = [pageView dataWithPDFInsideRect:[pageView bounds]];

	NSString *documentPath = [NSString stringWithFormat:@"%@.pdf", _outputPath];
	[pdfData writeToFile:documentPath atomically:YES];
	
	CFRunLoopStop(CFRunLoopGetCurrent());
}

@end

void usage(void)
{
	printf("html2pdf -- Converts local html files into PDF documents\n");
	printf("\n");
	printf("Arguments:\n");
	printf("	-h		Displays help and usage\n");
	printf("	-b <path>	Pass the base path to use for relative links\n");
	printf("	-i <path>	Pass input file, pdf will be written alongside this file with the same name\n");
	printf("\n");
}

int main(int argc, const char *argv[])
{
	@autoreleasepool
	{
		NSDictionary *arguments = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
		if ([arguments count] == 0 or [arguments objectForKey:@"h"]) {
			usage();
			return 0;
		}
		
		NSString *inputPath = [arguments objectForKey:@"i"];
		NSString *basePath = [arguments objectForKey:@"b"];
		if ([arguments count] == 2 and (inputPath != nil and basePath != nil)) {
			NSURL *htmlURL = [NSURL fileURLWithPath:inputPath];
			NSURL *baseURL = [NSURL fileURLWithPath:basePath];
			if (([htmlURL isFileURL] == YES and [[NSFileManager defaultManager] fileExistsAtPath:inputPath] == YES) and ([baseURL isFileURL] == YES and [[NSFileManager defaultManager] fileExistsAtPath:basePath] == YES)) {
				WebView2PDF *loadDelegate = [[WebView2PDF alloc] initWithURL:htmlURL andBase:baseURL];
				WebView *webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 1280, 720) frameName:nil groupName:nil];
				[webView setFrameLoadDelegate:loadDelegate];
				[webView setResourceLoadDelegate:loadDelegate];
				[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:htmlURL]];
				CFRunLoopRun();
			}
			else {
				printf("Could not lookup files!\n");
			}
		}
		else {
			printf("Did not provide%s%s\n", (inputPath == nil ? " \"-i\"" : ""), (basePath == nil ? " \"-b\"" : ""));
		}
	}
	return 0;
}
