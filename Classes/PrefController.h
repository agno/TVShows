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

#import <Cocoa/Cocoa.h>


@interface PrefController : NSObject
{
	// Download Preferences

	// Growl Settings

	// Application Update Preferences
	IBOutlet NSButton *checkForUpdates;
	IBOutlet NSButton *autoInstallNewUpdates;
	IBOutlet NSButton *downloadBetaVersions;
	IBOutlet NSButton *includeSystemInformation;
}

#pragma mark -
#pragma mark General
- (id) init;
- (void) syncPreferences;

#pragma mark -
#pragma mark Application Update Preferences
- (IBAction) checkForUpdatesDidChange:(id)sender;
- (IBAction) autoInstallNewUpdatesDidChange:(id)sender;
- (IBAction) downloadBetaVersionsDidChange:(id)sender;
- (IBAction) includeSystemInformationDidChange:(id)sender;

@end
