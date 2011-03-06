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

#import "ValueTransformers.h"
#import "TheTVDB.h"


@implementation ShowPosterValueTransformer

+ (Class) transformedValueClass;
{
	return [NSImage class];
}

+ (BOOL) allowsReverseTransformation
{
    return NO;
}

- (id) transformedValue:(id)value
{
	// For some reason, we sometimes receive nil values.
	// Those will crash the program if we aren't careful.
	if (value == nil) return nil;
	
	NSImage *showPoster = [[TheTVDB class] getPosterForShow:value withHeight:96 withWidth:66];
	return showPoster;
}

@end
