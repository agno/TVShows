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

#import "PresetTorrentsController.h"
#import "ShowListDelegate.h"
#import "RegexKitLite.h"
#import "WebsiteFunctions.h"

#pragma mark Constants
	#define ShowListHostname			@"showrss.karmorra.info"
	#define ShowListURL					@"http://showrss.karmorra.info/?cs=feeds"
	#define SelectTagsRegex				@"<select name=\"show\">(.+?)</select>"
	#define OptionTagsRegex				@"(?!<option value=\")([[:digit:]]+)(.*?)(?=</option>)"
	#define RSSIDRegex					@"([[:digit:]]+)(?![[:alnum:]]|[[:space:]])"
	#define DisplayNameRegex			@"\">(.+)"
	#define SeparatorBetweenNameAndID	@"\">"

#pragma mark -
#pragma mark Preset Torrents Controller
@implementation PresetTorrentsController

- (IBAction) displayPresetTorrentsWindow:(id)sender
{
	errorHasOccurred = NO;
	[self downloadTorrentShowList];
	
	if(errorHasOccurred == NO) {
		NSSortDescriptor *PTSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"sortName"
																		 ascending: YES 
																		  selector: @selector(caseInsensitiveCompare:)];
		[PTArrayController setSortDescriptors:[NSArray arrayWithObject:PTSortDescriptor]];
		[PTArrayController setSelectionIndex:0];
		
		[NSApp beginSheet: PTShowList
		   modalForWindow: [[NSApplication sharedApplication] mainWindow]
			modalDelegate: nil
		   didEndSelector: nil
			  contextInfo: nil];
		
		[NSApp endSheet: PTShowList];
		[NSApp runModalForWindow: PTShowList];
		
		[PTSortDescriptor release];
	}
}

- (void) displayErrorWindowWithMessage:(NSString *)message
{
	[PTErrorHeader setStringValue:@"An Error Has Occurred:"];
	[PTErrorText setStringValue:message];
	
    [NSApp beginSheet: PTErrorWindow
	   modalForWindow: [[NSApplication sharedApplication] mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	TVLog(@"%@",message);
	errorHasOccurred = YES;
	
	[NSApp endSheet: PTErrorWindow];
	[NSApp runModalForWindow: PTErrorWindow];
}

- (IBAction) closeErrorWindow:(id)sender
{	
    [NSApp stopModal];
    [PTErrorWindow orderOut:self];
}

- (IBAction) closePresetTorrentsWindow:(id)sender
{	
    [NSApp stopModal];
    [PTShowList orderOut:self];
}

- (void) downloadTorrentShowList {
	// There's probably a better way to do this:
	id delegateClass = [[[ShowListDelegate class] alloc] init];
	
	NSString *displayName, *sortName;
	int showrssID;
	
	// This rest of this method is extremely messy but it works for the time being
	// Feel free to improve it if you find a way
	
	// Download the page containing the show list
	NSURL *showListURL = [NSURL URLWithString:ShowListURL];
	NSString *showListContents = [[[NSString alloc] initWithContentsOfURL: showListURL
																 encoding: NSUTF8StringEncoding
																	error: NULL] autorelease];
	
	// Be sure to only search for shows between the <select> tags
	// Warning about never being read can be safely ignored
	NSArray *selectTags = [showListContents componentsMatchedByRegex:SelectTagsRegex];
	
	// Check to make sure the website is loading and that selectTags isn't NULL
	if ([WebsiteFunctions canConnectToHostname:ShowListHostname] && [selectTags count] == 0) {
		[self displayErrorWindowWithMessage:
		 [NSString stringWithFormat:@"The website '%@' seems to have loaded successfully but there were no shows found.", ShowListHostname]];
	}
	else if (![WebsiteFunctions canConnectToHostname:ShowListHostname]) {
		[self displayErrorWindowWithMessage:
		 [NSString stringWithFormat:@"Cannot connect to '%@'. Please try again later or check your internet connection.", ShowListHostname]];
	} else {
		showListContents = [selectTags objectAtIndex:0];
		
		// Reset the existing show list before continuing
		[delegateClass resetShowList];
		NSManagedObjectContext *context = [delegateClass managedObjectContext];
		
		// Extract the show name and number from the <option> tags
		NSArray *optionTags = [showListContents componentsMatchedByRegex:OptionTagsRegex];
		
		for(NSString *showInformation in optionTags) {
			NSManagedObject *newShow = [NSEntityDescription insertNewObjectForEntityForName: @"Show"
																	 inManagedObjectContext: context];
			
			// I hate having to search for each valute separately but I can't seem to figure out any other way
			displayName = [[[showInformation componentsMatchedByRegex:DisplayNameRegex] objectAtIndex:0]
						   stringByReplacingOccurrencesOfRegex:SeparatorBetweenNameAndID withString:@""];
			sortName = [displayName stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]" withString:@""];
			showrssID = [[[showInformation componentsMatchedByRegex:RSSIDRegex] objectAtIndex:0] intValue];

			[newShow setValue:displayName forKey:@"displayName"];
			[newShow setValue:displayName forKey:@"actualName"];
			[newShow setValue:sortName forKey:@"sortName"];
			[newShow setValue:[NSNumber numberWithInt:showrssID] forKey:@"showrssID"];
			[newShow setValue:[NSDate date] forKey:@"dateAdded"];
		} 
		
		[delegateClass saveAction];
	}
	
	[delegateClass release];
}

@end
