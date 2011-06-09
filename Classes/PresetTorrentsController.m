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

#import "PresetTorrentsController.h"
#import "TabController.h"

#import "PresetShowsDelegate.h"
#import "SubscriptionsDelegate.h"

#import "TSUserDefaults.h"
#import "TSParseXMLFeeds.h"
#import "TSRegexFun.h"

#import "RegexKitLite.h"
#import "WebsiteFunctions.h"
#import "TheTVDB.h"
#import "TorrentzParser.h"
#import "NSXMLNode-utils.h"

#pragma mark Define Macros

#define TVDBURL                     @"http://thetvdb.com/?tab=series&id=%@"
#define ShowListURL                 @"https://github.com/victorpimentel/tvshowsapp.com/raw/master/showlist/showlist.xml"
#define ShowListMirror              @"http://tvshowsapp.com/showlist/showlist.xml"
#define SelectTagsRegex             @"<select name=\"show\">(.+?)</select>"
#define OptionTagsRegex             @"(?!<option value=\")([[:digit:]]+)(.*?)(?=</option>)"
#define RSSIDRegex                  @"([[:digit:]]+)(?![[:alnum:]]|[[:space:]])"
#define DisplayNameRegex            @"\">(.+)"
#define SeparatorBetweenNameAndID   @"\">"

#pragma mark -
#pragma mark Preset Torrents Window


@implementation PresetTorrentsController

- init
{
    if((self = [super init])) {
        hasDownloadedList = NO;
        isTranslated = NO;
    }
    
    return self;
}

- (void) localizeWindow
{
    // Localize the buttons
    [showQuality setTitle: TSLocalizeString(@"Download in HD")];
    [cancelButton setTitle: TSLocalizeString(@"Cancel")];
    [subscribeButton setTitle: TSLocalizeString(@"Subscribe")];
    [moreInfoButton setTitle: [NSString stringWithFormat:@"%@...", TSLocalizeString(@"More Info")]];
    [startFromText setStringValue: TSLocalizeString(@"Start subscription with:")];
    [nextAiredButton setTitle: TSLocalizeString(@"Next aired episode")];
    [otherEpisodeButton setTitle: TSLocalizeString(@"This episode:")];
    
    // Localize the headings of the table columns
    [[colHD headerCell] setStringValue: TSLocalizeString(@"HD")];
    [[colName headerCell] setStringValue: TSLocalizeString(@"Episode Name")];
    [[colSeason headerCell] setStringValue: TSLocalizeString(@"Season")];
    [[colEpisode headerCell] setStringValue: TSLocalizeString(@"Episode")];
    [[colDate headerCell] setStringValue: TSLocalizeString(@"Published Date")];
    
    // Search field and Loading text
    [[PTSearchField cell] setPlaceholderString: TSLocalizeString(@"Search")];
    [loadingText setStringValue: TSLocalizeString(@"Updating Show Information…")];
    
    // Sort the preloaded list
    [self sortTorrentShowList];
    
    // Reset the selection and search bar
    [PTArrayController setSelectionIndex:-1];
    [[PTSearchField cell] cancelButtonCell];
    
    // Disable any control
    [PTSearchField setEnabled:NO];
    [PTTableView setEnabled:NO];
    [cancelButton setEnabled:NO];
    [subscribeButton setEnabled:NO];
    [showQuality setEnabled:NO];
    [moreInfoButton setEnabled:NO];
    [nextAiredButton setEnabled:NO];
    [otherEpisodeButton setEnabled:NO];
    
    // And start the loading throbber
    [loading startAnimation:nil];
    [loadingText setHidden:NO];
    [descriptionView setHidden:YES];
    
    isTranslated = YES;
}

