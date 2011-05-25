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

@implementation TSParseXMLFeeds

+ (NSArray *) parseEpisodesFromFeed:(NSString *)url maxItems:(int)maxItems
{
    // Begin parsing the feed
    NSString *episodeTitle = @"", *lastEpisodeTitle = @"", *episodeSeason = @"", *episodeNumber = @"", *episodeQuality = @"", *lastEpisodeQuality = @"", *qualityString = @"";
    NSError *error;
    NSMutableArray *episodeArray = [NSMutableArray array];
    NSMutableArray *fakeEpisodeArray = [NSMutableArray array];
    NSData *feedData = [WebsiteFunctions downloadDataFrom:url];
    FPFeed *parsedData = [FPParser parsedFeedWithData:feedData error:&error];
    
    int i=0;
    BOOL feedHasHDEpisodes = NO;
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
                feedHasHDEpisodes = YES;
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
    
    // Fake HD episodes if ShowRSS does not list any
    if (!feedHasHDEpisodes && [TSUserDefaults getBoolFromKey:@"UseAdditionalSourcesHD" withDefault:YES]) {
        for (NSMutableDictionary *realEpisode in episodeArray) {
            // Ignore this episode if it is a daily show
            // The scene does not release late nights regularly
            if ([[realEpisode valueForKey:@"episodeSeason"] isEqualToString:@"-"]) {
                [fakeEpisodeArray addObject:realEpisode];
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
            
            [fakeEpisodeArray addObject:fakeEpisode];
            [fakeEpisodeArray addObject:realEpisode];
            
            [fakeEpisode release];
        }
        
        return fakeEpisodeArray;
        [episodeArray release];
        [fakeEpisodeArray release];
    } else {
        return episodeArray;
        [episodeArray release];
        [fakeEpisodeArray release];
    }
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
