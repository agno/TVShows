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

#import "TSRegexFun.h"
#import "RegexKitLite.h"


@implementation TSRegexFun

+ (NSArray *) parseSeasonAndEpisode:(NSString *)title
{
	// These patterns are better but still need work before I trust them.
	// They need to ignore the space, not count it as another capture.
	// ([0-9]+)([[:space:]]*)x((\s)*)([0-9]+)
	// S([0-9]+)([[:space:]]*)E([0-9]+)
	
	// This method also needs to parse dates for shows like Colber Report
	// and The Daily Show.
	
	NSArray *matchedRegex, *returnThis = [NSArray array];
	NSArray *parseTypes = [NSArray arrayWithObjects:@"S([0-9]+)(?:[[:space:]]*)E([0-9]+)", 
													@"([0-9]+)(?:[[:space:]]*x[[:space:]]*)([0-9]+)",
													@"([0-9]{4})(?:[[:space:]]|[.])([0-9]{2})(?:[[:space:]]|[.])([0-9]{2})",
													@"([0-9]{2})(?:[[:space:]]|[.])([0-9]{2})(?:[[:space:]]|[.])([0-9]{4})",nil];
	for (NSString *regex in parseTypes) {
		matchedRegex = [title arrayOfCaptureComponentsMatchedByRegex:regex];
	
		if([matchedRegex count] != 0) {
			returnThis = [matchedRegex objectAtIndex:0];
		}
	}

	if (returnThis) {
		return returnThis;
	} else {
		return nil;
	}
}

+ (NSString *) removeLeadingZero:(NSString *)string
{
	return [string stringByReplacingOccurrencesOfRegex:@"^ *0+" withString:@""];
}

+ (NSString *) parseTitleFromString:(NSString *)title withIdentifier:(NSArray* )identifier withType:(NSString *)type
{
	// This is a temporary method until theTVDB support is added
	NSString *showTitle = [title stringByReplacingOccurrencesOfRegex:@"showRSS: feed for " withString:@""];
	
	if (type == @"episode") {
		
		// TVShow is in a Season x Episode format
		return [NSString stringWithFormat:@"%@ - %@x%@",showTitle,[self removeLeadingZero:[identifier objectAtIndex:1]],[self removeLeadingZero:[identifier objectAtIndex:2]]];				
		
	} else if (type == @"date") {
		
		if ([[identifier objectAtIndex:1] length] == 4) {
			
			// TVShows is in a YYYY MM DD format
			return [NSString stringWithFormat:@"%@ - %@/%@/%@",showTitle,
					[self removeLeadingZero:[identifier objectAtIndex:2]],
					[self removeLeadingZero:[identifier objectAtIndex:3]],
					[self removeLeadingZero:[identifier objectAtIndex:1]]];				
		} else {
			
			// TVShow is in a MM DD YYYY format
			return [NSString stringWithFormat:@"%@ - %@/%@/%@",showTitle,
					[self removeLeadingZero:[identifier objectAtIndex:1]],
					[self removeLeadingZero:[identifier objectAtIndex:2]],
					[self removeLeadingZero:[identifier objectAtIndex:3]]];	
		}
	}
}

@end