- (IBAction) displayPresetTorrentsWindow:(id)sender
{
    errorHasOccurred = NO;
    
    // Localize things and prepare the window (only needed the first time)
    if (!isTranslated) {
        [self localizeWindow];
    }
    
    // Always remember the user preference
    [showQuality setState:[TSUserDefaults getBoolFromKey:@"AutoSelectHDVersion" withDefault:1]];
    
    // Grab the list of episodes
    [episodeArrayController removeObjects:[episodeArrayController content]];
    [self tableViewSelectionDidChange:nil];
    
    [NSApp beginSheet:PTWindow
       modalForWindow:[[NSApplication sharedApplication] mainWindow]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    // Only download the show list once per session
    if (!hasDownloadedList) {
        [self downloadTorrentShowList];
        
        // Close the window
        if(errorHasOccurred == YES) {
            [NSApp endSheet:PTWindow];
            [self closePresetTorrentsWindow:nil];
            return;
        }
        
        // Enable the controls
        [PTSearchField setEnabled:YES];
        [PTTableView setEnabled:YES];
        [cancelButton setEnabled:YES];
        [subscribeButton setEnabled:YES];
        [showQuality setEnabled:YES];
        [moreInfoButton setEnabled:YES];
        [nextAiredButton setEnabled:YES];
        
        // Reset the selection
        [PTArrayController setSelectionIndex:0];
        [PTTableView scrollRowToVisible:0];
    }
    
    // Focus the search field
    [[PTSearchField cell] performClick:self];
    
    [NSApp endSheet: PTWindow];
    
    [NSApp runModalForWindow: PTWindow];
}

- (IBAction) closePresetTorrentsWindow:(id)sender
{
    [NSApp stopModal];
    [PTWindow orderOut:self];
}

- (IBAction) showQualityDidChange:(id)sender
{
    if ([showQuality state]) {
        // Is HD and HD is enabled.
        [episodeArrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"isHD == '1'"]];
    } else if (![showQuality state]) {
        // Is not HD and HD is not enabled.
        [episodeArrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"isHD == '0'"]];
    }
    
    // Select the first result
    if ([[episodeArrayController arrangedObjects] count] > 0) {
        [episodeTableView selectRow:0 byExtendingSelection:NO];
        [otherEpisodeButton setEnabled:YES];
    } else {
        [episodeTableView selectRow:0 byExtendingSelection:NO];
        [nextAiredButton setState:YES];
        [otherEpisodeButton setEnabled:NO];
        [otherEpisodeButton setState:NO];
    }
}

- (void) sortTorrentShowList
{
    // Sort the shows alphabetically
    NSSortDescriptor *PTSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortName"
                                                                     ascending:YES 
                                                                      selector:@selector(caseInsensitiveCompare:)];
    [PTArrayController setSortDescriptors:[NSArray arrayWithObject:PTSortDescriptor]];
    
    [PTSortDescriptor release];
}

- (IBAction) reloadShowList:(id)sender {
    
    // Start the loading throbber
    [loading startAnimation:nil];
    [loadingText setHidden:NO];
    
    // Grab the list of episodes (again)
    [episodeArrayController removeObjects:[episodeArrayController content]];
    [TSUserDefaults setKey:@"LastDownloadedShowList" fromDate:nil];
    [self downloadTorrentShowList];
    
    // Reset the selection
    [PTArrayController setSelectionIndex:0];
    [PTTableView scrollRowToVisible:0];
    
    // Focus the search field
    [[PTSearchField cell] performClick:self];
    
}

