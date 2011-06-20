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
#import "TVShowsHelper.h"
#import "PreferencesController.h"
#import "TorrentzParser.h"
#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "SUUpdaterSubclass.h"
#import "WebsiteFunctions.h"
#import "RegexKitLite.h"
#import "TSRegexFun.h"
#import "TheTVDB.h"

@implementation TVShowsHelper

@synthesize checkerLoop, TVShowsHelperIcon, subscriptionsDelegate, presetShowsDelegate;

- init
{
    if((self = [super init])) {
        checkerThread = nil;
        checkerLoop = nil;
        manually = NO;
        
        NSMutableString *appPath = [NSMutableString stringWithString:[[NSBundle bundleForClass:[self class]] bundlePath] ];
        [appPath replaceOccurrencesOfString:@"TVShowsHelper.app"
                                 withString:@""
                                    options:0
                                      range:NSMakeRange(0, [appPath length])];
        
        TVShowsHelperIcon = [[NSData alloc] initWithContentsOfFile:
                             [appPath stringByAppendingPathComponent:@"TVShows-On-Large.icns"]];
        
        misoBackend = [[Miso alloc] init];
        
        [misoBackend setDelegate:self];
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(authenticatedOnMiso:)
                                                                name:@"TSMisoAuthenticated"
                                                              object:nil];
    }
    
    return self;
}

- (void) awakeFromNib
{
    // This should never happen, but let's make sure TVShows is enabled before continuing.
    if ([TSUserDefaults getBoolFromKey:@"isEnabled" withDefault:YES]) {
        
        // Set up Growl notifications
        [GrowlApplicationBridge setGrowlDelegate:self];
        
        // Show the menu if the user wants
        if([TSUserDefaults getBoolFromKey:@"ShowMenuBarIcon" withDefault:YES]) {
            [self activateStatusMenu];
        }
        
        // Check first if we have to add or delete subscriptions because of Miso
        if ([TSUserDefaults getBoolFromKey:@"MisoEnabled" withDefault:NO]) {
            // Try to login in Miso
            manually = NO;
            [misoBackend authorizeWithKey:MISO_API_KEY secret:MISO_API_SECRET];
        } else {
            [self checkNow:nil];
        }
        
    } else {
        // TVShows is not enabled.
        LogWarning(@"The TVShowsHelper was run even though TVShows is not enabled. Quitting.");
        [self quitHelper:nil];
    }
}

- (NSObject *)getShow:(NSString *)showId fromArray:(NSArray *)array
{
    for (NSObject *show in array) {
        if ([[[show valueForKey:@"tvdbID"] description] isEqualToString:showId]) {
            return show;
        }
    }
    
    return nil;
}

- (NSObject *)getShow:(NSString *)showId fromDictionary:(NSDictionary *)dict
{
    for (NSObject *show in dict) {
        if ([[[[show valueForKey:@"media"] valueForKey:@"tvdb_id"] description] isEqualToString:showId]) {
            return show;
        }
    }
    
    return nil;
}

- (void)unsubscribeFromUnfollowedShows:(NSDictionary *)followedShows
{
    // Fetch subscriptions
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Subscription"
                                              inManagedObjectContext:[subscriptionsDelegate managedObjectContext]];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSArray *subscriptions = [[subscriptionsDelegate managedObjectContext] executeFetchRequest:request error:&error];
    
    // Delete from our subscriptions unfollowed shows on Miso
    for (NSManagedObject *show in subscriptions) {
        // Get the TVDB id
        NSString *showID = [[show valueForKey:@"tvdbID"] description];
        NSString *seriesName = [show valueForKey:@"name"];
        
        // Check if the show is been followed and if it is a custom RSS (if it has some filters)
        if (![show valueForKey:@"filters"] &&
            ![self getShow:showID fromDictionary:followedShows]) {
            
            // Some shows do not have TVDB ids yet; search for it on Miso to see if they are favorited
            NSDictionary *results = [misoBackend showWithQuery:seriesName];
            
            // Let's see if the show has id
            if (![self getShow:showID fromDictionary:results]) {
                
                NSObject *newShow = nil;
                
                // Just pick the first show (too late, I cannot even think anymore)
                for (NSObject *result in results) {
                    newShow = result;
                    break;
                }
                
                // If the name is not equal... do not remove
                if (newShow && ![[[newShow valueForKey:@"media"] valueForKey:@"title"] isEqualToString:seriesName]) {
                    continue;
                }
                
                // Or if this show is favorited... do it
                if (newShow && [[[newShow valueForKey:@"media"] valueForKey:@"currently_favorited"] boolValue]) {
                    continue;
                }
            }
            
            LogInfo(@"Unsubscribe show %@ because of Miso.", seriesName);
            NSManagedObject *selectedShow = [[subscriptionsDelegate managedObjectContext] objectWithID:[show objectID]];
            
            [[subscriptionsDelegate managedObjectContext] deleteObject:selectedShow];
            
            [[subscriptionsDelegate managedObjectContext] processPendingChanges];
            [subscriptionsDelegate saveAction];
        }
    }
}

