/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/mattprice/TVShows/
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

#import "TVShowsHelper.h"
#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "SubscriptionsDelegate.h"
#import "SUUpdaterSubclass.h"
#import <Growl/GrowlApplicationBridge.h>


@implementation TVShowsHelper

@synthesize TVShowsHelperIcon;

- init
{
    if((self = [super init])) {
        NSMutableString *appPath = [NSMutableString stringWithString:[[NSBundle bundleForClass:[self class]] bundlePath] ];
        [appPath replaceOccurrencesOfString:@"TVShowsHelper.app"
                                 withString:@""
                                    options:0
                                      range:NSMakeRange(0, [appPath length])];
        
        TVShowsHelperIcon = [[NSData alloc] initWithContentsOfFile:
                             [appPath stringByAppendingPathComponent:@"TVShows-On-Large.icns"]];
    }
    
    return self;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    // This should never happen, but let's make sure TVShows is enabled before continuing.
    if ([TSUserDefaults getBoolFromKey:@"isEnabled" withDefault:1]) {
        
        // Set up Growl notifications
        [GrowlApplicationBridge setGrowlDelegate:@""];
        
        // TVShows is enabled, continuing...
        id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
        
        NSManagedObjectContext *context = [delegateClass managedObjectContext];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Subscription" inManagedObjectContext:context];
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:entity];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        
        if (error != nil) {
            LogError(@"%@",[error description]);
        } else {
            
            // No error occurred so check for new episodes
            LogInfo(@"Checking for new episodes.");
            for (NSArray *show in results) {
                
                // Don't download unless it's been at least 15minutes (or close to it)
//              NSNumber *lastDownloaded = [NSNumber numberWithDouble:[[show valueForKey:@"lastDownloaded"] timeIntervalSinceNow]];
//              NSNumber *timeLimit = [NSNumber numberWithInt:-15*60+10];
                
//              if ([lastDownloaded compare:timeLimit] == NSOrderedAscending) {
                    
                    // Only check for new episodes if it's enabled.
                    if ([show valueForKey:@"isEnabled"]) {
                        LogDebug(@"Checking for new episodes of %@.", [show valueForKey:@"name"]);
                        [self checkForNewEpisodes:show];
                    }
//              }
                
            }
            
        }
        
        // Now that everything is done, update the time our last check was made.
        [TSUserDefaults setKey:@"lastCheckedForEpisodes" fromDate:[NSDate date]];
        
        [delegateClass saveAction];
        [delegateClass release];
        
    } else {
        // TVShows is not enabled.
        LogWarning(@"The TVShowsHelper was run even though TVShows is not enabled. Quitting.");
    }

}

- (void) checkForNewEpisodes:(NSArray *)show
{
    NSDate *pubDate, *lastDownloaded;
    NSArray *episodes = [TSParseXMLFeeds parseEpisodesFromFeed:[show valueForKey:@"url"] maxItems:10];
    
    if ([episodes count] == 0) {
        LogError(@"Could not download/parse feed for %@ <%@>", [show valueForKey:@"name"], [show valueForKey:@"url"]);
    }
    
    BOOL feedHasHDEpisodes = [TSParseXMLFeeds feedHasHDEpisodes:episodes];
    BOOL feedHasSDEpisodes = [TSParseXMLFeeds feedHasSDEpisodes:episodes];

    // For each episode that was parsed...
    for (NSArray *episode in episodes) {
        pubDate = [episode valueForKey:@"pubDate"];
        lastDownloaded = [show valueForKey:@"lastDownloaded"];
        
        // If the date we lastDownloaded episodes is before this torrent
        // was published then we should probably download the episode.
        if ([lastDownloaded compare:pubDate] == NSOrderedAscending) {
            
            if ([[show valueForKey:@"quality"] intValue] == 1 &&
                [[episode valueForKey:@"isHD"] intValue] == 1 ||
                feedHasSDEpisodes == NO) {
                
                // Is HD and HD is enabled.
                [self startDownloadingURL:[episode valueForKey:@"link"]
                             withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"]
                                 showInfo:show ];
                
            } else if ([[show valueForKey:@"quality"] intValue] == 0 &&
                       [[episode valueForKey:@"isHD"] intValue] == 0 ||
                       feedHasHDEpisodes == NO) {
                
                // Is not HD and HD is not enabled.
                [self startDownloadingURL:[episode valueForKey:@"link"]
                             withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"]
                                 showInfo:show ];   
            }
        }
        
    }
}

