/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/victorpimentel/TVShows/
 *
 *  TVShows is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with TVShows. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "AppInfoConstants.h"
#import "TSParseXMLFeeds.h"
#import "FeedParser.h"
#import "TSRegexFun.h"
#import "TSUserDefaults.h"
#import "TorrentzParser.h"
#import "WebsiteFunctions.h"
#import "RegexKitLite.h"

@implementation TSParseXMLFeeds

+ (NSArray *) parseEpisodesFromFeed:(NSString *)url maxItems:(int)maxItems
{
    // Begin parsing the feed
    NSString *episodeTitle = @"", *lastEpisodeTitle = @"", *episodeSeason = @"", *episodeNumber = @"", *episodeQuality = @"", *lastEpisodeQuality = @"", *qualityString = @"";
    NSError *error;
    NSMutableArray *episodeArray = [NSMutableArray array];
    NSData *feedData = [WebsiteFunctions downloadDataFrom:url];
    FPFeed *parsedData = [FPParser parsedFeedWithData:feedData error:&error];
    
    int i=0;
    lastEpisodeTitle = lastEpisodeQuality = @"";
    
    for (FPItem *item in parsedData.items) {
        if (i <= maxItems) {
            NSMutableDictionary *Episode = [[NSMutableDictionary alloc] init];
            NSArray *seasonAndEpisode = [TSRegexFun parseSeasonAndEpisode:[item title]];
            
            if ([seasonAndEpisode count] == 3) {
                episodeTitle = [TSRegexFun parseTitleFromString:[item title]
                                                 withIdentifier:seasonAndEpisode
                                                       withType:@"episode"];
                episodeSeason = [TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:1]];
                episodeNumber = [TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:2]];
                
            } else if ([seasonAndEpisode count] == 4) {
                episodeTitle = [TSRegexFun parseTitleFromString:[item title]
                                                 withIdentifier:seasonAndEpisode
                                                       withType:@"date"];
                episodeSeason = @"-";
                episodeNumber = @"-";
                
            }
            
            episodeQuality = [NSString stringWithFormat:@"%d",[TSRegexFun isEpisodeHD:[item title]]];
            
            if ([episodeQuality intValue] == 1) {
                qualityString = @"✓";
            } else {
                // qualityString = @"✗";
                qualityString = @"";
            }
            
            [Episode setValue:episodeTitle          forKey:@"episodeName"];
            [Episode setValue:[item pubDate]        forKey:@"pubDate"];
            [Episode setValue:[[item link] href]    forKey:@"link"];
            [Episode setValue:episodeSeason         forKey:@"episodeSeason"];
            [Episode setValue:episodeNumber         forKey:@"episodeNumber"];
            [Episode setValue:episodeQuality        forKey:@"isHD"];
            [Episode setValue:qualityString         forKey:@"qualityString"];
            
            // Check if we already add this same episode
            if (![episodeTitle isEqualToString:lastEpisodeTitle] ||
                ![episodeQuality isEqualToString:lastEpisodeQuality]) {
                [episodeArray addObject:Episode];
                lastEpisodeTitle = episodeTitle;
                lastEpisodeQuality = episodeQuality;
            }
            
            [Episode release];
        }
        
        i++;
    }
    
    return episodeArray;
    [episodeArray release];
}

+ (BOOL) getEpisode:(NSMutableDictionary *)episode fromArray:(NSArray *)episodes
{
    for (NSMutableDictionary *ep in episodes) {
        if ([[[[[[[episode valueForKey:@"episodeName"] lowercaseString]
                 stringByReplacingOccurrencesOfRegex:@"\\s+us\\s+" withString:@" "]
                stringByReplacingOccurrencesOfRegex:@"\\s+\\(.*\\)\\s+" withString:@" "]
               stringByReplacingOccurrencesOfRegex:@"\\s+and\\s+" withString:@" "]
              stringByReplacingOccurrencesOfRegex:@"\\s+&\\s+" withString:@" "]
             isEqualToString:
             [[[[[[ep valueForKey:@"episodeName"] lowercaseString]
                 stringByReplacingOccurrencesOfRegex:@"\\s+us\\s+" withString:@" "]
                stringByReplacingOccurrencesOfRegex:@"\\s+\\(.*\\)\\s+" withString:@" "]
               stringByReplacingOccurrencesOfRegex:@"\\s+and\\s+" withString:@" "]
              stringByReplacingOccurrencesOfRegex:@"\\s+&\\s+" withString:@" "]] &&
            [[episode valueForKey:@"isHD"] boolValue] == [[ep valueForKey:@"isHD"] boolValue]) {
            return YES;
        }
        if ([[episode valueForKey:@"episodeName"] isEqualToString:@""]) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray *) parseEpisodesFromFeeds:(NSArray *)urls maxItems:(int)maxItems
{
    NSMutableArray *episodes = [[[NSMutableArray alloc] init] autorelease];
    
    // Parse and store all results
    for (NSString *url in urls) {
        for (NSMutableDictionary *episode in [self parseEpisodesFromFeed:url maxItems:maxItems]) {
            // For each episode add it to the results if the episode is not already in the results
            if (![self getEpisode:episode fromArray:episodes]) {
                [episodes addObject:episode];
            }
        }
    }
    
    // Fake HD episodes!
    if ([TSUserDefaults getBoolFromKey:@"UseAdditionalSourcesHD" withDefault:YES]) {
        
        // We are going to populate an array with both fake and real episodes
        NSMutableArray *fakeEpisodes = [[[NSMutableArray alloc] init] autorelease];
        
        for (NSMutableDictionary *realEpisode in episodes) {
            // Add the real episode to the temporal array
            [fakeEpisodes addObject:realEpisode];
            
            // Ignore this episode if it is a daily show
            // The scene does not release late nights regularly
            // Also check that the show is not in the array
            if ([[realEpisode valueForKey:@"episodeSeason"] isEqualToString:@"-"]) {
                continue;
            }
            
            NSMutableDictionary *fakeEpisode = [[NSMutableDictionary alloc] init];
            
            [fakeEpisode setValue:[realEpisode valueForKey:@"episodeName"]     forKey:@"episodeName"];
            [fakeEpisode setValue:[realEpisode valueForKey:@"pubDate"]         forKey:@"pubDate"];
            [fakeEpisode setValue:[realEpisode valueForKey:@"episodeName"]     forKey:@"link"];
            [fakeEpisode setValue:[realEpisode valueForKey:@"episodeSeason"]   forKey:@"episodeSeason"];
            [fakeEpisode setValue:[realEpisode valueForKey:@"episodeNumber"]   forKey:@"episodeNumber"];
            [fakeEpisode setValue:[NSString stringWithFormat:@"%d", YES]       forKey:@"isHD"];
            [fakeEpisode setValue:@"✓"                                         forKey:@"qualityString"];
            
            // Check if the episode is already in HD
            if (![self getEpisode:fakeEpisode fromArray:episodes]) {
                [fakeEpisodes addObject:fakeEpisode];
            }
            
            [fakeEpisode release];
        }
        
        // Release the old copy and update it with the one with all episodes
        episodes = fakeEpisodes;        
    }
    
    // Sort results by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
    [episodes sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    return episodes;
}

+ (BOOL) feedHasHDEpisodes:(NSArray *)parsedFeed
{
    for (NSArray *item in parsedFeed) {
        if ([[item valueForKey:@"isHD"] boolValue]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL) feedHasSDEpisodes:(NSArray *)parsedFeed
{
    for (NSArray *item in parsedFeed) {
        if (![[item valueForKey:@"isHD"] boolValue]) {
            return YES;
        }
    }
    
    return NO;
}

@end