- (void)subscribeToFollowedShows:(NSDictionary *)followedShows
{
    // Fetch subscriptions
    NSEntityDescription *entitySubscriptions = [NSEntityDescription entityForName:@"Subscription"
                                                           inManagedObjectContext:[subscriptionsDelegate managedObjectContext]];
    NSFetchRequest *requestSubscriptions = [[[NSFetchRequest alloc] init] autorelease];
    [requestSubscriptions setEntity:entitySubscriptions];
    
    NSError *error = nil;
    NSArray *subscriptions = [[subscriptionsDelegate managedObjectContext]
                              executeFetchRequest:requestSubscriptions error:&error];
    
    // Fetch subscriptions
    NSEntityDescription *entityPresets = [NSEntityDescription entityForName:@"Show"
                                                     inManagedObjectContext:[presetShowsDelegate managedObjectContext]];
    NSFetchRequest *requestPresets = [[[NSFetchRequest alloc] init] autorelease];
    [requestPresets setEntity:entityPresets];
    
    NSArray *presets = [[presetShowsDelegate managedObjectContext]
                        executeFetchRequest:requestPresets error:&error];
    
    // The other way around, update our subscriptions with the followed shows on Miso
    for (NSDictionary *show in followedShows) {
        // Get the precious data for that show
        NSString *showID = [[[show valueForKey:@"media"] valueForKey:@"tvdb_id"] description];
        NSString *seriesName = [[show valueForKey:@"media"] valueForKey:@"title"];
        
        // Let's check that the show is in the preset show list
        NSObject *selectedShow = [self getShow:showID fromArray:presets];
        
        // If the user is not subscribed to this show and the show is still airing, add to the subscriptions
        if (selectedShow && ![self getShow:showID fromArray:subscriptions] &&
            ![[TheTVDB getShowStatus:seriesName withShowID:showID] isEqualToString:@"Ended"]) {
            
            LogInfo(@"Adding show %@ from Miso.", seriesName);
            
            NSManagedObject *newSubscription = [NSEntityDescription insertNewObjectForEntityForName:@"Subscription"
                                                                             inManagedObjectContext:[subscriptionsDelegate managedObjectContext]];
            
            // Set the information about the new show
            [newSubscription setValue:[selectedShow valueForKey:@"displayName"] forKey:@"name"];
            [newSubscription setValue:[selectedShow valueForKey:@"sortName"] forKey:@"sortName"];
            [newSubscription setValue:[selectedShow valueForKey:@"tvdbID"] forKey:@"tvdbID"];
            [newSubscription setValue:[selectedShow valueForKey:@"name"] forKey:@"url"];
            [newSubscription setValue:[NSDate date] forKey:@"lastDownloaded"];
            [newSubscription setValue:[NSNumber numberWithBool:[TSUserDefaults getBoolFromKey:@"AutoSelectHDVersion" withDefault:YES]]
                               forKey:@"quality"];
            [newSubscription setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
            
            [[subscriptionsDelegate managedObjectContext] processPendingChanges];
            [subscriptionsDelegate saveAction];
        }
    }
}

- (void)syncShows
{
    // Check the followed shows and process them
    NSDictionary *followedShows = [misoBackend favoritedShows];
    
    if (followedShows) {
        presetShowsDelegate = [[PresetShowsDelegate alloc] init];
        [self unsubscribeFromUnfollowedShows:followedShows];
        [self subscribeToFollowedShows:followedShows];
        [presetShowsDelegate release];
    }
}

- (BOOL)hasCheckInForShow:(NSObject *)show andEpisode:(NSObject *)episode
{
    // If the user did not enable check-ins, obviously we cannot know if there is a check-in
    if (![TSUserDefaults getBoolFromKey:@"MisoEnabled" withDefault:NO] ||
        ![TSUserDefaults getBoolFromKey:@"MisoCheckInEnabled" withDefault:NO]) {
        return NO;
    }
    
    // Only check check-ins for normal shows
    if ([[episode valueForKey:@"episodeSeason"] isEqualToString:@"-"] ||
        [[episode valueForKey:@"episodeNumber"] isEqualToString:@"-"] ||
        [show valueForKey:@"filters"]) {
        return NO;
    }
    
    // Retrieve the user id
    NSDictionary *userDetails = [misoBackend userDetails];
    if (!userDetails) {
        return NO;
    }
    
    // Search for it on Miso
    NSDictionary *results = [misoBackend showWithQuery:[show valueForKey:@"name"]];
    NSObject *showData = nil;
    
    // Just pick the first show (too late, I cannot even think anymore)
    for (NSObject *result in results) {
        showData = result;
        break;
    }
    if (!showData) {
        return NO;
    }
    
    // We have all the data, so search for checkins of that show!
    NSDictionary *checkins = [misoBackend checkingsForUser:[[[userDetails valueForKey:@"user"] valueForKey:@"id"] description]
                                                   andShow:[[[showData valueForKey:@"media"] valueForKey:@"id"] description]];
    
    // So check if the checkin was done
    for (NSObject *checkin in checkins) {
        if ([[[[checkin valueForKey:@"checkin"] valueForKey:@"episode_season_num"] description]
             isEqualToString:[episode valueForKey:@"episodeSeason"]] &&
            [[[[checkin valueForKey:@"checkin"] valueForKey:@"episode_num"] description]
             isEqualToString:[episode valueForKey:@"episodeNumber"]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)authenticationEnded:(BOOL)authenticated
{
    // If the shows were updated in the prefpane, we don't need to update them again
    if (!manually) {
        // Now we can check the new episodes!
        [self checkNow:nil];
    }
}

- (void)authenticatedOnMiso:(NSNotification *)inNotification
{
    // The user just login with the prefpane, so we have the credentials now!
    manually = YES;
    [misoBackend authorizeWithKey:MISO_API_KEY secret:MISO_API_SECRET];
}

- (void) runLoop
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop* threadLoop = [NSRunLoop currentRunLoop];
    
    NSInteger delay;
    NSTimeInterval seconds;
    delay = [TSUserDefaults getFloatFromKey:@"checkDelay" withDefault:1];
    
    switch (delay) {
        case 0:
            // 30 minutes
            seconds = 30*60;
            break;
        case 1:
            // 1 hour
            seconds = 1*60*60;
            break;
        case 2:
            // 3 hours
            seconds = 3*60*60;
            break;
        case 3:
            // 6 hours
            seconds = 6*60*60;
            break;
        case 4:
            // 12 hours
            seconds = 12*60*60;
            break;
        case 5:
            // 1 day
            seconds = 24*60*60;
            break;
        case 6:
            // 1 day, old value, needs to be reverted back to 5
            seconds = 24*60*60;
            [TSUserDefaults setKey:@"checkDelay" fromFloat:5];
            break;
        default:
            // 15 minutes
            seconds = 1*60;
    }
    
    checkerLoop = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1]
                                        interval:seconds
                                          target:self
                                        selector:@selector(checkAllShows)
                                        userInfo:nil
                                         repeats:YES];
    
    [threadLoop addTimer:checkerLoop forMode:NSDefaultRunLoopMode];
    [threadLoop run];
    [pool drain];
}

- (IBAction) checkNow:(id)sender
{
    if (checkerLoop != nil) {
        [checkerLoop performSelector:@selector(invalidate) onThread:checkerThread withObject:nil waitUntilDone:YES];
        checkerLoop = nil;
        [checkerThread release];
        checkerThread = nil;
        if (sender != nil) {
            // Notify the user to give him some feedback
            [GrowlApplicationBridge notifyWithTitle:@"TVShows"
                                        description:TSLocalizeString(@"Checking for new episodes...")
                                   notificationName:@"Checking For New Episodes"
                                           iconData:TVShowsHelperIcon
                                           priority:0
                                           isSticky:0
                                       clickContext:nil];
        }
    }
    
    // First disable the menubar option
    [checkShowsItem setAction:nil];
    [checkShowsItem setTitle:TSLocalizeString(@"Checking now, please wait...")];
    
    // And start the thread
    checkerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLoop) object:nil];
    [checkerThread start];
}