- (void) updateSubscriptions
{
    // There's probably a better way to do this:
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    NSManagedObjectContext *context = [delegateClass managedObjectContext];
    NSString *name;
    
    // Update all subscriptions
    for (NSManagedObject *show in [SBArrayController arrangedObjects]) {
        
        // Only update the default tv shows
        if ([show valueForKey:@"filters"] == nil) {
            
            // Let's assume it is cancelled
            BOOL cancelled = YES;
            
            // Search in every known show
            for (NSMutableDictionary *showDict in [PTArrayController arrangedObjects]) {
                name = [show valueForKey:@"name"];
                
                // Fix some shows that changed their names
                if ([name isEqualToString:@"30 Seconds AU"]) name = @"30 Seconds";
                if ([name isEqualToString:@"Archer"]) name = @"Archer (2009)";
                if ([name isEqualToString:@"Being Human"]) name = @"Being Human (US)";
                if ([name isEqualToString:@"Big Brother US"]) name = @"Big Brother";
                if ([name isEqualToString:@"Bob's Burger"]) name = @"Bob's Burgers";
                if ([name isEqualToString:@"Castle"]) name = @"Castle (2009)";
                if ([name isEqualToString:@"Conan"]) name = @"Conan (2010)";
                if ([name isEqualToString:@"Doctor Who"]) name = @"Doctor Who (2005)";
                if ([name isEqualToString:@"David Letterman"]) name = @"Late Show with David Letterman";
                if ([name isEqualToString:@"Hells Kitchen"]) name = @"Hells Kitchen (US)";
                if ([name isEqualToString:@"MonsterQuest"]) name = @"Monster Quest";
                if ([name isEqualToString:@"Parenthood"]) name = @"Parenthood (2010)";
                if ([name isEqualToString:@"The Big C	"]) name = @"The Big C";
                if ([name isEqualToString:@"The Office"]) name = @"The Office (US)";
                if ([name isEqualToString:@"The Daily Show"]) name = @"The Daily Show with Jon Stewart";
                if ([name isEqualToString:@"The Killing"]) name = @"The Killing (2011)";
                if ([name isEqualToString:@"Undercover Boss"]) name = @"Undercover Boss (US)";
                if ([name isEqualToString:@"Who Do You Think You Are"]) name = @"Who Do You Think You Are (US)";
                
                // And finally update all the info!
                if ([name isEqualToString:[showDict valueForKey:@"displayName"]]) {
                    NSManagedObject *subscription = [context objectWithID:[show objectID]];
                    
                    bool cleanSortName = ([TSRegexFun parseSeasonAndEpisode:[show valueForKey:@"sortName"]] == nil);
                    
                    [show setValue:[showDict valueForKey:@"displayName"] forKey:@"name"];
                    if (cleanSortName) [show setValue:[showDict valueForKey:@"sortName"] forKey:@"sortName"];
                    [show setValue:[showDict valueForKey:@"tvdbID"] forKey:@"tvdbID"];
                    [show setValue:[showDict valueForKey:@"name"] forKey:@"url"];
                    [subscription setValue:[showDict valueForKey:@"displayName"] forKey:@"name"];
                    if (cleanSortName) [subscription setValue:[showDict valueForKey:@"sortName"] forKey:@"sortName"];
                    [subscription setValue:[showDict valueForKey:@"tvdbID"] forKey:@"tvdbID"];
                    [subscription setValue:[showDict valueForKey:@"name"] forKey:@"url"];
                    
                    // Great, so it is not cancelled
                    cancelled = NO;
                    
                    break;
                }
            }
            
            // Oh, oh, the show has been cancelled, warn the user!
            if (cancelled) {
                // By disabling the sortName, the user interface gets updated
                NSManagedObject *subscription = [context objectWithID:[show objectID]];
                [show setValue:@"" forKey:@"sortName"];
                [subscription setValue:@"" forKey:@"sortName"];
            }
            
        }
    }
    
    // Be sure to process pending changes before saving or it won't save correctly.
    [[delegateClass managedObjectContext] processPendingChanges];
    [delegateClass saveAction];
    [delegateClass release];
}

