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
CFStringRef prefKeyToSave;
CFStringRef prefValueToSave;
CFBooleanRef checkBoxValue;

@implementation PrefController

#pragma mark -
#pragma mark General
- (id) init
{
	// Read preferences here.
}

- (void) syncPreferences
{
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender
{
	prefKeyToSave = CFSTR("SUEnableAutomaticChecks");
	
	if ([checkForUpdates state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(prefKeyToSave, checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) autoInstallNewUpdatesDidChange:(id)sender
{
		prefKeyToSave = CFSTR("SUAutomaticallyUpdate");
	
	if ([autoInstallNewUpdates state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(prefKeyToSave, checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

- (IBAction) downloadBetaVersionsDidChange:(id)sender
{
	NSLog(@"No actions set for downloadBetaVersionsDidChange:");
}

- (IBAction) includeSystemInformationDidChange:(id)sender
{
	prefKeyToSave = CFSTR("SUSendProfileInfo");
	
	if ([includeSystemInformation state])
		checkBoxValue = kCFBooleanTrue;
	else
		checkBoxValue = kCFBooleanFalse;
	
	CFPreferencesSetValue(prefKeyToSave, checkBoxValue, prefAppDomain,
						  kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[self syncPreferences];
}

@end