- (void) checkAllShows
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Reload the delegate
    subscriptionsDelegate = [[SubscriptionsDelegate alloc] init];
    
    // Sync shows with Miso
    if ([TSUserDefaults getBoolFromKey:@"MisoEnabled" withDefault:NO] &&
        [TSUserDefaults getBoolFromKey:@"MisoSyncEnabled" withDefault:YES]) {
        [self syncShows];
        
        // Warn the pref pane
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"TSUpdatedShows" object:nil];
    }
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Subscription"
                                              inManagedObjectContext:[subscriptionsDelegate managedObjectContext]];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSArray *results = [[subscriptionsDelegate managedObjectContext] executeFetchRequest:request error:&error];
    
    if (error != nil) {
        LogError(@"%@",[error description]);
    } else {
        // No error occurred so check for new episodes
        LogInfo(@"Checking for new episodes.");
        for (NSArray *show in results) {
            // Only check for new episodes if it's enabled.
            if ([[show valueForKey:@"isEnabled"] boolValue]) {
                [self checkForNewEpisodes:show];
            }
        }
    }
    
    // And free the delegate
    [subscriptionsDelegate release];
    
    // Now that everything is done, update the time our last check was made.
    [TSUserDefaults setKey:@"lastCheckedForEpisodes" fromDate:[NSDate date]];
    
    // And update the menu to reflect the date
    [self performSelectorOnMainThread:@selector(updateLastCheckedItem) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void) checkForNewEpisodes:(NSArray *)show
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    LogDebug(@"Checking episodes for %@.", [show valueForKey:@"name"]);
    
    NSDate *pubDate, *lastDownloaded, *lastChecked;
    NSArray *episodes = [TSParseXMLFeeds parseEpisodesFromFeeds:
                         [[show valueForKey:@"url"] componentsSeparatedByString:@"#"]
                                                       maxItems:50];
    
    if ([episodes count] == 0) {
        LogError(@"Could not download/parse feed for %@ <%@>", [show valueForKey:@"name"], [show valueForKey:@"url"]);
    }
    
    BOOL chooseAnyVersion = NO;
    
    // Get the dates before checking anything, in case we have to download more than one episode
    lastDownloaded = [show valueForKey:@"lastDownloaded"];
    lastChecked = [TSUserDefaults getDateFromKey:@"lastCheckedForEpisodes"];
    
    // Filter episodes according to user filters
    if ([show valueForKey:@"filters"] != nil) {
        episodes = [episodes filteredArrayUsingPredicate:[show valueForKey:@"filters"]];
    }
    
    NSString *lastEpisodeName = [show valueForKey:@"sortName"];
    
    // For each episode that was parsed...
    for (NSArray *episode in episodes) {
        pubDate = [episode valueForKey:@"pubDate"];
        
        // If the date we lastDownloaded episodes is before this torrent
        // was published then we should probably download the episode.
        if ([lastDownloaded compare:pubDate] == NSOrderedAscending) {
            
            // HACK HACK HACK: To avoid download an episode twice
            // Check if the sortname contains this episode name
            // HACK HACK HACK: put on the sortname the episode name
            // Why not storing this on a key? Because Core Data migrations and PrefPanes do not mix well
            NSString *episodeName = [[show valueForKey:@"name"] stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]"
                                                                                         withString:@""];
            episodeName = [episodeName stringByAppendingString:[episode valueForKey:@"episodeName"]];
            
            // Detect if the last downloaded episode was aired after this one (so do not download it!)
            // Use a cache version (lastEpisodename) because we could have download it several episodes
            // in this session, for example if the show aired two episodes in the same day
            if (![TSRegexFun wasThisEpisode:episodeName
                          airedAfterThisOne:lastEpisodeName]) {
                [pool drain];
                return;
            }
            
            // If it has been two full days since the episode was aired attempt the download of any version
            // Also check that we have checked for episodes at least once in the last day
            if ([pubDate timeIntervalSinceDate:[NSDate date]] > 2*24*60*60 &&
                [[NSDate date] timeIntervalSinceDate:lastChecked] < 25*60*60) {
                chooseAnyVersion = YES;
            } else {
                chooseAnyVersion = NO;
            }
            
            // First let's try to download the HD version from the RSS
            // Only if it is HD and HD is enabled (or SD was not available last two days)
            if (([[show valueForKey:@"quality"] boolValue] &&
                 [[episode valueForKey:@"isHD"] boolValue]) ||
                (![[show valueForKey:@"quality"] boolValue] &&
                 ![[episode valueForKey:@"isHD"] boolValue]) ||
                chooseAnyVersion) {
                
                // If the user has Miso enabled, check if there is a check-in for that episode
                // Otherwise download the episode
                if ([self hasCheckInForShow:show andEpisode:episode] ||
                    [self startDownloadingURL:[episode valueForKey:@"link"]
                                 withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"]
                                  andShowName:[show valueForKey:@"name"]]) {
                    // Update the last downloaded episode name only if it was aired after the previous stored one
                    if ([TSRegexFun wasThisEpisode:episodeName
                                 airedAfterThisOne:[show valueForKey:@"sortName"]]) {
                        // Update when the show was last downloaded
                        [show setValue:pubDate forKey:@"lastDownloaded"];
                        [show setValue:episodeName forKey:@"sortName"];
                        [[subscriptionsDelegate managedObjectContext] processPendingChanges];
                        [subscriptionsDelegate saveAction];
                    }
                }
            }
        } else {
            // The rest is not important because it is even before the previous entry
            [pool drain];
            return;
        }
        
    }
    
    [pool drain];
}

