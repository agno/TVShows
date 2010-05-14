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

#import "PresetShowsController.h"
#import "ShowListDelegate.h"


@implementation PresetShowsController

- (IBAction) displayPresetShowsWindow:(id)sender
{
	[self downloadShowList];
	
    [NSApp beginSheet: presetShowsWindow
	   modalForWindow: [[NSApplication sharedApplication] mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
    [NSApp runModalForWindow: presetShowsWindow];
	[NSApp endSheet: presetShowsWindow];
}

- (IBAction) closePresetShowsWindow:(id)sender
{	
    [NSApp stopModal];
    [presetShowsWindow orderOut: self];
}

- (void) downloadShowList {
	// There's probably a better way to do this.
	id delegateClass = [[[ShowListDelegate class] alloc] init];
	
	NSManagedObjectContext *context = [delegateClass managedObjectContext];
	NSManagedObject *show = [NSEntityDescription insertNewObjectForEntityForName: @"Show"
														  inManagedObjectContext: context];
	NSManagedObject *show2 = [NSEntityDescription insertNewObjectForEntityForName: @"Show"
														   inManagedObjectContext: context];
	
	[show setValue: @"Psych" forKey: @"displayName"];
	[show setValue: [NSNumber numberWithInt:111] forKey: @"showrssID"];
	
	[show2 setValue: @"Psych 2" forKey: @"displayName"];
	[show2 setValue: [NSNumber numberWithInt:112] forKey: @"showrssID"];
	
	[delegateClass saveAction];
	[delegateClass release];
}

@end
