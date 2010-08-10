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

#import "TheTVDB.h"
#import "RegexKitLite.h"


// This is a TVShow's specific API key. Do NOT reuse it.
// You can get your own at http://thetvdb.com/?tab=apiregister
#define API_KEY			@"E455EEEEFF5E6E2B"

@implementation TheTVDB

@synthesize mirrorURL, serverTime;

- init
{
	if((self = [super init])) {
		// Before we can do anything we need to download a list of mirrors.
		// TODO: Grab the list of mirrors. Currently only one server is listed, though.
		mirrorURL = [NSURL URLWithString:@"http://www.thetvdb.com"];
		
		// Get the current server time.
		// TODO: This isn't actually saved anywhere but will be used for knowing
		// whether we need to update the Cache or not.
		serverTime = [[[NSString alloc] initWithContentsOfURL: [NSURL URLWithString:@"http://www.thetvdb.com/api/Updates.php?type=none"]
													 encoding: NSUTF8StringEncoding
														error: NULL] autorelease];
	}
	
	return self;
}

- (NSString *) getValueForKey:(NSString *)key andShow:(NSString *)show
{
	// TODO: Save the information returned for each series into the Cache
	NSURL *seriesURL = [NSURL URLWithString:[[NSString stringWithString: @"http://www.thetvdb.com/api/GetSeries.php?seriesname="]
											 stringByAppendingString: [show stringByReplacingOccurrencesOfRegex:@" " withString:@"+"]]];
	NSString *seriesInfo = [[[NSString alloc] initWithContentsOfURL: seriesURL
														   encoding: NSUTF8StringEncoding
															  error: NULL] autorelease];
	
	// For now select the first show in the list that's returned
	// TODO: Get the TVDB ID from the Subscriptions file.
	NSString *seriesID = [[seriesInfo componentsMatchedByRegex:@"(?!<seriesid>)([[:digit:]]+)(?=</seriesid>)"] objectAtIndex:0];
	
	// Now let's grab complete info for the show using the API key.
	// Since we don't need the other list anymore we'll reuse variables.
	// TODO: Grab the correct localization.
	seriesURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.thetvdb.com/api/%@/series/%@/en.xml",API_KEY,seriesID]];
	seriesInfo = [[[NSString alloc] initWithContentsOfURL: seriesURL
												 encoding: NSUTF8StringEncoding
													error: NULL] autorelease];
	
	// Regex fun...
	key = [NSString stringWithFormat:@"<%@>(.+)</%@>",key,key];
	NSString *value = [[seriesInfo componentsMatchedByRegex:key] objectAtIndex:0];
	value = [value stringByReplacingOccurrencesOfRegex:@"<(.+?)>" withString:@""];
	
	return value;
}


- (void) dealloc
{
	[serverTime release];
	[mirrorURL release];
	[super dealloc];
}

@end
