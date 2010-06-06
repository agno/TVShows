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

#import "TSParseXMLFeeds.h"
#import "FeedParser.h"
#import "TSRegexFun.h"


@implementation TSParseXMLFeeds

+ (NSArray *) copyEpisodesFromFeed:(NSString *)url maxItems:(int)maxItems
{
	// Begin parsing the feed
	NSError *error;
	NSMutableArray *episodeArray = [[NSMutableArray alloc] init];
	NSData *feedData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
	FPFeed *parsedData = [FPParser parsedFeedWithData:feedData error:&error];
	
	int i=0;
	
	for (FPItem *item in parsedData.items) {
		if (i <= maxItems) {
			NSMutableDictionary *Episode = [[NSMutableDictionary alloc] init];
			NSArray *seasonAndEpisode = [TSRegexFun parseSeasonAndEpisode:[item title]];
			DLog(@"%@",seasonAndEpisode);
			
			[Episode setValue:[item title] forKey:@"episodeName"];
			[Episode setValue:[item pubDate] forKey:@"pubDate"];
			[Episode setValue:[seasonAndEpisode objectAtIndex:1] forKey:@"episodeSeason"];
			[Episode setValue:[seasonAndEpisode objectAtIndex:2] forKey:@"episodeNumber"];
			
			[episodeArray addObject:Episode];
			
			[Episode release];
		}
		
		i++;
	}
	
	return episodeArray;
	[episodeArray release];
}

@end
