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

#import "CustomRSSController.h"
#import "SubscriptionsDelegate.h"
#import "RegexKitLite.h"

@implementation CustomRSSController

- (IBAction) displayCustomRSSWindow:(id)sender
{
	[NSApp beginSheet: CustomRSSWindow
	   modalForWindow: [[NSApplication sharedApplication] mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];

	[NSApp endSheet: CustomRSSWindow];
	[NSApp runModalForWindow: CustomRSSWindow];
}

- (IBAction) closeCustomRSSWindow:(id)sender
{	
    [NSApp stopModal];
    [CustomRSSWindow orderOut:self];
}

@end
