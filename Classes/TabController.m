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

#import <QuartzCore/QuartzCore.h>

#import "AppInfoConstants.h"
#import "TabController.h"
#import "JRFeedbackController.h"

#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"

#import "TorrentzParser.h"
#import "TheTVDB.h"
#import "LCLLogFile.h"
#import "WebsiteFunctions.h"

@implementation TabController

@synthesize selectedShow, subscriptionsDelegate;

- (void) awakeFromNib
{
    // Init the subscriptions delegate
    subscriptionsDelegate = [[SubscriptionsDelegate alloc] init];
    
    // Set displayed version information
    NSString *bundleVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary] 
                               valueForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
                              valueForKey:@"CFBundleVersion"];
    NSString *buildDate = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
                           valueForKey:@"TSBundleBuildDate"];
    
    [sidebarHeader setStringValue:@"TVShows 2"];
    [sidebarVersionText setStringValue: [NSString stringWithFormat:@"%@ (r%@)", bundleVersion, buildVersion]];
    [sidebarDateText setStringValue:buildDate];
    [endedRibbonText setStringValue:[TSLocalizeString(@"Ended") uppercaseString]];
    
    NSDate *date = [TSUserDefaults getDateFromKey:@"lastCheckedForEpisodes"];
    if (date) {
        // Set the last date/time episodes were checked for.
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
        NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        [lastCheckedDate setStringValue: [[[dateFormatter stringFromDate: date] stringByAppendingString:TSLocalizeString(@" at ")]
                                          stringByAppendingString: [timeFormatter stringFromDate: date]]];
    } else {
        [lastCheckedDate setStringValue: TSLocalizeString(@"Never")];
    }
    
    // Localize everything
    [[prefTabView tabViewItemAtIndex:0] setLabel: TSLocalizeString(@"Subscriptions")];
    [[prefTabView tabViewItemAtIndex:1] setLabel: TSLocalizeString(@"Preferences")];
    [[prefTabView tabViewItemAtIndex:2] setLabel: TSLocalizeString(@"About")];
    
    [feedbackButton setTitle: TSLocalizeString(@"Submit Feedback")];
    
    [addButton setTitle: TSLocalizeString(@"Add Show")];
    [addRSSButton setTitle: TSLocalizeString(@"Add Custom RSS")];
    [lastCheckedText setStringValue: TSLocalizeString(@"Last Checked:")];
    
    [websiteButton setTitle: TSLocalizeString(@"Website")];
    [donateButton setTitle: TSLocalizeString(@"Donate")];
    [viewLogsButton setTitle: TSLocalizeString(@"View Logs")];
    [uninstallButton setTitle: TSLocalizeString(@"Uninstall")];
    [disclaimer setStringValue: TSLocalizeString(@"No actual videos are downloaded by TVShows, only torrents which will require other programs to use. It is up to you, the user, to decide the legality of using any of the files downloaded by this application, in accordance with applicable copyright laws of you country.")];
    
    [logTitleText setStringValue: TSLocalizeString(@"Recently Logged Activity")];
    [logExplanationText setStringValue: TSLocalizeString(@"A message is logged each time new episodes are checked for. Unless noted otherwise, no new episodes were found.")];
    [logLocalizationText setStringValue: TSLocalizeString(@"Logs are stored in ~/Library/Logs/TVShows/")];
    [closeLogButton setTitle: TSLocalizeString(@"Close")];
    
    // Localize the headings of the table columns
    [[colHD headerCell] setStringValue: TSLocalizeString(@"HD")];
    [[colName headerCell] setStringValue: TSLocalizeString(@"Episode Name")];
    [[colSeason headerCell] setStringValue: TSLocalizeString(@"Season")];
    [[colEpisode headerCell] setStringValue: TSLocalizeString(@"Episode")];
    [[colDate headerCell] setStringValue: TSLocalizeString(@"Published Date")];
    
    // Localize everything else
    [showQuality setTitle: TSLocalizeString(@"Download in HD")];
    [showIsEnabled setTitle: TSLocalizeString(@"Enable downloading new episodes")];
    [statusTitle setStringValue: TSLocalizeString(@"Status")];
    [lastDownloadedTitle setStringValue: TSLocalizeString(@"Last Downloaded")];
    [nextEpisodeTitle setStringValue: TSLocalizeString(@"Next Episode")];
    [infoBoxTitle setTitle: TSLocalizeString(@"Info")];
    [prefBoxTitle setTitle: TSLocalizeString(@"Preferences")];
    [closeButton setTitle: TSLocalizeString(@"Close")];
    [editButton setTitle: TSLocalizeString(@"Edit")];
    [unsubscribeButton setTitle: TSLocalizeString(@"Unsubscribe")];
    
    // Sort the subscription list and draw the About box
    [self sortSubscriptionList];
    [self drawAboutBox];
    
    // Start the animation about one second after loading this
    [self performSelector:@selector(animateDonateButton) withObject:nil afterDelay:1];
}

