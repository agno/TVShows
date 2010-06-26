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

#import <Cocoa/Cocoa.h>
#import <Sparkle/SUUpdater.h>


@interface TVShowsHelper : NSObject {

}

@property (nonatomic) Boolean didFindValidUpdate;

- (void) applicationDidFinishLaunching:(NSNotification *)notification;
- (void) checkForNewEpisodes:(NSArray *)show;

#pragma mark -
#pragma mark Download Methods
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName;

#pragma mark -
#pragma mark Sparkle Delegate Methods
- (void) updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update;
- (void) updaterDidNotFindUpdate:(SUUpdater *)update;

@end
