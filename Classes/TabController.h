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

#import <PreferencePanes/PreferencePanes.h>
#import <Cocoa/Cocoa.h>


@interface TabController : NSObject
{
	IBOutlet NSTextView *mainTextView;
	
	IBOutlet NSWindow *licenseInfoDialog;
	IBOutlet NSTextView *textView_licenseInfo;
	IBOutlet NSTextView *textView_aboutBox;
}


#pragma mark -
#pragma mark Leftover Test Code
- (IBAction) showRssFeed:(id)sender;
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark -
#pragma mark About Tab
- (IBAction) visitWebsite:(id)sender;
- (IBAction) showLicenseInfo:(id)sender;
- (IBAction) closeLicenseInfoDialog:(id)sender;
- (void) drawAboutBox;

@end