- (void) animateDonateButton
{
    // Each animation step is a full second
    CATransition *presentAnimation = [CATransition animation];
    [presentAnimation setDuration:1];
    [presentAnimation setDelegate:self];
    
    // Animate the Core Animation content filters
    [donateButton setAnimations:[NSDictionary dictionaryWithObject:presentAnimation forKey:@"contentFilters"]];
    
    [self animationDidStop:nil finished:YES];
}

- (void) animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
    if (finished) {
        // Get the content filters for the button (there are two, one to add color and another one to change the hue)
        CIFilter *colorAdjust = [[donateButton contentFilters] objectAtIndex:0];
        CIFilter *hueAdjustOld = [[donateButton contentFilters] objectAtIndex:1];
        
        float hue = [[hueAdjustOld valueForKey:@"inputAngle"] floatValue];
        
        // Slowly change the hue (in radians, max is 2*PI because it is a circle)
        hue += (2 * M_PI) / 100;
        
        CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust"];
        [hueAdjust setDefaults];
        [hueAdjust setValue:[NSNumber numberWithFloat:hue] forKey:@"inputAngle"];
        
        [[donateButton animator] setContentFilters:[NSArray arrayWithObjects:colorAdjust, hueAdjust, nil]];
    }
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSRect tabFrame;
    int newWinHeight;
    
    tabFrame = [[tabView window] frame];
    
    // newWinHeight should be equal to the wanted window size (in Interface Builder) + 54 (title bar height)
    if ([[tabViewItem identifier] isEqualTo:@"tabItemPreferences"]) {
        newWinHeight = 617;
    } else if ([[tabViewItem identifier] isEqualTo:@"tabItemSubscriptions"]) {
        newWinHeight = 617;
    }  else if ([[tabViewItem identifier] isEqualTo:@"tabItemAbout"]) {
        newWinHeight = 500;
    } else {
        newWinHeight = 617;
    }
    
    tabFrame = NSMakeRect(tabFrame.origin.x, tabFrame.origin.y - (newWinHeight - (int)(NSHeight(tabFrame))), (int)(NSWidth(tabFrame)), newWinHeight);
    
    [[tabView window] setFrame:tabFrame display:YES animate:YES];
}

- (IBAction) showFeedbackWindow:(id)sender
{
    [JRFeedbackController showFeedback];
}

#pragma mark -
#pragma mark About Tab
- (IBAction) openWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: TVShowsWebsite]];
}

- (IBAction) openBlog:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: TVShowsBlog]];
}

- (IBAction) openTwitter:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: TVShowsTwitter]];
}

- (IBAction) openPaypal:(id)sender
{
    // This is a list of accepted currencies for Paypal transfers and donations
    NSArray *acceptedCurrencies = [NSArray arrayWithObjects:@"AUD", @"BRL", @"CAD", @"CZK", @"DKK", @"EUR",
                                   @"HKD", @"HUF", @"ILS", @"JPY", @"MXN", @"NOK", @"NZD", @"PHP", @"PLN",
                                   @"GBP", @"SGD", @"SEK", @"CHF", @"TWD", @"THB", @"TRY", @"USD", nil];
    
    // And this should be the preferred currency for this user
    NSString *currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
    
    // Let's assume is not supported
    BOOL supported = NO;
    
    // And let's see if it is in that currency list
    for (NSString *code in acceptedCurrencies) {
        if ([currencyCode isEqualToString:code]) {
            supported = YES;
            break;
        }
    }
    
    // Fallback to euros!
    if (!supported) {
        currencyCode = @"EUR";
    }
    
    // Also retrieve the country for this user
    NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    NSString *donationURL = [NSString stringWithFormat:TVShowsDonations, currencyCode, countryCode];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:donationURL]];
}

