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

#import "PreferencesController.h"
#import "TSUserDefaults.h"
#import "AppInfoConstants.h"


@implementation PreferencesController

#pragma mark -
#pragma mark General
- init
{
	if((self = [super init])) {
		// Set default user preferences if TVShows has never launched
		// In a perfect world this would check for any keys that don't
		// exist, regardless of whether we've launched before or not.
		
		if ([TSUserDefaults getBoolFromKey:@"hasLaunched" withDefault:0] == 0) {
			[self setDefaultUserDefaults];
		}
	}
	
	return self;
}

- (void) awakeFromNib
{
	// Load the user's preferences
	[self loadSavedDefaults];
	
	NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
							  valueForKey:@"CFBundleVersion"];
	
	// Update the application build number in installedBuild
	// (Allows us to run build specific update sequences)
	[TSUserDefaults setKey:@"installedBuild" fromString:buildVersion];
}

- (void) setDefaultUserDefaults
{
	[TSUserDefaults setKey:@"AutoOpenDownloadedFiles"	fromBool:YES];
	[TSUserDefaults setKey:@"checkDelay"				fromFloat:0];
	[TSUserDefaults setKey:@"defaultQuality"			fromFloat:0];
	[TSUserDefaults setKey:@"downloadFolder"			fromString:[NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"]];
	[TSUserDefaults setKey:@"GrowlOnAppUpdate"			fromBool:YES];
	[TSUserDefaults setKey:@"GrowlOnNewEpisode"			fromBool:YES];
	[TSUserDefaults setKey:@"hasLaunched"				fromBool:YES];
	[TSUserDefaults setKey:@"isEnabled"					fromBool:YES];
	[TSUserDefaults setKey:@"SUAutomaticallyUpdate"		fromBool:YES];
	[TSUserDefaults setKey:@"SUDownloadBetaVersions"	fromBool:NO];
	[TSUserDefaults setKey:@"SUEnableAutomaticChecks"	fromBool:YES];
	[TSUserDefaults setKey:@"SUFeedURL"					fromString:TVShowsAppcastURL];
	[TSUserDefaults setKey:@"SUSendProfileInfo"			fromBool:YES];
}

- (void) loadSavedDefaults
{
	// Load download preferences
	// -------------------------
	if ([TSUserDefaults getBoolFromKey:@"isEnabled" withDefault:1]) {
		isEnabled = 1;
		[isEnabledControl setSelectedSegment: 1];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									 [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									  pathForResource: @"TVShows-Beta-Large" ofType: @"icns"]] autorelease]];
	} else {
		isEnabled = 0;
		[isEnabledControl setSelectedSegment: 0];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									 [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									  pathForResource: @"TVShows-Off-Large" ofType: @"icns"]] autorelease]];
	}
	
	[autoOpenDownloadedFiles setState: [TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]];
	[episodeCheckDelay selectItemAtIndex: [TSUserDefaults getFloatFromKey:@"checkDelay" withDefault:0]];
	
	defaultQuality = [TSUserDefaults getFloatFromKey:@"defaultQuality" withDefault:0];
	[defaultVideoQuality setState: 1
							atRow: defaultQuality
						   column: 0];
	
	[self buildDownloadLocationMenu];
	
	// Load Growl notification preferences
	// -----------------------------------
	[growlNotifyEpisode			setState: [TSUserDefaults getBoolFromKey:@"GrowlOnNewEpisode" withDefault:1]];
	[growlNotifyApplication		setState: [TSUserDefaults getBoolFromKey:@"GrowlOnAppUpdate" withDefault:1]];
	
	// Load Sparkle preferences
	// ------------------------
	if ([TSUserDefaults getBoolFromKey:@"SUEnableAutomaticChecks" withDefault:1] == 0) {
		[checkForUpdates			setState: 0];
		[autoInstallNewUpdates		setEnabled: NO];
		[includeSystemInformation	setEnabled: NO];
		[downloadBetaVersions		setEnabled: NO];
	}
	[downloadBetaVersions		setState: [TSUserDefaults getBoolFromKey:@"SUDownloadBetaVersions" withDefault:1]];
	[autoInstallNewUpdates		setState: [TSUserDefaults getBoolFromKey:@"SUAutomaticallyUpdate" withDefault:1]];
	[includeSystemInformation	setState: [TSUserDefaults getBoolFromKey:@"SUSendProfileInfo" withDefault:1]];
}

#pragma mark -
#pragma mark Download Preferences
- (IBAction) isEnabledControlDidChange:(id)sender
{
	if ([isEnabledControl selectedSegment]) {
		isEnabled = 1;
		[TSUserDefaults setKey:@"isEnabled" fromBool: 1];
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									 [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									  pathForResource: @"TVShows-Beta-Large" ofType: @"icns"]] autorelease]];
	} else {
		isEnabled = 0;
		[TSUserDefaults setKey:@"isEnabled" fromBool: 0];
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									 [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									  pathForResource: @"TVShows-Off-Large" ofType: @"icns"]] autorelease]];
	}
}