#pragma mark -
#pragma mark Status Menu
- (void) activateStatusMenu
{
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    [statusItem setImage:[NSImage imageNamed:@"TVShows-Menu-Icon-Black"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"TVShows-Menu-Icon-White"]];
    [statusItem setEnabled:YES];
    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    
    [statusItem setAction:@selector(openApplication:)];
    [statusItem setMenu:statusMenu];
    
    // Localize
    [lastUpdateItem setTitle:[NSString stringWithFormat:@"%@ %@", TSLocalizeString(@"Last Checked:"), TSLocalizeString(@"Never")]];
    [checkShowsItem setTitle:TSLocalizeString(@"Checking now, please wait...")];
    [subscriptionsItem setTitle:[NSString stringWithFormat:@"%@...", TSLocalizeString(@"Subscriptions")]];
    [syncItem setTitle:[NSString stringWithFormat:@"%@...", TSLocalizeString(@"Sync")]];
    [preferencesItem setTitle:[NSString stringWithFormat:@"%@...", TSLocalizeString(@"Preferences")]];
    [feedbackItem setTitle:[NSString stringWithFormat:@"%@...", TSLocalizeString(@"Submit Feedback")]];
    [aboutItem setTitle:[NSString stringWithFormat:@"%@ TVShows", TSLocalizeString(@"About")]];
    [disableItem setTitle:TSLocalizeString(@"Disable TVShows")];
}