- (IBAction) openUninstaller:(id)sender
{
    // Create an alert box.
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: TSLocalizeString(@"Yes")];
    [alert addButtonWithTitle: TSLocalizeString(@"No")];
    [alert setMessageText: TSLocalizeString(@"Uninstall TVShows")];
    [alert setInformativeText: TSLocalizeString(@"Are you sure you want to uninstall TVShows? This will also remove all preferences and subscriptions.")];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    // Run the alert and then wait for user input.
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // Drat! They really do want to uninstall. Find the path to the uninstaller.
        NSString *launchPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain]
                                pathForResource:@"Uninstaller"
                                ofType:@"app"];
        launchPath = [launchPath stringByAppendingPathComponent:@"Contents/MacOS/applet"];
        
        // Start up an NSTask to run the uninstaller.
        NSTask *uninstaller = [[NSTask alloc] init];
        [uninstaller setLaunchPath:launchPath];
        [uninstaller launch];
        
        [uninstaller release];
    }
    
    [alert release];
}

- (void) drawAboutBox
{
    NSString *pathToAboutBoxText = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] 
                                    pathForResource: @"Credits" 
                                    ofType: @"rtf"];
    
    NSAttributedString *aboutBoxText = [[[NSAttributedString alloc]
                                         initWithPath: pathToAboutBoxText
                                         documentAttributes: nil] autorelease];
    
    [[textView_aboutBox textStorage] setAttributedString:aboutBoxText];
}

#pragma mark -
#pragma mark Log Viewer

- (IBAction) showLogViewerWindow:(id)sender
{
    NSString *loggedItems;
    
    [NSApp beginSheet: logViewerWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    loggedItems = [NSString stringWithContentsOfFile: [LCLLogFile defaultPathInHomeLibraryLogsOrPath:nil]
                                            encoding: NSUTF8StringEncoding
                                               error: NULL];
    
    if (!loggedItems) {
        loggedItems = TSLocalizeString(@"No activity has been logged yet. Have you recently installed TVShows?");
    }
    
    [textView_logViewer setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
    [textView_logViewer setString:loggedItems];
    [textView_logViewer moveToEndOfDocument:nil];
    
    [NSApp endSheet: logViewerWindow];
    [NSApp runModalForWindow: logViewerWindow];
}

- (IBAction) closeLogViewerWindow:(id)sender
{
    [NSApp stopModal];
    [logViewerWindow orderOut: self];
}

#pragma mark -
#pragma mark Subscriptions Tab
- (IBAction) displayShowInfoWindow:(id)sender
{
    selectedShow = [[[sender cell] representedObject] representedObject];
    
    // Link that info to the edit button
    [[editButton cell] setRepresentedObject:self];
    
    // Set up the date formatter
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // Set the available values now
    [showName setStringValue: [selectedShow valueForKey:@"name"]];
    [showStatus setStringValue: TSLocalizeString(@"Unknown")];
    [showLastDownloaded setStringValue: [dateFormatter stringFromDate:[selectedShow valueForKey:@"lastDownloaded"]]];
    [showNextEpisode setStringValue: TSLocalizeString(@"Unknown")];
    [showQuality setState: [[selectedShow valueForKey:@"quality"] intValue]];
    [showIsEnabled setState: [[selectedShow valueForKey:@"isEnabled"] boolValue]];
    
    NSImage *defaultPoster = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"posterArtPlaceholder" ofType:@"jpg"]] autorelease];
    [defaultPoster setSize: NSMakeSize(127, 184)];
    [showPoster setImage: defaultPoster];
    
    // Reset the Episode Array Controller
    [[episodeArrayController content] removeAllObjects];
    [episodeArrayController removeObjects:[episodeArrayController arrangedObjects]];
    [episodeTableView reloadData];
    [episodeTableView setEnabled:NO];
    
    if (selectedShow) {
        NSString *showFeeds = [selectedShow valueForKey:@"url"];
        NSArray *arguments = [NSArray arrayWithObjects:[selectedShow valueForKey:@"name"],
                              [NSString stringWithFormat:@"%@", [selectedShow valueForKey:@"tvdbID"]], nil];
        
        // Grab the list of episodes
        [self performSelectorInBackground:@selector(setEpisodesForShow:) withObject:showFeeds];
        
        // Display the show poster now that it's been resized.
        [self performSelectorInBackground:@selector(setPosterForShow:) withObject:arguments];
        
        // Grab the show status
        [self performSelectorInBackground:@selector(setStatusForShow:) withObject:arguments];
        
        // Grab the next episode date
        [self performSelectorInBackground:@selector(setNextEpisodeForShow:) withObject:arguments];
    }
    
    [NSApp beginSheet: showInfoWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp endSheet: showInfoWindow];
    [NSApp runModalForWindow: showInfoWindow];
}