- (IBAction) episodeCheckDelayDidChange:(id)sender
{
	[TSUserDefaults setKey:@"checkDelay" fromFloat: [episodeCheckDelay indexOfSelectedItem]];
}

// Modified from the Adium prefence window source code
// Original version: http://hg.adium.im/adium/file/tip/Source/ESFileTransferPreferences.m
- (void) buildDownloadLocationMenu
{
	[downloadLocationMenu setMenu: [self downloadLocationMenu]];
	[downloadLocationMenu selectItem: [downloadLocationMenu itemAtIndex:0]];
}

- (NSMenu *) downloadLocationMenu
{
	NSMenu		*menu;
	NSMenuItem	*menuItem;
	NSString	*userPreferredDownloadFolder;
	NSImage		*iconForDownloadFolder;
	
	menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	[menu setAutoenablesItems:NO];
	
	// Create the menu item for the current download folder
	userPreferredDownloadFolder = [TSUserDefaults getStringFromKey:@"downloadFolder"];
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle: [[NSFileManager defaultManager] displayNameAtPath:userPreferredDownloadFolder]
																	 action: nil
															  keyEquivalent: @""] autorelease];

	// Get the download folder's icon and resize it
	iconForDownloadFolder = [[NSWorkspace sharedWorkspace] iconForFile:userPreferredDownloadFolder];
	[iconForDownloadFolder setSize:NSMakeSize(16, 16)];
	
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menuItem setImage:iconForDownloadFolder];
	[menu addItem:menuItem];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	// Create the menu item for changing the current download folder
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Other..."
																	 action:@selector(selectOtherDownloadFolder:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menu addItem:menuItem];
	
	return menu;
}

- (void) selectOtherDownloadFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSString	*userPreferredDownloadFolder = [sender representedObject];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	
	[openPanel beginSheetForDirectory:userPreferredDownloadFolder
								 file:nil
								types:nil
					   modalForWindow:[[NSApplication sharedApplication] mainWindow]
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (void) openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[TSUserDefaults setKey:@"downloadFolder" fromString:[openPanel filename]];
	}
	
	[self buildDownloadLocationMenu];
}

- (IBAction) defaultVideoQualityDidChange:(id)sender
{
	[TSUserDefaults setKey:@"defaultQuality" fromFloat: [defaultVideoQuality selectedRow]];
}

- (IBAction) autoOpenDownloadedFilesDidChange:(id)sender
{
	[TSUserDefaults setKey:@"AutoOpenDownloadedFiles" fromBool: [autoOpenDownloadedFiles state]];
}

#pragma mark -
#pragma mark Growl Notification Preferences
- (IBAction) growlNotifyEpisodeDidChange:(id)sender
{
	[TSUserDefaults setKey:@"GrowlOnNewEpisode" fromBool: [growlNotifyEpisode state]];
}

- (IBAction) growlNotifyApplicationDidChange:(id)sender
{
	[TSUserDefaults setKey:@"GrowlOnAppUpdate" fromBool: [growlNotifyApplication state]];
}

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender
{
	if ([checkForUpdates state]) {
		[TSUserDefaults setKey:@"SUEnableAutomaticChecks" fromBool: 1];
		
		[autoInstallNewUpdates setEnabled: YES];
		[includeSystemInformation setEnabled: YES];
		[downloadBetaVersions setEnabled: YES];
	} else {
		[TSUserDefaults setKey:@"SUEnableAutomaticChecks" fromBool: 0];
		
		[autoInstallNewUpdates setEnabled: NO];
		[includeSystemInformation setEnabled: NO];
		[downloadBetaVersions setEnabled: NO];
	}
}

- (IBAction) autoInstallNewUpdatesDidChange:(id)sender
{
	[TSUserDefaults setKey:@"SUAutomaticallyUpdate" fromBool: [autoInstallNewUpdates state]];
}

- (IBAction) downloadBetaVersionsDidChange:(id)sender
{
	if ([downloadBetaVersions state]) {
		[TSUserDefaults setKey:@"SUDownloadBetaVersions" fromBool: 1];
		[TSUserDefaults setKey:@"SUFeedURL" fromString:TVShowsBetaAppcastURL];
	} else {
		[TSUserDefaults setKey:@"SUDownloadBetaVersions" fromBool: 0];
		[TSUserDefaults setKey:@"SUFeedURL" fromString:TVShowsAppcastURL];
	}
}

- (IBAction) includeSystemInformationDidChange:(id)sender
{
	[TSUserDefaults setKey:@"SUSendProfileInfo" fromBool: [includeSystemInformation state]];
}

@end