- (void) downloadTorrentShowList
{
    // First check if we need to update the show list
    NSDate *lastChecked = [TSUserDefaults getDateFromKey:@"LastDownloadedShowList"];
    
    // If three days did not pass since the last check, do not update the show list
    if (lastChecked != nil && [[NSDate date] timeIntervalSinceDate:lastChecked] < 3*24*60*60) {
        LogInfo(@"Using a cached show list.");
        hasDownloadedList = YES;
        return;
    }
    
    LogInfo(@"Downloading an updated show list.");
    
    // There's probably a better way to do this:
    id delegateClass = [[PresetShowsDelegate alloc] init];
    
    NSString *displayName, *sortName;
    NSMutableString *name;
    int tvdbID;
    
    // The rest of this method is extremely messy but it works for the time being
    // Feel free to improve it if you find a way
    
    // Download the page containing the show list
    NSString *showListContents = [WebsiteFunctions downloadStringFrom:ShowListURL];
    
    // Try the mirror if there was no luck
    if (!showListContents || [showListContents length] < 1000) {
        LogInfo(@"Downloading an updated show list from the mirror.");
        showListContents = [WebsiteFunctions downloadStringFrom:ShowListMirror];
    }
    
    NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:showListContents
                                                          options:NSXMLDocumentTidyXML
                                                            error:nil] autorelease];
    NSXMLNode *rootNode = nil;
    
    if (doc != nil) {
        rootNode = [doc rootElement];
    }
    
    // Check to make sure the website is loading and that the root node isn't nil
    if (showListContents && [showListContents length] < 1000) {
        [self errorWindowWithStatusCode:102];
    } else if (rootNode == nil) {
        [self errorWindowWithStatusCode:101];
    } else {
        // Reset the existing show list before continuing. In a perfect world we'd
        // only be adding shows that didn't already exist, instead of deleting
        // everything and starting from scratch.
        [delegateClass resetPresetShows];
        [[PTArrayController content] removeAllObjects];
        
        NSManagedObjectContext *context = [delegateClass managedObjectContext];
        
        // Extract the shows from the children nodes
        NSArray *shows = [rootNode children];
        
        for (NSXMLNode *show in shows) {
            // Yes, it's extremely messy to be adding it to the array controller and to
            // the MOC separately but I don't have time to debug the issue with 32bit.
            NSManagedObject *showObj = [NSEntityDescription insertNewObjectForEntityForName:@"Show"
                                                                     inManagedObjectContext:context];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            
            displayName = [[show childNamed:@"name"] stringValue];
            sortName = [displayName stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]" withString:@""];
            tvdbID = [[[show childNamed:@"tvdbid"] stringValue] intValue];
            
            // Now we get to the really tricky part. We are going to use the name to store
            // all the feed urls for this tv show. WHY? Because we cannot change the
            // CoreData store until we moved this preference pane to an app
            name = [[[NSMutableString alloc] init] autorelease];
            
            // We concatenate every feed separating them with #
            for (NSString *feed in [[show childNamed:@"mirrors"] childrenAsStrings]) {
                [name appendFormat:@"%@#", feed];
            }
            
            [showObj setValue:displayName forKey:@"displayName"];
            [showObj setValue:[name copy] forKey:@"name"];
            [showObj setValue:sortName forKey:@"sortName"];
            [showObj setValue:[NSDate date] forKey:@"dateAdded"];
            [showObj setValue:[NSNumber numberWithInt:tvdbID] forKey:@"tvdbID"];
            [showObj setValue:[NSNumber numberWithInt:tvdbID] forKey:@"showrssID"];
            
            [showDict setValue:displayName forKey:@"displayName"];
            [showDict setValue:[name copy] forKey:@"name"];
            [showDict setValue:sortName forKey:@"sortName"];
            [showDict setValue:[NSDate date] forKey:@"dateAdded"];
            [showDict setValue:[NSNumber numberWithInt:tvdbID] forKey:@"tvdbID"];
            [showDict setValue:[NSNumber numberWithInt:tvdbID] forKey:@"showrssID"];
            
            [PTArrayController addObject:showDict];
            [context insertObject:showObj];
        }
        
        hasDownloadedList = YES;
        
        [context processPendingChanges];
        [delegateClass saveAction];
        
        LogInfo(@"Finished downloading the new show list.");
        
        [TSUserDefaults setKey:@"LastDownloadedShowList" fromDate:[NSDate date]];
        [self updateSubscriptions];
    }
    
    [self sortTorrentShowList];
    
    [delegateClass release];
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    // Don't prematurely download show information;
    // tableViewSelectionDidChange is called when the app first starts
    if (hasDownloadedList) {
        
        // If the selectedRow is -1 (no selection) or null, try to set a selection.
        if ([PTTableView selectedRow] == -1 || ![PTTableView selectedRow]) {
            [PTArrayController setSelectionIndex:0];
        }
        
        // No matter what, reset the elements of the view
        [self resetShowView];
        
        // Make sure we were able to correctly set a selection before continuing,
        // or else searching and the scrollbar will fail.
        if ([PTTableView selectedRow] != -1 || ![PTTableView selectedRow]) {
            
            NSString *showFeeds = nil;
            NSArray *arguments = nil;
            
            // First disable completely the subscribe button is the user is already subscribed
            if ([[PTArrayController selectedObjects] count] != 0) {
                if ([self userIsSubscribedToShow:[[[PTArrayController selectedObjects] objectAtIndex:0] valueForKey:@"displayName"]]) {
                    [subscribeButton setEnabled:NO];
                } else {
                    [subscribeButton setEnabled:YES];
                }
                
                showFeeds = [[[PTArrayController selectedObjects] objectAtIndex:0] valueForKey:@"name"];
                arguments = [NSArray arrayWithObjects:
                             [[[PTArrayController selectedObjects] objectAtIndex:0] valueForKey:@"displayName"],
                             [NSString stringWithFormat:@"%@",
                              [[[PTArrayController selectedObjects] objectAtIndex:0] valueForKey:@"tvdbID"]], nil];
                
                [moreInfoButton setEnabled:YES];
            }
            
            // In the meantime show the loading throbber
            [self showLoadingThrobber];
            
            if (showFeeds != nil) {
                // Grab the list of episodes
                [self performSelectorInBackground:@selector(setEpisodesForShow:) withObject:showFeeds];
            }
            
            if (arguments != nil) {
                // Grab the show poster
                [self performSelectorInBackground:@selector(setPosterForShow:) withObject:arguments];
                
                // Grab the show description
                [self performSelectorInBackground:@selector(setDescriptionForShow:) withObject:arguments];
            }
        }
    }
}

