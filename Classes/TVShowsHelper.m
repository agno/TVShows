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
#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "SubscriptionsDelegate.h"
#import "SUUpdaterSubclass.h"
#import <Growl/GrowlApplicationBridge.h>


@implementation TVShowsHelper

@synthesize checkerLoop, TVShowsHelperIcon;

- init
{
    if((self = [super init])) {
        checkerThread = nil;
        checkerLoop = nil;
        
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

- (void) awakeFromNib
{
    // This should never happen, but let's make sure TVShows is enabled before continuing.
    if ([TSUserDefaults getBoolFromKey:@"isEnabled" withDefault:YES]) {
        
        // Set up Growl notifications
        [GrowlApplicationBridge setGrowlDelegate:self];
        
        [self activateStatusMenu];
        
        [self checkNow:nil];
        
    } else {
        // TVShows is not enabled.
        LogWarning(@"The TVShowsHelper was run even though TVShows is not enabled. Quitting.");
        [self quitHelper:nil];
    }
}

- (void) runLoop
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop* threadLoop = [NSRunLoop currentRunLoop];
    
    NSInteger delay;
    NSTimeInterval seconds;
    delay = [TSUserDefaults getFloatFromKey:@"checkDelay" withDefault:0];
    
    switch (delay) {
        case 0:
            // 15 minutes
            seconds = 15*60;
            break;
        case 1:
            // 30 minutes
            seconds = 30*60;
            break;
        case 2:
            // 1 hour
            seconds = 1*60*60;
            break;
        case 3:
            // 3 hours
            seconds = 3*60*60;
            break;
        case 4:
            // 6 hours
            seconds = 6*60*60;
            break;
        case 5:
            // 12 hours
            seconds = 12*60*60;
            break;
        case 6:
            // 1 day
            seconds = 24*60*60;
            break;
        default:
            // 15 minutes
            seconds = 15*60;
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
        // Notify the user to give him some feedback
        [GrowlApplicationBridge notifyWithTitle:@"TVShows"
                                    description:TSLocalizeString(@"Checking for new episodes...")
                               notificationName:@"Checking For New Episodes"
                                       iconData:TVShowsHelperIcon
                                       priority:0
                                       isSticky:0
                                   clickContext:nil];
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
                //                        LogDebug(@"Checking for new episodes of %@.", [show valueForKey:@"name"]);
                [self checkForNewEpisodes:show];
            }
            //              }
            
        }
        
    }
    
    // Now that everything is done, update the time our last check was made.
    [TSUserDefaults setKey:@"lastCheckedForEpisodes" fromDate:[NSDate date]];
    
    // And update the menu to reflect the date
    [self performSelectorOnMainThread:@selector(updateLastCheckedItem)  withObject:nil waitUntilDone:NO];
    
    [delegateClass saveAction];
    [delegateClass release];
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

- (IBAction) showPreferences:(id)sender
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

- (IBAction) showAbout:(id)sender
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
                                    description:[NSString stringWithFormat:TSLocalizeString(@"A new episode of %@ is being downloaded."), [show valueForKey:@"name"]]
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
    [checkerLoop invalidate];
    [checkerLoop release];
    [TVShowsHelperIcon release];
    [super dealloc];
}

@end
