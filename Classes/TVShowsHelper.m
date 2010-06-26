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

#import "TVShowsHelper.h"
#import "SubscriptionsDelegate.h"
#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "SUUpdaterSubclass.h"


@implementation TVShowsHelper

@synthesize didFindValidUpdate;

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
	// This should never happen, but let's make sure TVShows is enabled before continuing.
	if ([TSUserDefaults getBoolFromKey:@"isEnabled" withDefault:1]) {

		// TVShows is enabled, continuing...
		id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
		
		NSManagedObjectContext *context = [delegateClass managedObjectContext];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Subscription" inManagedObjectContext:context];
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:entity];
		
		NSError *error = nil;
		NSArray *results = [context executeFetchRequest:request error:&error];
		
		if (error != nil) {
			TVLog(@"%@",[error description]);
		} else {
			
			// No error occurred so check for new episodes
			for (NSArray *show in results) {
				
				// Only check for new episodes if we're supposed to
				if ([show valueForKey:@"isEnabled"]) {
					[self checkForNewEpisodes:show];
				} else {
					DLog(@"Downloading for the show %@ is disabled.", [show valueForKey:@"name"]);
				}
				
				// Update when the show was last downloaded. We do this for disabled
				// shows too so that if it's renabled the user isn't bombarded with
				// tens or hundreds of old episodes they probably don't want.
				[show setValue:[NSDate date] forKey:@"lastDownloaded"];
			}
			
		}
		
		[delegateClass saveAction];
		[delegateClass release];
		
	} else {
		// TVShows is not enabled.
		TVLog(@"The TVShowsHelper was run even though TVShows is not enabled. Quitting.");
	}

}

- (void) checkForNewEpisodes:(NSArray *)show
{
	NSDate *pubDate, *lastDownloaded;
	NSArray *episodes = [TSParseXMLFeeds parseEpisodesFromFeed:[show valueForKey:@"url"] maxItems:10];
	
	// For each episode that was parsed...
	for (NSArray *episode in episodes) {
		pubDate = [episode valueForKey:@"pubDate"];
		lastDownloaded = [show valueForKey:@"lastDownloaded"];

		// If the date we lastDownloaded episodes is before this torrent
		// was published then we should probably download the episode.
		if ([lastDownloaded compare:pubDate] == NSOrderedAscending) {
			
			// This currently only returns a Torrent file and should eventually regex
			// out the actual file extension of the item we're downloading.
			[self startDownloadingURL:[episode valueForKey:@"link"]
						 withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"] ];
		}
		
	}
}

#pragma mark -
#pragma mark Download Methods
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName
{
	NSData *fileContents = [NSData dataWithContentsOfURL: [NSURL URLWithString:url]];
	NSString *saveLocation = [[TSUserDefaults getStringFromKey:@"downloadFolder"] stringByAppendingPathComponent:fileName];
	
	[fileContents writeToFile:saveLocation atomically:YES];
	
	if (!fileContents) {
		TVLog(@"Unable to download file: %@",url);
	}
	
	// Check to see if the user wants to automatically open new downloads
	if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
		[[NSWorkspace sharedWorkspace] openFile:saveLocation];
	}

}


#pragma mark -
#pragma mark Sparkle Delegate Methods
- (void) updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update
{
	// We use this to help no whether or not the TVShowsHelper should close after
	// downloading new episodes or whether it should wait for Sparkle to finish
	// installing new updates.
	didFindValidUpdate = YES;
	DLog(@"Sparkle found a valid update.");
}

- (void) updaterDidNotFindUpdate:(SUUpdater *)update
{
	// We use this to help no whether or not the TVShowsHelper should close after
	// downloading new episodes or whether it should wait for Sparkle to finish
	// installing new updates.
	didFindValidUpdate = NO;
	DLog(@"Sparkle did not find a valid update.");
}

@end