- (void) resetShowView {
    [episodeArrayController removeObjects:[episodeArrayController content]];
    [showDescription setString:@""];
    [moreInfoButton setEnabled:NO];
    [nextAiredButton setState:YES];
    [otherEpisodeButton setEnabled:NO];
    [otherEpisodeButton setState:NO];
    [episodeTableView setEnabled:NO];
    [self setDefaultPoster];
    [self setUserDefinedShowQuality];
}

- (void) setDefaultPoster {
    NSImage *defaultPoster = [[[NSImage alloc] initByReferencingFile:
                               [[NSBundle bundleForClass:[self class]] pathForResource:@"posterArtPlaceholder"
                                                                                ofType:@"jpg"]] autorelease];
    [defaultPoster setSize:NSMakeSize(129, 187)];
    [showPoster setImage:defaultPoster];
}

- (void) setUserDefinedShowQuality {
    [showQuality setState:[TSUserDefaults getBoolFromKey:@"AutoSelectHDVersion" withDefault:1]];
}

- (void) showLoadingThrobber {
    [loading startAnimation:nil];
    [loadingText setHidden:NO];
    [descriptionView setHidden:YES];
}

- (void) hideLoadingThrobber {
    [loading stopAnimation:nil];
    [loadingText setHidden:YES];
    [descriptionView setHidden:NO];
}

- (IBAction) openMoreInfoURL:(id)sender {
    // Check if any show is selected
    NSArray *selectedObjects = [PTArrayController selectedObjects];
    if ([selectedObjects count] == 0) {
        return;
    }
    
    // Extract the TVDB id
    NSString *tvdbid = [[selectedObjects objectAtIndex:0] valueForKey:@"tvdbID"];
    
    // Open the url
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:TVDBURL, tvdbid]]];
}

- (IBAction) selectNextAired:(id)sender {
    [episodeTableView setEnabled:NO];
}

- (IBAction) selectOtherEpisode:(id)sender {
    [episodeTableView setEnabled:YES];
}

#pragma mark -
#pragma mark Background workers
- (void) setEpisodesForShow:(NSString *)showFeeds
{
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:showFeeds,
                        [TSParseXMLFeeds parseEpisodesFromFeeds:[showFeeds componentsSeparatedByString:@"#"]
                                                       maxItems:50], nil];
    
    if ([results count] < 2) {
        LogError(@"Could not download/parse feed(s) <%@>", showFeeds);
        return;
    }
    
    [self performSelectorOnMainThread:@selector(updateEpisodes:) withObject:results waitUntilDone:NO];
}