#pragma mark -
#pragma mark Background workers
- (void) setEpisodesForShow:(NSString *)showFeeds
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:showFeeds,
                        [TSParseXMLFeeds parseEpisodesFromFeeds:[showFeeds componentsSeparatedByString:@"#"]
                                                       maxItems:50], nil];
    
    if ([results count] < 2) {
        LogError(@"Could not download/parse feed(s) <%@>", showFeeds);
        return;
    }
    
    [self performSelectorOnMainThread:@selector(updateEpisodes:) withObject:results waitUntilDone:NO];
    
    [pool drain];
}

- (void) setStatusForShow:(NSArray *)arguments
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:[arguments objectAtIndex:0],
                            [TheTVDB getShowStatus:[arguments objectAtIndex:0]
                                        withShowID:[arguments objectAtIndex:1]], nil];
    
    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:results waitUntilDone:NO];
    
    [pool drain];
}

- (void) setNextEpisodeForShow:(NSArray *)arguments
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:[arguments objectAtIndex:0],
                        [TheTVDB getShowNextEpisode:[arguments objectAtIndex:0]
                                         withShowID:[arguments objectAtIndex:1]], nil];
    
    [self performSelectorOnMainThread:@selector(updateNextEpisode:) withObject:results waitUntilDone:NO];
    
    [pool drain];
}

- (void) setPosterForShow:(NSArray *)arguments
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:[arguments objectAtIndex:0],
                        [[[TheTVDB getPosterForShow:[arguments objectAtIndex:0]
                                         withShowID:[arguments objectAtIndex:1]
                                         withHeight:187
                                          withWidth:129] copy] autorelease], nil];
    
    [self performSelectorOnMainThread:@selector(updatePoster:) withObject:results waitUntilDone:NO];
    
    [pool drain];
}

- (void) updateEpisodes:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    if (!selectedShow) {
        return;
    }
    
    // Extract the data
    NSString *showFeeds = [data objectAtIndex:0];
    NSArray *results = [data objectAtIndex:1];
    NSString *copy = [selectedShow valueForKey:@"url"];
    
    // Continue only if the selected show is the same as before
    if ([showFeeds isEqualToString:copy]) {
        [episodeTableView setEnabled:YES];
        [episodeArrayController addObjects:results];
        
        // Check if there are HD episodes, if so enable the "Download in HD" checkbox
        BOOL feedHasHDEpisodes = [TSParseXMLFeeds feedHasHDEpisodes:results];
        
        if (!feedHasHDEpisodes) {
            [showQuality setState:NO];
        }
        [showQuality setEnabled:feedHasHDEpisodes];
        
        // Update the filter predicate to only display the correct quality.
        [self showQualityDidChange:nil];
    }
}