- (void) updateLastCheckedItem
{
    // We have to build a localized string with the date info
    // Prepare the date formatter
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    // Create the string from this date
    NSString *formattedDateString = [dateFormatter stringFromDate:[TSUserDefaults getDateFromKey:@"lastCheckedForEpisodes"]];
    
    // Finally, update the string
    [lastUpdateItem setTitle:[NSString stringWithFormat:@"%@ %@", TSLocalizeString(@"Last Checked:"), formattedDateString]];
    
    // Enable again the menubar option
    [checkShowsItem setAction:@selector(checkNow:)];
    [checkShowsItem setTitle:TSLocalizeString(@"Check for new episodes now")];
}

- (IBAction) openApplication:(id)sender
{
    BOOL success = [[NSWorkspace sharedWorkspace] openFile:
                    [[[NSBundle bundleWithIdentifier:TVShowsAppDomain] bundlePath] stringByExpandingTildeInPath]];
    
    if (!success) {
        LogError(@"Application did not open at request.");
    }
}

- (IBAction) showSubscriptions:(id)sender
{
    NSString *command =
    @"tell application \"System Preferences\"                               \n"
    @"   activate                                                           \n"
    @"   set the current pane to pane id \"com.victorpimentel.TVShows2\"    \n"
    @"end tell                                                              \n"
    @"tell application \"System Events\"                                    \n"
    @"    tell process \"System Preferences\"                               \n"
    @"        click radio button 1 of tab group 1 of window \"TVShows\"     \n"
    @"    end tell                                                          \n"
    @"end tell                                                              ";
    
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSMutableArray arrayWithObjects:@"-e", command, nil]];
    [task launch];
}

