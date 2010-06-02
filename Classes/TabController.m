/*
 *	This file is part of the TVShows 2 ("Phoenix") source code.
 *	http://github.com/mattprice/TVShows/
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
#import "AppInfoConstants.h"
#import "SubscriptionsDelegate.h"


@implementation TabController

@synthesize selectedShow;

- (void) awakeFromNib
{
	// Set displayed version information
	NSString *bundleVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary] 
							   valueForKey:@"CFBundleShortVersionString"];
	NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
							  valueForKey:@"CFBundleVersion"];
	NSString *buildDate = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
						   valueForKey:@"TSBundleBuildDate"];

	[sidebarHeader setStringValue: [NSString stringWithFormat:@"TVShows 2", bundleVersion]];
	[sidebarVersionText setStringValue: [NSString stringWithFormat:@"%@ (r%@)", bundleVersion, buildVersion]];
	[sidebarDateText setStringValue: buildDate];
	
	[aboutTabVersionText setStringValue: [NSString stringWithFormat:@"TVShows %@ (%@)", bundleVersion, buildVersion]];
	
	[self sortSubscriptionList];
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSRect  tabFrame;
    int    newWinHeight;
	
	// newWinHeight should be equal to the wanted window size (in Interface Builder) + 54 (title bar height)
	
	tabFrame = [[tabView window] frame];
	
    if ([[tabViewItem identifier] isEqualTo:@"tabItemPreferences"]) {
        newWinHeight = 526;
		
    } else if ([[tabViewItem identifier] isEqualTo:@"tabItemSubscriptions"]) {
        newWinHeight = 526;
		
    }  else if ([[tabViewItem identifier] isEqualTo:@"tabItemAbout"]) {
		[self drawAboutBox];
        newWinHeight = 422;
		
    } else {
        newWinHeight = 422;
    }
	
	tabFrame = NSMakeRect(tabFrame.origin.x, tabFrame.origin.y - (newWinHeight - (int)(NSHeight(tabFrame))), (int)(NSWidth(tabFrame)), newWinHeight);
	
    [[tabView window] setFrame:tabFrame display:YES animate:YES];
}

- (IBAction) showFeedbackWindow:(id)sender
{
	[JRFeedbackController showFeedback];
}

#pragma mark -
#pragma mark About Tab
- (IBAction) visitWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: TVShowsWebsite]];
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
					   [NSURL fileURLWithPath:
						[[NSBundle bundleWithIdentifier: TVShowsAppDomain]
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

- (void) drawAboutBox
{
	NSString *pathToAboutBoxText = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] 
									pathForResource: @"Credits" 
									ofType: @"rtf"];
	
	NSAttributedString *aboutBoxText = [[[NSAttributedString alloc]
										initWithPath: pathToAboutBoxText
										documentAttributes: nil] autorelease];

	[[textView_aboutBox textStorage] setAttributedString:aboutBoxText];
}

#pragma mark -
#pragma mark Subscriptions Tab
- (IBAction) displayShowInfoWindow:(id)sender
{
	// Not sure why I have to call representedObject twice, but it works
	selectedShow = [[[sender cell] representedObject] representedObject];
	
	[showName setStringValue: [selectedShow valueForKey:@"name"]];
	[showQuality setState: [[selectedShow valueForKey:@"quality"] intValue]];
	[showIsEnabled setState: [[selectedShow valueForKey:@"isEnabled"] intValue]];
	
	[NSApp beginSheet: showInfoWindow
	   modalForWindow: [[NSApplication sharedApplication] mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
    [NSApp runModalForWindow: showInfoWindow];
	[NSApp endSheet: showInfoWindow];
}

- (IBAction) closeShowInfoWindow:(id)sender
{	
	selectedShow = nil;
	
    [NSApp stopModal];
    [showInfoWindow orderOut: self];
}

- (void) sortSubscriptionList
{
	NSSortDescriptor *SBSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"sortName"
																	 ascending: YES 
																	  selector: @selector(caseInsensitiveCompare:)];
	[SBArrayController setSortDescriptors:[NSArray arrayWithObject:SBSortDescriptor]];
	
	[SBSortDescriptor release];
}

- (IBAction) unsubscribeFromShow:(id)sender
{
	id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
	
	// I don't understand why I have to remove the object from both locations
	// but this should work for the time being.
	[SBArrayController removeObject:selectedShow];
	[[delegateClass managedObjectContext] deleteObject:selectedShow];
		
	[self closeShowInfoWindow:(id)sender];

	[delegateClass saveAction];
	[delegateClass release];
}


- (void) dealloc
{
	[selectedShow release];
    [super dealloc];
}

@end
