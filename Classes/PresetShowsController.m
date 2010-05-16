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
#import "RegexKitLite.h"


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
	// There's probably a better way to do this:
	id delegateClass = [[[ShowListDelegate class] alloc] init];
	
	NSManagedObjectContext *context = [delegateClass managedObjectContext];
	NSString *displayName;
	int showrssID;
	
	// This rest of this method is extremely messy but it works for the time being
	// Feel free to improve it if you find any ways
	
	// Download the show list from showRSS
	NSURL *showRSSList = [NSURL URLWithString:@"http://showrss.karmorra.info/?cs=feeds"];
	NSString *searchString = [[[NSString alloc] initWithContentsOfURL:showRSSList
															 encoding:NSUTF8StringEncoding
																error:NULL] autorelease];

	// Only search for shows between the <select> tag
	NSArray *matchArray = [searchString componentsMatchedByRegex:@"<select name=\"show\">(.+?)</select>"];
	searchString = [matchArray objectAtIndex:0];
	
	// Extract the show name and number from the <option> tag
	NSArray *optionTags = [searchString componentsMatchedByRegex:@"(?!<option value=\")([[:digit:]]+)(.*?)(?=</option>)"];
	
	for(NSString *matchedString in optionTags) {
		NSManagedObject *show = [NSEntityDescription insertNewObjectForEntityForName: @"Show"
															  inManagedObjectContext: context];
		
		// I hate having to search for each valute separately but I can't seem to figure out any other way
		displayName = [[[matchedString componentsMatchedByRegex:@"\">(.+)"] objectAtIndex:0]
					   stringByReplacingOccurrencesOfRegex:@"\">" withString:@""];
		showrssID = [[[matchedString componentsMatchedByRegex:@"([[:digit:]]+)(?![[:alnum:]]|[[:space:]])"] objectAtIndex:0]
					 intValue];
		
		[show setValue:displayName forKey: @"displayName"];
		[show setValue:[NSNumber numberWithInt:showrssID] forKey: @"showrssID"];
	} 

	[delegateClass saveAction];
	[delegateClass release];
}

@end