- (IBAction) showSync:(id)sender
{
    NSString *command =
    @"tell application \"System Preferences\"                               \n"
    @"   activate                                                           \n"
    @"   set the current pane to pane id \"com.victorpimentel.TVShows2\"    \n"
    @"end tell                                                              \n"
    @"tell application \"System Events\"                                    \n"
    @"    tell process \"System Preferences\"                               \n"
    @"        click radio button 2 of tab group 1 of window \"TVShows\"     \n"
    @"    end tell                                                          \n"
    @"end tell                                                              ";
    
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSMutableArray arrayWithObjects:@"-e", command, nil]];
    [task launch];
}

- (IBAction) showPreferences:(id)sender
{
    NSString *command =
    @"tell application \"System Preferences\"                               \n"
    @"   activate                                                           \n"
    @"   set the current pane to pane id \"com.victorpimentel.TVShows2\"    \n"
    @"end tell                                                              \n"
    @"tell application \"System Events\"                                    \n"
    @"    tell process \"System Preferences\"                               \n"
    @"        click radio button 3 of tab group 1 of window \"TVShows\"     \n"
    @"    end tell                                                          \n"
    @"end tell                                                              ";
    
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSMutableArray arrayWithObjects:@"-e", command, nil]];
    [task launch];
}

- (IBAction) showAbout:(id)sender
{
    NSString *command =
    @"tell application \"System Preferences\"                               \n"
    @"   activate                                                           \n"
    @"   set the current pane to pane id \"com.victorpimentel.TVShows2\"    \n"
    @"end tell                                                              \n"
    @"tell application \"System Events\"                                    \n"
    @"    tell process \"System Preferences\"                               \n"
    @"        click radio button 4 of tab group 1 of window \"TVShows\"     \n"
    @"    end tell                                                          \n"
    @"end tell                                                              ";
    
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSMutableArray arrayWithObjects:@"-e", command, nil]];
    [task launch];
}

- (IBAction) showFeedback:(id)sender
{
    NSString *command =
    @"tell application \"System Preferences\"                               \n"
    @"   activate                                                           \n"
    @"   set the current pane to pane id \"com.victorpimentel.TVShows2\"    \n"
    @"end tell                                                              \n"
    @"tell application \"System Events\"                                    \n"
    @"    tell process \"System Preferences\"                               \n"
    @"        click button 4 of window \"TVShows\"                          \n"
    @"    end tell                                                          \n"
    @"end tell                                                              ";
    
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSMutableArray arrayWithObjects:@"-e", command, nil]];
    [task launch];
}

- (IBAction) quitHelper:(id)sender
{
    [[[PreferencesController new] autorelease] enabledControlDidChange:NO];
    [NSApp terminate];
}

- (void)checkinEpisode:(NSString *)episodeName ofShow:(NSString *)showName
{
    if ([TSUserDefaults getBoolFromKey:@"MisoEnabled" withDefault:NO] &&
        [TSUserDefaults getBoolFromKey:@"MisoCheckInEnabled" withDefault:NO]) {
        
        NSArray *seasonAndEpisode = [TSRegexFun parseSeasonAndEpisode:episodeName];
        
        if ([seasonAndEpisode count] == 3) {
            
            // Search for it on Miso
            NSDictionary *results = [misoBackend showWithQuery:showName];
            
            NSObject *show = nil;
            
            // Just pick the first show (too late, I cannot even think anymore)
            for (NSObject *result in results) {
                show = result;
                break;
            }
            
            // At this point, it should be a valid show, but maybe it is not on the Miso database yet
            if (show) {
                LogInfo(@"Adding check-in for %@ on Miso.", episodeName);
                
                [misoBackend addCheckingForShow:[[[show valueForKey:@"media"] valueForKey:@"id"] description]
                                  withSeasonNum:[TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:1]]
                                     episodeNum:[TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:2]]];
            }
        }
    }
}

