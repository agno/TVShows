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


@interface PrefController : NSPreferencePane
{
	// Download Preferences
	Boolean isEnabled;
	int defaultQuality;
	IBOutlet NSSegmentedControl *isEnabledControl;
	IBOutlet NSImageView *TVShowsAppImage;
	IBOutlet NSPopUpButton *episodeCheckDelay;
	IBOutlet NSPopUpButton *downloadLocationMenu;
	IBOutlet NSMatrix *defaultVideoQuality;
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
#pragma mark Preferences Functions
- (BOOL) getBoolFromKey:(NSString *)key withDefault:(BOOL)defaultValue;
- (void) setKey:(NSString *)key fromBool:(BOOL)value;

- (float) getFloatFromKey:(NSString *)key withDefault:(float)defaultValue;
- (void) setKey:(NSString *)key fromFloat:(float)value;

- (unsigned int) getUnsignedIntFromKey:(NSString *)key withDefault:(int)defaultValue;
- (void) setKey:(NSString *)key fromInt:(int)value;

- (NSString *) getStringFromKey:(NSString *)key;
- (void) setKey:(NSString *)key fromString:(NSString *)value;

- (NSDate *) getDateFromKey:(NSString *)key;
- (void) setKey:(NSString *)key fromDate:(NSDate *)value;

#pragma mark -
#pragma mark General
- init;
- (void) awakeFromNib;
- (void) setDefaultUserDefaults;
- (void) loadSavedDefaults;

#pragma mark -
#pragma mark Download Preferences
- (IBAction) isEnabledControlDidChange:(id)sender;
- (IBAction) episodeCheckDelayDidChange:(id)sender;
- (void) buildDownloadLocationMenu;
- (NSMenu *) downloadLocationMenu;
- (void) selectOtherDownloadFolder:(id)sender;
- (void) openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction) defaultVideoQualityDidChange:(id)sender;
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
