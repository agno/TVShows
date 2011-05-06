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
#import "TorrentzParser.h"
#import "RegexKitLite.h"


@implementation TorrentzParser

- (id)init
{
    if((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

+ (NSString *) getAlternateTorrentForEpisode:(NSArray *)anEpisode ofShow:(NSArray *)aShow
{
    // Prepare the Torrentz search URL
    NSURL *torrentzURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://torrentz.eu/feed_any?q=%%22%@%%22+720p",
                                               [[anEpisode valueForKey:@"episodeName"]
                                                stringByReplacingOccurrencesOfString:@" " withString:@"+"]]];
    
    // Now let's grab the search results
    NSString *searchResults = [[[NSString alloc] initWithContentsOfURL:torrentzURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil] autorelease];
    
    // Regex fun...
    NSString *regex = @"<guid>[^<]+</guid>";
    NSArray *tempValues = [searchResults componentsMatchedByRegex:regex];
    
    // Check the first result
    if ([tempValues count] >= 1) {
        
        // Get the torrentz result page
        NSString *value = [tempValues objectAtIndex:0];
        torrentzURL = [NSURL URLWithString:[value stringByReplacingOccurrencesOfRegex:@"<[^<]+>" withString:@""]];
        
        // Get all possible torrent files
        tempValues = [TorrentzParser getAllTorrentsFromTorrenzURL:torrentzURL];
        
        // And choose one randomly
        if ([tempValues count] >= 1) {
            return [tempValues objectAtIndex:arc4random()%[tempValues count]];
        } else {
            return nil;
        }
        
    } else {
        return nil;
    }
}

+ (NSArray *) getAllTorrentsFromTorrenzURL:(NSURL*)aTorrentzURL
{
    // Now let's grab the meta search results
    NSString *searchResults = [[[NSString alloc] initWithContentsOfURL:aTorrentzURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil] autorelease];
    
    // Get all the external links (the trackers)
    NSString *regex = @"<a href=\"http[^\"]+";
    NSArray *tempValues = [searchResults componentsMatchedByRegex:regex];
    NSMutableArray *torrents = [NSMutableArray arrayWithCapacity:10];
    
    // And process one by one
    for (NSString *tracker in tempValues) {
        tracker = [tracker stringByReplacingOccurrencesOfRegex:@"<a href=\"" withString:@""];
        NSString *torrent = nil;
        
        // Process only known trackers
        if([tracker hasPrefix:@"http://www.vertor.com"]) {
            torrent = [TorrentzParser getTorrentFromTracker:[NSURL URLWithString:tracker]
                                            withLinkMatcher:@"http://www.vertor.com/([^\"]*)mod=download([^\"]*)id=([^\"]*)"
                                                  appending:@""];
        } else if([tracker hasPrefix:@"http://thepiratebay.org"]) {
            torrent = [TorrentzParser getTorrentFromTracker:[NSURL URLWithString:tracker]
                                            withLinkMatcher:@"http://torrents.thepiratebay.org([^\"]*)"
                                                  appending:@""];
        } else if([tracker hasPrefix:@"http://btjunkie.org"]) {
            torrent = [TorrentzParser getTorrentFromTracker:[NSURL URLWithString:tracker]
                                            withLinkMatcher:@"http://dl.btjunkie.org/torrent/([^\"]*)\\.torrent"
                                                  appending:@""];
        } else if([tracker hasPrefix:@"http://www.btmon.com"]) {
            torrent = [TorrentzParser getTorrentFromTracker:[NSURL URLWithString:tracker]
                                            withLinkMatcher:@"/([^\"]*)\\.torrent"
                                                  appending:@"http://www.btmon.com"];
        } else if([tracker hasPrefix:@"http://www.torrenthound.com"]) {
            torrent = [TorrentzParser getTorrentFromTracker:[NSURL URLWithString:tracker]
                                            withLinkMatcher:@"/torrent/([^\"]*)"
                                                  appending:@"http://www.torrenthound.com"];
        }
        
        if (torrent != nil) {
            [torrents addObject:torrent]; 
        }
    }
    
    return torrents;
}

+ (NSString *) getTorrentFromTracker:(NSURL*)theURL withLinkMatcher:(NSString*)theLinkMatcher appending:(NSString*)aString
{
    // Let's grab this URL content
    NSString *content = [[[NSString alloc] initWithContentsOfURL:theURL
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil] autorelease];
    
    // Get all the URLs
    NSArray *tempValues = [content componentsMatchedByRegex:theLinkMatcher];
    
    // Return the first result
    if ([tempValues count] >= 1) {
        return [aString stringByAppendingString:[tempValues objectAtIndex:0]];
    } else {
        return nil;
    }
}

- (void)dealloc
{
    [super dealloc];
}

@end
