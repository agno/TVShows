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

#import "NSApplication+Relaunch.h"
#import "AppInfoConstants.h"

@implementation NSApplication (Relaunch)

// Thanks to Matt Patenaude and his blog post on how to relaunch an application.
// Slightly modified to work with a Preference Pane.
// http://iloveco.de/relaunching-your-application/

- (void) relaunch:(id)sender
{
	NSString *daemonPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] pathForResource:@"relaunch" ofType:nil];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *prefPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] bundlePath];
	
	[NSTask launchedTaskWithLaunchPath:daemonPath
							 arguments:[NSArray arrayWithObjects: bundlePath, prefPath, 
										[NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]], nil] ];
	[self terminate:sender];
}

@end