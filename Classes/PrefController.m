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
CFBooleanRef checkBoxValue;

@implementation PrefController

#pragma mark -
#pragma mark Preferences Functions

// Modified from the Perian prefPane source code
// Original version: http://svn.perian.org/trunk/CPFPerianPrefPaneController.m

- (BOOL) getBoolFromKey:(NSString *)key withDefault:(BOOL)defaultValue
{
	Boolean ret, exists = FALSE;
	
	ret = CFPreferencesGetAppBooleanValue((CFStringRef)key, prefAppDomain, &exists);
	
	return exists ? ret : defaultValue;
}

- (void) setKey:(NSString *)key fromBool:(BOOL)value
{
	CFPreferencesSetAppValue((CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, prefAppDomain);
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (float) getFloatFromKey:(NSString *)key withDefault:(float)defaultValue
{
	CFPropertyListRef value;
	float ret = defaultValue;
	
	value = CFPreferencesCopyAppValue((CFStringRef)key, prefAppDomain);
	if(value && CFGetTypeID(value) == CFNumberGetTypeID())
		CFNumberGetValue(value, kCFNumberFloatType, &ret);
	
	if(value)
		CFRelease(value);
	
	return ret;
}

- (void) setKey:(NSString *)key fromFloat:(float)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberFloatType, &value);
	CFPreferencesSetAppValue((CFStringRef)key, numRef, prefAppDomain);
	CFRelease(numRef);
	
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (unsigned int) getUnsignedIntFromKey:(NSString *)key withDefault:(int)defaultValue
{
	int ret; Boolean exists = FALSE;
	
	ret = CFPreferencesGetAppIntegerValue((CFStringRef)key, prefAppDomain, &exists);
	
	return exists ? ret : defaultValue;
}

- (void) setKey:(NSString *)key fromInt:(int)value
{
	CFNumberRef numRef = CFNumberCreate(NULL, kCFNumberIntType, &value);
	CFPreferencesSetAppValue((CFStringRef)key, numRef, prefAppDomain);
	CFRelease(numRef);
	
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (NSString *) getStringFromKey:(NSString *)key
{
	CFPropertyListRef value;
	
	value = CFPreferencesCopyAppValue((CFStringRef)key, prefAppDomain);
	
	if(value) {
		CFMakeCollectable(value);
		[(id)value autorelease];
		
		if (CFGetTypeID(value) != CFStringGetTypeID())
			return nil;
	}
	
	return (NSString*)value;
}

- (void) setKey:(NSString *)key fromString:(NSString *)value
{
	CFPreferencesSetAppValue((CFStringRef)key, value, prefAppDomain);
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (NSDate *) getDateFromKey:(NSString *)key
{
	CFPropertyListRef value;
	NSDate *ret = nil;
	
	value = CFPreferencesCopyAppValue((CFStringRef)key, prefAppDomain);
	if(value && CFGetTypeID(value) == CFDateGetTypeID())
		ret = [[(NSDate *)value retain] autorelease];
	
	if(value)
		CFRelease(value);
	
	return ret;
}

- (void) setKey:(NSString *)key fromDate:(NSDate *)value
{
	CFPreferencesSetAppValue((CFStringRef)key, value, prefAppDomain);
	CFPreferencesSynchronize(prefAppDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

#pragma mark -
#pragma mark General
- (void) awakeFromNib
{
	// Saved for reference. Not everything is a BOOL.
	// CFPreferencesCopyAppValue();
	
	// Set displayed version information
	// ---------------------------------
	NSString *bundleVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary] 
							   valueForKey: @"CFBundleShortVersionString"];
	NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
								valueForKey:@"CFBundleVersion"];
	NSString *buildDate = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
							  valueForKey:@"TSBundleBuildDate"];
	
	[sidebarVersionText setStringValue: [NSString stringWithFormat:@"%@ (%@)", bundleVersion, buildVersion]];
	[sidebarDateText setStringValue: buildDate];
	
	[sidebarHeader setStringValue: [NSString stringWithFormat: @"TVShows %@", bundleVersion]];
	[sidebarHeaderShadow setStringValue: [sidebarHeader stringValue]];
	
	[aboutTabVersionText setStringValue: [NSString stringWithFormat: @"TVShows %@ (%@)", bundleVersion, buildVersion]];
	[aboutTabVersionTextShadow setStringValue: [aboutTabVersionText stringValue]];
	
	// Register download preferences
	// -----------------------------
	if ([self getBoolFromKey:@"isEnabled" withDefault:1]) {
		[isEnabledControl setSelectedSegment: 1];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									[[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									 pathForResource: @"TVShows-Beta-Large" ofType: @"icns"]] autorelease]];
		isEnabled = 1;
	} else {
		[isEnabledControl setSelectedSegment: 0];
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile:
									[[NSBundle bundleWithIdentifier: TVShowsAppDomain]
									 pathForResource: @"TVShows-Off-Large" ofType: @"icns"]] autorelease]];
		isEnabled = 0;
	}
	
	[autoOpenDownloadedFiles setState: [self getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]];
	[episodeCheckDelay selectItemAtIndex: [self getFloatFromKey:@"checkDelay" withDefault:0]];
		
	defaultQuality = [self getFloatFromKey:@"defaultQuality" withDefault:0];

	[defaultVideoQuality setState: 1
							atRow: defaultQuality
						   column: 0];
	
	// Register Growl notification preferences
	// ---------------------------------------
	[growlNotifyEpisode			setState: [self getBoolFromKey:@"GrowlOnNewEpisode" withDefault:1]];
	[growlNotifyApplication		setState: [self getBoolFromKey:@"GrowlOnAppUpdate" withDefault:1]];
	
	// Register application update preferences
	// ---------------------------------------
	if ([self getBoolFromKey:@"SUEnableAutomaticChecks" withDefault:1] == 0) {
		[checkForUpdates			setState: 0];
		[autoInstallNewUpdates		setEnabled: NO];
		[includeSystemInformation	setEnabled: NO];
		[downloadBetaVersions		setEnabled: NO];
	}
		[downloadBetaVersions		setState: [self getBoolFromKey:@"SUDownloadBetaVersions" withDefault:1]];
		[autoInstallNewUpdates		setState: [self getBoolFromKey:@"SUAutomaticallyUpdate" withDefault:1]];
		[includeSystemInformation	setState: [self getBoolFromKey:@"SUSendProfileInfo" withDefault:1]];
}

