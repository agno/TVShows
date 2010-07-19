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

#import <PreferencePanes/PreferencePanes.h>
#import <Cocoa/Cocoa.h>
#import "JRFeedbackController.h"

@interface TabController : NSPreferencePane
{
	IBOutlet NSTabView *prefTabView;
	IBOutlet NSButton *feedbackButton;
	NSManagedObject *selectedShow;
	
	// Getting started
	IBOutlet NSTextField *gettingStartedText;
	IBOutlet NSTextField *optionOneTitle;
	IBOutlet NSTextField *optionOneDesc;
	IBOutlet NSTextField *optionTwoTitle;
	IBOutlet NSTextField *optionTwoDesc;
	IBOutlet NSTextField *optionThreeTitle;
	IBOutlet NSTextField *optionThreeDesc;
	
	// Version information
	IBOutlet NSTextField *sidebarHeader;
	IBOutlet NSTextField *sidebarVersionText;
	IBOutlet NSTextField *sidebarDateText;
	IBOutlet NSTextField *aboutTabVersionText;
	
	// About tab
	IBOutlet NSTextView *textView_aboutBox;
	
	// Subscriptions tab
	IBOutlet NSArrayController *SBArrayController;
	IBOutlet NSWindow *showInfoWindow;
	
	// Show info window
	IBOutlet NSTextField *showName;
	IBOutlet NSTextField *showLastDownloaded;
	IBOutlet NSButton *showQuality;
	IBOutlet NSButton *showIsEnabled;
	IBOutlet NSArrayController *episodeArrayController;
	IBOutlet NSTableView *episodeTableView;
	IBOutlet NSTextField *statusTitle;
	IBOutlet NSTextField *lastAiredTitle;
	IBOutlet NSTextField *lastDownloadedTitle;
	IBOutlet NSBox *infoBoxTitle;
	IBOutlet NSBox *prefBoxTitle;
	IBOutlet NSButton *closeButton;
	IBOutlet NSButton *unsubscribeButton;
}

@property (retain) NSManagedObject *selectedShow;

- (void) awakeFromNib;
- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (IBAction) showFeedbackWindow:(id)sender;

#pragma mark -
#pragma mark About Tab
- (IBAction) openWebsite:(id)sender;
- (IBAction) openTwitter:(id)sender;
- (void) drawAboutBox;

#pragma mark -
#pragma mark Subscriptions TabController
- (IBAction) displayShowInfoWindow:(id)sender;
- (IBAction) closeShowInfoWindow:(id)sender;
- (IBAction) showQualityDidChange:(id)sender;
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName;
- (void) sortSubscriptionList;
- (IBAction) unsubscribeFromShow:(id)sender;

@end
