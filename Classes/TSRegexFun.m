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
	// This needs to be improved, especially as things become more advanced
	NSArray *attemptOne = [title arrayOfCaptureComponentsMatchedByRegex:@"S([0-9]+)E([0-9]+)"];
	NSArray *attemptTwo = [title arrayOfCaptureComponentsMatchedByRegex:@"([0-9]+)x([0-9]+)"];
	
	if(attemptOne) {
		
		return [attemptOne objectAtIndex:0];

	} else if (attemptTwo) {
		
		return [attemptTwo objectAtIndex:0];
		
	} else {
		
		return nil;
	}

}

@end