#pragma mark -
#pragma mark Download Methods
- (BOOL) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName andShowName:(NSString *)show
{
    // Process the URL if the is not found
    if ([url rangeOfString:@"http"].location == NSNotFound) {
        LogInfo(@"Retrieving an HD torrent file from Torrentz of: %@", url);
        url = [TorrentzParser getAlternateTorrentForEpisode:url];
        if (url == nil) {
            LogError(@"Unable to find an HD torrent file for: %@", fileName);
            return NO;
        }
    }
    
    // Build the saving folder
    NSString *saveLocation = [TSUserDefaults getStringFromKey:@"downloadFolder"];
    
    // Check if we have to sort shows by folders or not
    if ([TSUserDefaults getBoolFromKey:@"SortInFolders" withDefault:NO]) {
        saveLocation = [saveLocation stringByAppendingPathComponent:show];
        if (![[NSFileManager defaultManager] createDirectoryAtPath:saveLocation
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            LogError(@"Unable to create the folder: %@", saveLocation);
            return NO;
        }
        // And check if we have to go deeper (sorting by season)
        if ([TSUserDefaults getBoolFromKey:@"SeasonSubfolders" withDefault:NO]) {
            NSArray *seasonAndEpisode = [TSRegexFun parseSeasonAndEpisode:fileName];
            if ([seasonAndEpisode count] == 3) {
                saveLocation = [saveLocation stringByAppendingPathComponent:
                                [NSString stringWithFormat:@"Season %@",
                                 [TSRegexFun removeLeadingZero:[seasonAndEpisode objectAtIndex:1]]]];
                if (![[NSFileManager defaultManager] createDirectoryAtPath:saveLocation
                                               withIntermediateDirectories:YES
                                                                attributes:nil
                                                                     error:nil]) {
                    LogError(@"Unable to create the folder: %@", saveLocation);
                    return NO;
                }
            }
        }
    }
    
    // Add the filename
    saveLocation = [saveLocation stringByAppendingPathComponent:fileName];
    
    LogInfo(@"Attempting to download new episode: %@", fileName);
    NSData *fileContents = [WebsiteFunctions downloadDataFrom:url];
    
    // Check if the download was right
    if (!fileContents || [fileContents length] < 100) {
        LogError(@"Unable to download file: %@ <%@>", fileName, url);
        
        // Failure!
        return NO;
    } else {
        // The file downloaded successfully, continuing...
        LogInfo(@"Episode downloaded successfully.");
        
        [fileContents writeToFile:saveLocation atomically:YES];
        
        // Bounce the downloads stack!
        [[NSDistributedNotificationCenter defaultCenter]
            postNotificationName:@"com.apple.DownloadFileFinished" object:saveLocation];
        
        // Check to see if the user wants to automatically open new downloads
        if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
            [[NSWorkspace sharedWorkspace] openFile:saveLocation withApplication:nil andDeactivate:NO];
        }
        
        if([TSUserDefaults getBoolFromKey:@"GrowlOnNewEpisode" withDefault:1]) {
            NSData *cover = [[NSData alloc] initWithData:[[TheTVDB getPosterForShow:show withShowID:@"0" withHeight:96 withWidth:66] TIFFRepresentation]];
            
            [GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"%@", show]
                                    description:[NSString stringWithFormat:TSLocalizeString(@"A new episode of %@ is being downloaded."), show]
                               notificationName:@"New Episode Downloaded"
                                       iconData:cover
                                       priority:0
                                       isSticky:0
                                   clickContext:nil];
            [cover autorelease];
        }
        
        // Checkin the episode on Miso
        [self checkinEpisode:fileName ofShow:show];
        
        // Success!
        return YES;
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
        
        if([TSUserDefaults getBoolFromKey:@"GrowlOnAppUpdate" withDefault:YES]) {
            [GrowlApplicationBridge notifyWithTitle:@"TVShows Update Downloading"
                                        description:TSLocalizeString(@"A new version of TVShows is being downloaded and installed.")
                                   notificationName:@"TVShows Update Downloaded"
                                           iconData:TVShowsHelperIcon
                                           priority:0
                                           isSticky:0
                                       clickContext:nil];
        }
    } else if([TSUserDefaults getBoolFromKey:@"GrowlOnAppUpdate" withDefault:YES]) {
        [GrowlApplicationBridge notifyWithTitle:@"TVShows Update Available"
                                    description:TSLocalizeString(@"A new version of TVShows is available for download.")
                               notificationName:@"TVShows Update Available"
                                       iconData:TVShowsHelperIcon
                                       priority:0
                                       isSticky:0
                                   clickContext:nil];
    }
}

- (void) dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [checkerLoop invalidate];
    [checkerLoop release];
    [TVShowsHelperIcon release];
    [misoBackend release];
    [subscriptionsDelegate release];
    [presetShowsDelegate release];
    [super dealloc];
}

@end
