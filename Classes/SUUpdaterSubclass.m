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

#import "SUUpdaterSubclass.h"
#import "AppInfoConstants.h"

@implementation SUUpdaterSubclass

// This subclass is required in order for Sparkle to update bundles correctly.
// For more information see: http://wiki.github.com/andymatuschak/Sparkle/bundles

+ (id) sharedUpdater
{
	// Get the path of the TVShowsHelper
	NSString *appPath = [[NSBundle bundleForClass:[self class]] bundlePath];
	
	// Get the path of the bundle TVShowsHelper is currently within.
	NSMutableString *prefPanePath = [NSMutableString stringWithString:appPath];
	[prefPanePath replaceOccurrencesOfString:@"/Content/Resources/TVShowsHelper.app"
								  withString:@""
									 options:0
									   range:NSMakeRange(0, [prefPanePath length])];
	
	// If we're running in DEBUG mode then TVShowsHelper won't be in a bundle
	// so we should just return a static path to the  prefPane instead.
	#if DEBUG
		prefPanePath = [NSMutableString stringWithString:@"~/Library/PreferencePanes/TVShows.prefPane"];
	#endif
	
    return [self updaterForBundle:[NSBundle bundleWithPath:prefPanePath]];
}

- (id) init
{
	// Get the path of the TVShowsHelper
	NSString *appPath = [[NSBundle bundleForClass:[self class]] bundlePath];
	
	// Get the path of the bundle TVShowsHelper is currently within.
	NSMutableString *prefPanePath = [NSMutableString stringWithString:appPath];
	[prefPanePath replaceOccurrencesOfString:@"/Content/Resources/TVShowsHelper.app"
								  withString:@""
									 options:0
									   range:NSMakeRange(0, [prefPanePath length])];
	
	// If we're running in DEBUG mode then TVShowsHelper won't be in a bundle
	// so we should just return a static path to the  prefPane instead.
	#if DEBUG
		prefPanePath = [NSMutableString stringWithString:@"~/Library/PreferencePanes/TVShows.prefPane"];
	#endif
	
	return [self initForBundle:[NSBundle bundleWithPath:prefPanePath]];
}

@end