- (void) updateStatus:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    if (!selectedShow) {
        return;
    }
    
    // Extract the data
    NSString *name = [data objectAtIndex:0];
    NSString *status = nil;
    if ([data count] > 1) {
        status = [data objectAtIndex:1];
    }
    NSString *copy = [selectedShow valueForKey:@"name"];
    
    // Continue only if the selected show is the same as before
    if ([name isEqualToString:copy] && status != nil) {
        // And finally we can set the status
        [showStatus setStringValue:TSLocalizeString(status)];
        if ([status isEqualToString:@"Ended"]) {
            [showNextEpisode setStringValue:TSLocalizeString(@"Never")];
        }
    }
}

- (void) updateNextEpisode:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    if (!selectedShow) {
        return;
    }
    
    // Extract the data
    NSString *name = [data objectAtIndex:0];
    NSDate *nextEpisode = nil;
    if ([data count] > 1) {
        nextEpisode = [data objectAtIndex:1];
    }
    NSString *copy = [selectedShow valueForKey:@"name"];
    
    // Continue only if the selected show is the same as before
    if ([name isEqualToString:copy] && nextEpisode != nil) {
        // Set up the date formatter
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
        [showNextEpisode setStringValue:[dateFormatter stringFromDate:nextEpisode]];
    }
}

- (void) updatePoster:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    if (!selectedShow) {
        return;
    }
    
    // Extract the data
    NSString *name = [data objectAtIndex:0];
    NSImage *poster = [data objectAtIndex:1];
    NSString *copy = [selectedShow valueForKey:@"name"];
    
    // Continue only if the selected show is the same as before
    if ([name isEqualToString:copy]) {
        [showPoster setImage:poster];
        [showPoster display];
    }
}

- (IBAction) closeShowInfoWindow:(id)sender
{
    // Close the window first
    // The following code has a bug in Intel 32-bit that I couldn't fix,
    // so I prefer not to save that information rather than not be able to close the app
    [NSApp stopModal];
    [showInfoWindow orderOut: self];
    
    // NSManagedContext objectWithID is required for it to save changes to the disk.
    // We also need to update the original selectedShow NSManagedObject so that the
    // interface displays any changes when the window is opened multiple times a session.
    NSManagedObject *selectedShowObj = [[subscriptionsDelegate managedObjectContext] objectWithID:[selectedShow objectID]];
    
    // Update the per-show preferences
    [selectedShow setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [selectedShow setValue:[NSNumber numberWithBool:[showIsEnabled state]] forKey:@"isEnabled"];
    [selectedShowObj setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [selectedShowObj setValue:[NSNumber numberWithBool:[showIsEnabled state]] forKey:@"isEnabled"];
    
    // Be sure to process pending changes before saving or it won't save correctly.
    [[subscriptionsDelegate managedObjectContext] processPendingChanges];
    [subscriptionsDelegate saveAction];
    
    // Reset the selected show
    selectedShow = nil;
}

- (IBAction) showQualityDidChange:(id)sender
{
    if ([showQuality state]) {
        [episodeArrayController setFilterPredicate:
         [NSCompoundPredicate andPredicateWithSubpredicates:
          [NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"isHD == '1'"],
           [selectedShow valueForKey:@"filters"],nil]]];
    } else {
        [episodeArrayController setFilterPredicate:
         [NSCompoundPredicate andPredicateWithSubpredicates:
          [NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"isHD == '0'"],
           [selectedShow valueForKey:@"filters"],nil]]];
    }
}

- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName andShowName:(NSString *)show
{
    // Process the URL if the is not found
    if ([url rangeOfString:@"http"].location == NSNotFound) {
        LogInfo(@"Retrieving an HD torrent file from Torrentz of: %@", url);
        url = [TorrentzParser getAlternateTorrentForEpisode:url];
        if (url == nil) {
            LogError(@"Unable to find an HD torrent file for: %@", fileName);
            
            // Display the error
            NSRunCriticalAlertPanel([NSString stringWithFormat:TSLocalizeString(@"Unable to find an HD torrent for %@"), fileName],
                                    TSLocalizeString(@"The file may not be released yet. Please try again later or check your internet connection. Alternatively you can download the SD version."),
                                    TSLocalizeString(@"Ok"),
                                    nil,
                                    nil);
            
            return;
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
            return;
        }
    }
    
    // Add the filename
    saveLocation = [saveLocation stringByAppendingPathComponent:fileName];
    
    // Method copied from TVShowsHelper.m
    LogInfo(@"Attempting to download new episode: %@", fileName);
    NSData *fileContents = [WebsiteFunctions downloadDataFrom:url];
    
    if (!fileContents || [fileContents length] < 100) {
        LogError(@"Unable to download file: %@ <%@>",fileName, url);
        
        // Display the error
        NSRunCriticalAlertPanel([NSString stringWithFormat:TSLocalizeString(@"Unable to download %@"), fileName],
                                TSLocalizeString(@"Cannot connect. Please try again later or check your internet connection"),
                                TSLocalizeString(@"Ok"),
                                nil,
                                nil);
        
    } else {
        // The file downloaded successfully, continuing...
        LogInfo(@"Episode downloaded successfully.");
        
        [fileContents writeToFile:saveLocation atomically:YES];
        
        // Check to see if the user wants to automatically open new downloads
        if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
            [[NSWorkspace sharedWorkspace] openFile:saveLocation withApplication:nil andDeactivate:NO];
        }
    }
}

- (BOOL) tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    // Check to see whether or not this is the GET button or not.

    // Which column and row was clicked?
    NSInteger clickedCol = [episodeTableView clickedColumn];
    NSInteger clickedRow = [episodeTableView clickedRow];
    
    if (clickedRow >= 0 && clickedCol >= 0) {
        // Grab information about the clicked cell.
        NSCell *cell = [episodeTableView preparedCellAtColumn:clickedCol row:clickedRow];
        
        // If the cell is an NSButtonCell and it's enabled...
        if ([cell isKindOfClass:[NSButtonCell class]] && [cell isEnabled]) {
            // This currently only returns a Torrent file and should eventually regex
            // out the actual file extension of the item we're downloading.
            NSObject *episode = [[episodeArrayController arrangedObjects] objectAtIndex:clickedRow];
            [self startDownloadingURL:[episode valueForKey:@"link"]
                         withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"]
                          andShowName:[selectedShow valueForKey:@"name"]];
        }
    }

    // Don't select the row
    return NO;
}

- (void) sortSubscriptionList
{
    // Arguably, I don't really know how this works, and I only reached this method
    // after hours and hours of debugging and trying to make the NSArrayController not
    // send all its elements to the NSControllerView in every sorting step.
    // But OMG, THIS IS THE MOST AMAZING THING IN THE WORLD
    // IT'S SO GOOD I WANT TO HAVE KIDS WITH IT,
    // KILL THEM AND THEN MAKE MORE KIDS
    [SBArrayController setUsesLazyFetching:YES];
    
    NSSortDescriptor *SBSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"sortName"
                                                                     ascending: YES
                                                                      selector: @selector(caseInsensitiveCompare:)];
    [SBArrayController setSortDescriptors:[NSArray arrayWithObject:SBSortDescriptor]];
    
    [SBSortDescriptor release];
}

- (IBAction) unsubscribeFromShow:(id)sender
{
    // Ask for confirmation to the user
    if (NSRunCriticalAlertPanel([NSString stringWithFormat:TSLocalizeString(@"Are you sure you want to unsubscribe from %@?"),
                                 [selectedShow valueForKey:@"name"]],
                                TSLocalizeString(@"This action cannot be undone."),
                                TSLocalizeString(@"Unsubscribe"),
                                TSLocalizeString(@"Cancel"),
                                nil) != NSAlertDefaultReturn) { 
        return;
    }
    
    NSManagedObject *selectedShowObj = [[subscriptionsDelegate managedObjectContext] objectWithID:[selectedShow objectID]];
    
    // I don't understand why I have to remove the object from both locations
    // but it works so I won't question it.
    [SBArrayController removeObject:selectedShow];
    [[subscriptionsDelegate managedObjectContext] deleteObject:selectedShowObj];
    
    [self closeShowInfoWindow:(id)sender];
    
    [[subscriptionsDelegate managedObjectContext] processPendingChanges];
    [subscriptionsDelegate saveAction];
}

- (void) dealloc
{
    [selectedShow release];
    [subscriptionsDelegate release];
    [super dealloc];
}

@end
