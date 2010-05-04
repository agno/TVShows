/*
 *	This file is part of the TVShows 2 ("Phoenix") source code.
 *	http://github.com/mattprice/TVShows/tree/Phoenix
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

#import "SUUpdaterSubclass.h"

@implementation SUUpdaterSubclass

// This subclass is required in order for Sparkle to update bundles correctly.
// For more information see: http://wiki.github.com/andymatuschak/Sparkle/bundles

+ (id) sharedUpdater
{
    return [self updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (id) init
{
	return [self initForBundle:[NSBundle bundleForClass:[self class]]];
}


@end
