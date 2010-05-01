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


@interface PrefController : NSPreferencePane
{
	// Download Preferences
	Boolean *isEnabled;
	IBOutlet NSSegmentedControl *isEnabledControl;
	IBOutlet NSImageView *TVShowsAppImage;
	IBOutlet NSButton *autoOpenDownloadedFiles;

	// Growl Settings
	IBOutlet NSButton *growlNotifyEpisode;
	IBOutlet NSButton *growlNotifyApplication;

	// Application Update Preferences
	IBOutlet NSButton *checkForUpdates;
	IBOutlet NSButton *autoInstallNewUpdates;
	IBOutlet NSButton *downloadBetaVersions;
	IBOutlet NSButton *includeSystemInformation;
}

#pragma mark -
#pragma mark General
- (void) awakeFromNib;
- (void) syncPreferences;

#pragma mark -
#pragma mark Download Preferences
- (IBAction) isEnabledControlDidChange:(id)sender;
- (IBAction) autoOpenDownloadedFilesDidChange:(id)sender;

#pragma mark -
#pragma mark Growl Notification Preferences
- (IBAction) growlNotifyEpisodeDidChange:(id)sender;
- (IBAction) growlNotifyApplicationDidChange:(id)sender;

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender;
- (IBAction) autoInstallNewUpdatesDidChange:(id)sender;
- (IBAction) downloadBetaVersionsDidChange:(id)sender;
- (IBAction) includeSystemInformationDidChange:(id)sender;

@end
