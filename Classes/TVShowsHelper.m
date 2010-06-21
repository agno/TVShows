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


@implementation TVShowsHelper

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
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
			[self checkForNewEpisodes:show];
		}

	}
	
	[delegateClass release];
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
		}
		
	}
}

@end
