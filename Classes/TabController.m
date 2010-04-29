/*
 *	This file is part of the TVShows 2 ("Phoenix") source code.
 *	http://github.com/mattprice/TVShows/tree/Phoenix
 *
 *	TVShows is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with TVShows. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "TabController.h"
#import "FeedParser.h"

#define TVSHOWS_IDENTIFIER		@"com.github.TVShows2"
#define TVSHOWS_WEBSITE			@"http://deathtobunnies.com/tvshows/"


@implementation TabController

- (id) init
{
	[self drawAboutBox];
	return self;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	NSRect  tabFrame;
    int    newWinHeight;
	
	tabFrame = [[tabView window] frame];
	
    if ([[tabViewItem identifier] isEqualTo:@"tabItemPreferences"]) {
        newWinHeight = 512;
		
    } else if ([[tabViewItem identifier] isEqualTo:@"tabItemSubscriptions"]) {
        newWinHeight = 512;
		
    } else {
        newWinHeight = 422;
		
    }
	
	tabFrame = NSMakeRect(tabFrame.origin.x, tabFrame.origin.y - (newWinHeight - (int)(NSHeight(tabFrame))), (int)(NSWidth(tabFrame)), newWinHeight);
	
    [[tabView window] setFrame:tabFrame display:YES animate:YES];
}

#pragma mark -
#pragma mark Leftover Test Code
- (IBAction)showRssFeed:(id)sender
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSError * error;
	NSURL * url = [NSURL URLWithString:@"http://antwrp.gsfc.nasa.gov/apod.rss"];
	NSData * data = [NSData dataWithContentsOfURL:url];
	FPFeed * feed = [FPParser parsedFeedWithData:data error:&error];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Title: %@\n", feed.title]];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Description: %@\n", feed.feedDescription]];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Date published: %@\n\n", [feed.pubDate description]]];
	for (FPItem * item in feed.items)
	{
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Title: %@\n", item.title]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Link: href:%@ \t + rel: %@ + \t type: %@ \t + title:%@\n", item.link.href, item.link.rel, item.link.type, item.link.title]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item GUID: %@\n", item.guid]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Description: %@\n", item.description]];  
	}
	[pool drain];
}

#pragma mark -
#pragma mark About Tab
- (IBAction) visitWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TVSHOWS_WEBSITE]];
}

- (IBAction) showLicenseInfo:(id)sender
{
	NSString *licenseInfoText;
	
    [NSApp beginSheet: licenseInfoDialog
	   modalForWindow: [[NSApplication sharedApplication] mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];

	licenseInfoText = [NSString stringWithContentsOfURL:
					   [NSURL fileURLWithPath: [[NSBundle bundleWithIdentifier:TVSHOWS_IDENTIFIER]
										pathForResource: @"LICENSE" ofType:@"txt"]]
											   encoding: NSUTF8StringEncoding
												  error: NULL];
	
	[textView_licenseInfo setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
	[textView_licenseInfo setString:licenseInfoText];
	
    [NSApp runModalForWindow: licenseInfoDialog];
	[NSApp endSheet: licenseInfoDialog];
}

- (IBAction) closeLicenseInfoDialog:(id)sender
{	
    [NSApp stopModal];
    [licenseInfoDialog orderOut: self];
}

- (void) drawAboutBox {
	NSString *pathToAboutBoxText = [[NSBundle bundleWithIdentifier: TVSHOWS_IDENTIFIER]
									pathForResource: @"Credits"
									ofType: @"rtfd"];
	
	NSAttributedString *aboutBoxText = [[NSAttributedString alloc]
										initWithPath: pathToAboutBoxText
										documentAttributes: NULL];

	[textView_aboutBox setString: @"TEST"];
	NSLog(@"Test");
	[[textView_aboutBox textStorage] setAttributedString:aboutBoxText];
}

@end
