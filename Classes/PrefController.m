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

#import "PrefController.h"
#import "Constants.h"


// Setup CFPreference variables
CFStringRef prefAppDomain = (CFStringRef)TVShowsAppDomain;
CFStringRef prefValueToSave;
CFBooleanRef checkBoxValue;

@implementation PrefController

#pragma mark -
#pragma mark General
- (void) awakeFromNib
{
	// Saved for reference. Not everything is a BOOL.
	// CFPreferencesCopyAppValue();
	
	// Register download preferences
	// -----------------------------
	if (CFPreferencesGetAppBooleanValue(CFSTR("isEnabled"), prefAppDomain, NULL)) {
		[isEnabledControl setSelectedSegment: 1];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									[[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									 pathForResource: @"TVShows-Beta-Large" ofType: @"icns"]] autorelease]];
	} else {
		[isEnabledControl setSelectedSegment: 0];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									[[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									 pathForResource: @"TVShows-Off-Large" ofType: @"icns"]] autorelease]];
	}
		[autoOpenDownloadedFiles	setState: CFPreferencesGetAppBooleanValue(CFSTR("AutoOpenDownloadedFiles"), prefAppDomain, NULL)];
	
	// Register Growl notification preferences
	// ---------------------------------------
		[growlNotifyEpisode			setState: CFPreferencesGetAppBooleanValue(CFSTR("GrowlOnNewEpisode"), prefAppDomain, NULL)];
		[growlNotifyApplication		setState: CFPreferencesGetAppBooleanValue(CFSTR("GrowlOnAppUpdate"), prefAppDomain, NULL)];
	
	// Register application update preferences
	// ---------------------------------------
	if (CFPreferencesGetAppBooleanValue(CFSTR("SUEnableAutomaticChecks"), prefAppDomain, NULL) == 0) {
		[checkForUpdates			setState: 0];
		[autoInstallNewUpdates		setEnabled: NO];
		[includeSystemInformation	setEnabled: NO];
		[downloadBetaVersions		setEnabled: NO];
	}
		[downloadBetaVersions		setState: CFPreferencesGetAppBooleanValue(CFSTR("SUDownloadBetaVersions"), prefAppDomain, NULL)];
		[autoInstallNewUpdates		setState: CFPreferencesGetAppBooleanValue(CFSTR("SUAutomaticallyUpdate"), prefAppDomain, NULL)];
		[includeSystemInformation	setState: CFPreferencesGetAppBooleanValue(CFSTR("SUSendProfileInfo"), prefAppDomain, NULL)];
}

- (void) syncPreferences
{
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

#pragma mark -
#pragma mark Download Preferences
- (IBAction) isEnabledControlDidChange:(id)sender
{
	NSString *appIconPath;
	
	if ([isEnabledControl selectedSegment]) {
		checkBoxValue = kCFBooleanTrue;
		
		appIconPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] pathForResource: @"TVShows-Beta-Large" ofType: @"icns"];
		
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile: appIconPath] autorelease]];
	} else {
		checkBoxValue = kCFBooleanFalse;
		
		appIconPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
					   pathForResource: @"TVShows-Off-Large" ofType: @"icns"];
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile: appIconPath] autorelease]];
	}
	
	CFPreferencesSetValue(CFSTR("isEnabled"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) autoOpenDownloadedFilesDidChange:(id)sender
{
	if ([autoOpenDownloadedFiles state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(CFSTR("AutoOpenDownloadedFiles"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

#pragma mark -
#pragma mark Growl Notification Preferences
- (IBAction) growlNotifyEpisodeDidChange:(id)sender
{
	if ([growlNotifyEpisode state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(CFSTR("GrowlOnNewEpisode"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) growlNotifyApplicationDidChange:(id)sender
{
	if ([growlNotifyApplication state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(CFSTR("GrowlOnAppUpdate"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender
{
	if ([checkForUpdates state]) {
		checkBoxValue = kCFBooleanTrue;
		
		[autoInstallNewUpdates setEnabled: YES];
		[includeSystemInformation setEnabled: YES];
		[downloadBetaVersions setEnabled: YES];
	} else {
		checkBoxValue = kCFBooleanFalse;
		
		[autoInstallNewUpdates setEnabled: NO];
		[includeSystemInformation setEnabled: NO];
		[downloadBetaVersions setEnabled: NO];
	}
	
	CFPreferencesSetValue(CFSTR("SUEnableAutomaticChecks"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) autoInstallNewUpdatesDidChange:(id)sender
{
	if ([autoInstallNewUpdates state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(CFSTR("SUAutomaticallyUpdate"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) downloadBetaVersionsDidChange:(id)sender
{
	if ([downloadBetaVersions state]) {
		checkBoxValue = kCFBooleanTrue;
		CFPreferencesSetValue(CFSTR("SUFeedURL"), (CFStringRef)TVShowsBetaAppcastURL, prefAppDomain,
							  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	} else {
		checkBoxValue = kCFBooleanFalse;
		CFPreferencesSetValue(CFSTR("SUFeedURL"), (CFStringRef)TVShowsAppcastURL, prefAppDomain, 
							  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	}
	
	CFPreferencesSetValue(CFSTR("SUDownloadBetaVersions"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	
	[self syncPreferences];
}

- (IBAction) includeSystemInformationDidChange:(id)sender
{
	if ([includeSystemInformation state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(CFSTR("SUSendProfileInfo"), checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

@end