- (void) setPosterForShow:(NSArray *)arguments
{
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:[arguments objectAtIndex:0],
                        [[[TheTVDB getPosterForShow:[arguments objectAtIndex:0]
                                         withShowID:[arguments objectAtIndex:1]
                                         withHeight:187
                                          withWidth:129] copy] autorelease], nil];
    
    [self performSelectorOnMainThread:@selector(updatePoster:) withObject:results waitUntilDone:NO];
}

- (void) setDescriptionForShow:(NSArray *)arguments
{
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:[arguments objectAtIndex:0],
                        [TheTVDB getValueForKey:@"Overview"
                                     withShowID:[arguments objectAtIndex:1]
                                    andShowName:[arguments objectAtIndex:0]], nil];
    
    [self performSelectorOnMainThread:@selector(updateDescription:) withObject:results waitUntilDone:NO];
}

- (void) updateEpisodes:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    NSArray *selectedObjects = [PTArrayController selectedObjects];
    if ([selectedObjects count] == 0) {
        return;
    }
    
    // Extract the data
    NSString *showFeeds = [data objectAtIndex:0];
    NSArray *results = [data objectAtIndex:1];
    NSString *copy = [[selectedObjects objectAtIndex:0] valueForKey:@"name"];
    
    // Continue only if the selected show is the same as before
    if ([showFeeds isEqualToString:copy]) {
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

- (void) updatePoster:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    NSArray *selectedObjects = [PTArrayController selectedObjects];
    if ([selectedObjects count] == 0) {
        return;
    }
    
    // Extract the data
    NSString *showName = [data objectAtIndex:0];
    NSImage *poster = [data objectAtIndex:1];
    NSString *copy = [[selectedObjects objectAtIndex:0] valueForKey:@"displayName"];
    
    // Continue only if the selected show is the same as before
    if ([showName isEqualToString:copy]) {
        [showPoster setImage:poster];
        [showPoster display];
    }
}

- (void) updateDescription:(NSArray *)data
{
    // We are back after probably a lot of time, so check carefully if the user has changed the selection
    NSArray *selectedObjects = [PTArrayController selectedObjects];
    if ([selectedObjects count] == 0) {
        return;
    }
    
    // Extract the data
    NSString *showName = [data objectAtIndex:0];
    NSString *description = [data objectAtIndex:1];
    NSString *copy = [[selectedObjects objectAtIndex:0] valueForKey:@"displayName"];
    
    // Continue only if the selected show is the same as before
    if ([showName isEqualToString:copy]) {
        // And finally we can set the description
        if (description != NULL) {
            [showDescription setString: [TSRegexFun replaceHTMLEntitiesInString:description]];
            [showDescription moveToBeginningOfDocument:nil];
        } else {
            [showDescription setString: TSLocalizeString(@"No description was found for this show.")];
        }
        
        // And stop the loading throbber
        [self hideLoadingThrobber];
    }
}

