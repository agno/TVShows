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
		
		for (NSArray *show in results) {
			[self checkForNewEpisodes:show];
		}

	}
	
	[delegateClass release];
}

- (void) checkForNewEpisodes:(NSArray *)show
{
	NSArray *episodes = [TSParseXMLFeeds parseEpisodesFromFeed:[show valueForKey:@"url"] maxItems:10];
	
	for (NSArray *episode in episodes) {
		
		// This check is a little buggy at the moment, probably
		// because lastDownloaded isn't required or always set.
		
		if ([episode valueForKey:@"pubDate"] > [show valueForKey:@"lastDownloaded"]) {
			// TVLog(@"%@:%@",[episode valueForKey:@"link"], @"NEW");
		} else {
			// TVLog(@"%@:%@",[episode valueForKey:@"link"], @"OLD");
		}
		
	}
}

@end