#pragma mark -
#pragma mark Download Preferences
- (IBAction) isEnabledControlDidChange:(id)sender
{
	NSString *appIconPath;
	
	if ([isEnabledControl selectedSegment]) {
		isEnabled = 1;
		[self setKey:@"isEnabled" fromBool: 1];
		
		appIconPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] pathForResource: @"TVShows-Beta-Large" ofType: @"icns"];
		
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile: appIconPath] autorelease]];
	} else {
		[self setKey:@"isEnabled" fromBool: 0];
		isEnabled = 0;
		
		appIconPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
					   pathForResource: @"TVShows-Off-Large" ofType: @"icns"];
		
		[TVShowsAppImage setImage: [[[NSImage alloc] initWithContentsOfFile: appIconPath] autorelease]];
	}
}

- (IBAction) episodeCheckDelayDidChange:(id)sender
{
	[self setKey:@"checkDelay" fromFloat: [episodeCheckDelay indexOfSelectedItem]];
}

- (IBAction) defaultVideoQualityDidChange:(id)sender
{
	[self setKey:@"defaultQuality" fromFloat: [defaultVideoQuality selectedRow]];
}

- (IBAction) autoOpenDownloadedFilesDidChange:(id)sender
{
	[self setKey:@"AutoOpenDownloadedFiles" fromBool: [autoOpenDownloadedFiles state]];
}

#pragma mark -
#pragma mark Growl Notification Preferences
- (IBAction) growlNotifyEpisodeDidChange:(id)sender
{
	[self setKey:@"GrowlOnNewEpisode" fromBool: [growlNotifyEpisode state]];
}

- (IBAction) growlNotifyApplicationDidChange:(id)sender
{
	[self setKey:@"GrowlOnAppUpdate" fromBool: [growlNotifyApplication state]];
}

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender
{
	if ([checkForUpdates state]) {
		[self setKey:@"SUEnableAutomaticChecks" fromBool: 1];
		
		[autoInstallNewUpdates setEnabled: YES];
		[includeSystemInformation setEnabled: YES];
		[downloadBetaVersions setEnabled: YES];
	} else {
		[self setKey:@"SUEnableAutomaticChecks" fromBool: 0];
		
		[autoInstallNewUpdates setEnabled: NO];
		[includeSystemInformation setEnabled: NO];
		[downloadBetaVersions setEnabled: NO];
	}
}

- (IBAction) autoInstallNewUpdatesDidChange:(id)sender
{
	[self setKey:@"SUAutomaticallyUpdate" fromBool: [autoInstallNewUpdates state]];
}

- (IBAction) downloadBetaVersionsDidChange:(id)sender
{
	if ([downloadBetaVersions state]) {
		[self setKey:@"SUDownloadBetaVersions" fromBool:1];
		[self setKey:@"SUFeedURL" fromString:TVShowsBetaAppcastURL];
	} else {
		[self setKey:@"SUDownloadBetaVersions" fromBool:0];
		[self setKey:@"SUFeedURL" fromString:TVShowsAppcastURL];
	}
}

- (IBAction) includeSystemInformationDidChange:(id)sender
{
	[self setKey:@"SUSendProfileInfo" fromBool: [includeSystemInformation state]];
}

@end
