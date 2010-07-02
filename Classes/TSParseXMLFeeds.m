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

+ (NSArray *) parseEpisodesFromFeed:(NSString *)url maxItems:(int)maxItems
{
	// Begin parsing the feed
	NSString *episodeTitle = @"", *episodeSeason = @"", *episodeNumber = @"", *episodeQuality = @"";
	NSError *error;
	NSMutableArray *episodeArray = [NSMutableArray array];
	NSData *feedData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
	FPFeed *parsedData = [FPParser parsedFeedWithData:feedData error:&error];
	
	int i=0;
	
	for (FPItem *item in parsedData.items) {
		if (i <= maxItems) {
			NSMutableDictionary *Episode = [[NSMutableDictionary alloc] init];
			NSArray *seasonAndEpisode = [TSRegexFun parseSeasonAndEpisode:[item title]];
			
			if ([seasonAndEpisode count] == 3) {
				episodeTitle = [TSRegexFun parseTitleFromString:[parsedData title]
												 withIdentifier:seasonAndEpisode
													   withType:@"episode"];
				episodeSeason = [TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:1]];
				episodeNumber = [TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:2]];
				
			} else if ([seasonAndEpisode count] == 4) {
				episodeTitle = [TSRegexFun parseTitleFromString:[parsedData title]
												 withIdentifier:seasonAndEpisode
													   withType:@"date"];
				episodeSeason = @"-";
				episodeNumber = @"-";
				
			}
			
			episodeQuality = [NSString stringWithFormat:@"%d",[TSRegexFun isEpisodeHD:[item title]]];
			
			[Episode setValue:episodeTitle			forKey:@"episodeName"];
			[Episode setValue:[item pubDate]		forKey:@"pubDate"];
			[Episode setValue:[[item link] href]	forKey:@"link"];
			[Episode setValue:episodeSeason			forKey:@"episodeSeason"];
			[Episode setValue:episodeNumber			forKey:@"episodeNumber"];
			[Episode setValue:episodeQuality		forKey:@"isHD"];
			
			[episodeArray addObject:Episode];
			
			[Episode release];
		}
		
		i++;
	}
	
	return episodeArray;
	[episodeArray release];
}

@end