#pragma mark -
#pragma mark Error Window Methods
- (void) errorWindowWithStatusCode:(int)code
{
    NSString *message, *title;
    
    // Add 100 to any error codes if an older show list was found
    if([[PTArrayController content] count] >= 1)
        code = code + 100;
    
    // Switch between each error code:
    // x01 = Website loaded but we couldn't parse a show list from it 
    // x02 = The website did not load or the user is having connection issues
    switch(code) {
        case 101:
            title   = TSLocalizeString(@"An Error Has Occurred");
            message = TSLocalizeString(@"A show list cannot be found. Please try again later or check your internet connection.");
            break;
            
        case 201:
            title   = TSLocalizeString(@"Unable to Update the Show List");
            message = TSLocalizeString(@"A newer show list cannot be found. Using an old show list temporarily.");
            break;
            
        case 102:
            title   = TSLocalizeString(@"An Error Has Occurred");
            message = TSLocalizeString(@"Cannot connect. Please try again later or check your internet connection.");
            break;
            
        case 202:
            title   = TSLocalizeString(@"Unable to Update the Show List");
            message = TSLocalizeString(@"Cannot connect. Using an old show list temporarily.");
            break;
            
        default:
            title   = TSLocalizeString(@"An Error Has Occurred");
            message = TSLocalizeString(@"An unknown error has occurred. Please try again later.");
            break;
    }
    
    if (code < 200)
        errorHasOccurred = YES;
    
    [PTErrorHeader setStringValue: title];
    [PTErrorText setStringValue: message];
    [okayButton setTitle: TSLocalizeString(@"Ok")];
    
    [NSApp beginSheet: PTErrorWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    LogWarning(@"%@",message);
    
    [NSApp endSheet: PTErrorWindow];
    [NSApp runModalForWindow: PTErrorWindow];
}

- (IBAction) closeErrorWindow:(id)sender
{
    [NSApp stopModal];
    [PTErrorWindow orderOut:self];
}

#pragma mark -
#pragma mark Subscription Methods
- (IBAction) subscribeToShow:(id)sender
{
    // To force the view to sort the new subscription
    [SBArrayController setUsesLazyFetching:NO];
    
    // There's probably a better way to do this:
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    
    NSManagedObjectContext *context = [delegateClass managedObjectContext];
    NSManagedObject *newSubscription = [NSEntityDescription insertNewObjectForEntityForName: @"Subscription"
                                                                     inManagedObjectContext: context];
    
    NSArray *selectedShow = [PTArrayController selectedObjects];
    
    // Set the information about the new show
    [newSubscription setValue:[[selectedShow valueForKey:@"displayName"] objectAtIndex:0] forKey:@"name"];
    [newSubscription setValue:[[selectedShow valueForKey:@"sortName"] objectAtIndex:0] forKey:@"sortName"];
    [newSubscription setValue:[[selectedShow valueForKey:@"tvdbID"] objectAtIndex:0] forKey:@"tvdbID"];
    [newSubscription setValue:[[selectedShow valueForKey:@"name"] objectAtIndex:0] forKey:@"url"];
    [newSubscription setValue:[NSDate date] forKey:@"lastDownloaded"];
    [newSubscription setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [newSubscription setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
    
    // Don't do this at home, kids, it's a horrible coding practice.
    // Here until I can figure out why Core Data hates me.
    #if __x86_64__ || __ppc64__
        [SBArrayController addObject:newSubscription];
    #else
        NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
        
        [showDict setValue:[[selectedShow valueForKey:@"displayName"] objectAtIndex:0] forKey:@"name"];
        [showDict setValue:[[selectedShow valueForKey:@"sortName"] objectAtIndex:0] forKey:@"sortName"];
        [showDict setValue:[[selectedShow valueForKey:@"tvdbID"] objectAtIndex:0] forKey:@"tvdbID"];
        [showDict setValue:[[selectedShow valueForKey:@"name"] objectAtIndex:0]
                    forKey:@"url"];
        [showDict setValue:[NSDate date] forKey:@"lastDownloaded"];
        [showDict setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [showDict setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
        
        [SBArrayController addObject:showDict];
        [context insertObject:newSubscription];
    #endif
    
    [delegateClass saveAction];
    
    // Close the modal dialog box
    [self closePresetTorrentsWindow:(id)sender];
    
    [delegateClass release];
    
    // If other episode is selected, start with it
    if ([otherEpisodeButton state]) {
        for (int i = 0; i <= [episodeTableView selectedRow]; i++) {
            NSObject *episode = [[episodeArrayController arrangedObjects] objectAtIndex:i];
            [self startDownloadingURL:[episode valueForKey:@"link"]
                         withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"]
                          andShowName:[selectedShow valueForKey:@"displayName"]];
        }
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

- (BOOL) userIsSubscribedToShow:(NSString*)showName
{
    for (NSManagedObject *subscription in [SBArrayController arrangedObjects]) {
        if ([[subscription valueForKey:@"name"] isEqualToString:showName]) {
            return YES;
        }
    }
    
    return NO;
}

@end
