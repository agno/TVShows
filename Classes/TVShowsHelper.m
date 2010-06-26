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
				
			}
			
		}
		
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
		
		if ([lastDownloaded compare:pubDate] == NSOrderedAscending) {
			// The date we lastDownloaded episodes is before this torrent was
			// published. This means we should probably download the episode.
			DLog(@"%@",[episode valueForKey:@"link"]);
			[self startDownloadingURL:[episode valueForKey:@"link"]];
		}
		
	}
}

#pragma mark -
#pragma mark Download Methods
- (void) startDownloadingURL:(NSString *)url
{
	NSData *fileContents = [NSData dataWithContentsOfURL: [NSURL URLWithString:url]];
	[fileContents writeToFile:[[TSUserDefaults getStringFromKey:@"downloadFolder"]
							   stringByAppendingPathComponent:@"Test.torrent"] atomically:YES];
	
	if (!fileContents) {
		TVLog(@"Unable to download file: %@",url);
	}
	
	// Check to see if the user wants to automatically open new downloads
	if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
		// Open file here.
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