#pragma mark -
#pragma mark Download Methods
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName showInfo:(NSArray *)show
{
    LogInfo(@"Attempting to download new episode: %@", fileName);
    NSData *fileContents = [NSData dataWithContentsOfURL: [NSURL URLWithString:url]];
    NSString *saveLocation = [[TSUserDefaults getStringFromKey:@"downloadFolder"] stringByAppendingPathComponent:fileName];
    
    [fileContents writeToFile:saveLocation atomically:YES];
    
    if (!fileContents) {
        LogError(@"Unable to download file: %@ <%@>",fileName, url);
    } else {
        // The file downloaded successfully, continuing...
        LogInfo(@"Episode downloaded successfully.");
        id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
        
        // Check to see if the user wants to automatically open new downloads
        if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
            [[NSWorkspace sharedWorkspace] openFile:saveLocation withApplication:nil andDeactivate:NO];
        }
        
        if([TSUserDefaults getBoolFromKey:@"GrowlOnNewEpisode" withDefault:1]) {
        // In the future this may display the show's poster instead of our app icon.
        [GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"%@", [show valueForKey:@"name"]]
                                    description:[NSString stringWithFormat:@"A new episode of %@ is being downloaded.", [show valueForKey:@"name"]]
                               notificationName:@"New Episode Downloaded"
                                       iconData:TVShowsHelperIcon
                                       priority:0
                                       isSticky:0
                                   clickContext:nil];
        }
        
        // Update when the show was last downloaded.
        [show setValue:[NSDate date] forKey:@"lastDownloaded"];
        
        [delegateClass saveAction];
        [delegateClass release];
    }
}


#pragma mark -
#pragma mark Sparkle Delegate Methods
- (void) updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update
{
    // We use this to help no whether or not the TVShowsHelper should close after
    // downloading new episodes or whether it should wait for Sparkle to finish
    // installing new updates.
    LogDebug(@"Sparkle found a valid update.");
    
    // If the user has automatic updates turned on, set a value saying that we installed
    // an update in the background and send a Growl notification.
    if ([TSUserDefaults getBoolFromKey:@"SUAutomaticallyUpdate" withDefault:YES]) {
        [TSUserDefaults setKey:@"AutomaticallyInstalledLastUpdate" fromBool:YES];
        
        if([TSUserDefaults getBoolFromKey:@"GrowlOnAppUpdate" withDefault:1]) {
            [GrowlApplicationBridge notifyWithTitle:@"TVShows Update Downloading"
                                        description:@"A new version of TVShows is being downloaded and installed."
                                   notificationName:@"TVShows Update Downloaded"
                                           iconData:TVShowsHelperIcon
                                           priority:0
                                           isSticky:0
                                       clickContext:nil];
        }
    } else if([TSUserDefaults getBoolFromKey:@"GrowlOnAppUpdate" withDefault:1]) {
        [GrowlApplicationBridge notifyWithTitle:@"TVShows Update Available"
                                    description:@"A new version of TVShows is available for download."
//                                  description:@"A new version of TVShows is available for download. Click here for information."
                               notificationName:@"TVShows Update Available"
                                       iconData:TVShowsHelperIcon
                                       priority:0
                                       isSticky:0
                                   clickContext:nil];
    }
}

- (void) updaterDidNotFindUpdate:(SUUpdater *)update
{
    // We use this to help no whether or not the TVShowsHelper should close after
    // downloading new episodes or whether it should wait for Sparkle to finish
    // installing new updates.
    LogDebug(@"Sparkle did not find valid update. Closing TVShows.");
    [NSApp terminate:nil];
}

- (void) dealloc
{
    [TVShowsHelperIcon release];
    [super dealloc];
}

@end
