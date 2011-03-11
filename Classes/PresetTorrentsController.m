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

#pragma mark Define Macros

#define ShowListHostname            @"showrss.karmorra.info"
#define ShowListURL                 @"http://showrss.karmorra.info/?cs=feeds"
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
    }
    
    return self;
}

- (IBAction) displayPresetTorrentsWindow:(id)sender
{
    errorHasOccurred = NO;
    
    // Only download the show list once per session
    if(hasDownloadedList == NO) {
        [self downloadTorrentShowList];
                
        // Sort the shows alphabetically
        NSSortDescriptor *PTSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"sortName"
                                                                         ascending: YES 
                                                                          selector: @selector(caseInsensitiveCompare:)];
        [PTArrayController setSortDescriptors:[NSArray arrayWithObject:PTSortDescriptor]];
        
        [PTSortDescriptor release];
    }
    
    // Continue if no error occurred when downloading the show list
    if(errorHasOccurred == NO) {
        // Reset the selection and search bar each time they open the window
        [[[PTSearchField cell] cancelButtonCell] performClick:self];
        [PTArrayController setSelectionIndex:0];
        
        // Setup the default video quality
        [showQuality setTitle: TSLocalizeString(@"Download in HD")];
        [showQuality setState: 1];
        
        // Localize the other buttons
        [cancelButton setTitle: TSLocalizeString(@"Cancel")];
        [subscribeButton setTitle: TSLocalizeString(@"Subscribe")];
        [tvcomButton setTitle: TSLocalizeString(@"View on TV.com")];
//      [ratingsTitle setStringValue: TSLocalizeString(@"Rating:")];
        
        // Localize the headings of the table columns
//      [[colHD headerCell] setStringValue: TSLocalizeString(@"HD")];
//      [[colName headerCell] setStringValue: TSLocalizeString(@"Episode Name")];
//      [[colSeason headerCell] setStringValue: TSLocalizeString(@"Season")];
//      [[colEpisode headerCell] setStringValue: TSLocalizeString(@"Episode")];
//      [[colDate headerCell] setStringValue: TSLocalizeString(@"Published Date")];
        
        [NSApp beginSheet: PTWindow
           modalForWindow: [[NSApplication sharedApplication] mainWindow]
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
        
        [NSApp endSheet: PTWindow];
        [NSApp runModalForWindow: PTWindow];
    }
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
//      [episodeArrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"isHD == '1'"]];
    } else if (![showQuality state]) {
        // Is not HD and HD is not enabled.
//      [episodeArrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"isHD == '0'"]];
    }
}

- (void) downloadTorrentShowList
{
    // There's probably a better way to do this:
    id delegateClass = [[[PresetShowsDelegate class] alloc] init];
    
    NSString *displayName, *sortName;
    int showrssID;
    
    // This rest of this method is extremely messy but it works for the time being
    // Feel free to improve it if you find a way
    
    // Download the page containing the show list
    NSURL *showListURL = [NSURL URLWithString:ShowListURL];
    NSString *showListContents = [[[NSString alloc] initWithContentsOfURL: showListURL
                                                                 encoding: NSUTF8StringEncoding
                                                                    error: NULL] autorelease];
    
    // Be sure to only search for shows between the <select> tags
    // Warning about never being read can be safely ignored
    NSArray *selectTags = [showListContents componentsMatchedByRegex:SelectTagsRegex];
    
    // Check to make sure the website is loading and that selectTags isn't NULL
    if ([WebsiteFunctions canConnectToHostname:ShowListHostname] && [selectTags count] == 0) {
        [self errorWindowWithStatusCode:101];
    }
    else if (![WebsiteFunctions canConnectToHostname:ShowListHostname]) {
        [self errorWindowWithStatusCode:102];
    } else {
        showListContents = [selectTags objectAtIndex:0];
        
        // Reset the existing show list before continuing. In a perfect world we'd
        // only be adding shows that didn't already exist, instead of deleting
        // everything and starting from scratch.
        [delegateClass resetPresetShows];
        [[PTArrayController content] removeAllObjects];
        
        NSManagedObjectContext *context = [delegateClass managedObjectContext];
        
        // Extract the show name and number from the <option> tags
        NSArray *optionTags = [showListContents componentsMatchedByRegex:OptionTagsRegex];
        
        for(NSString *showInformation in optionTags) {
            // Yes, it's extremely messy to be adding it to the array controller and to
            // the MOC separately but I don't have time to debug the issue with 32bit.
            NSManagedObject *showObj = [NSEntityDescription insertNewObjectForEntityForName: @"Show"
                                                                     inManagedObjectContext: context];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            
            // I hate having to search for each valute separately but I can't seem to figure out any other way
            displayName = [[[showInformation componentsMatchedByRegex:DisplayNameRegex] objectAtIndex:0]
                           stringByReplacingOccurrencesOfRegex:SeparatorBetweenNameAndID withString:@""];
            sortName = [displayName stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]" withString:@""];
            showrssID = [[[showInformation componentsMatchedByRegex:RSSIDRegex] objectAtIndex:0] intValue];
            
            [showObj setValue:displayName forKey:@"displayName"];
            [showObj setValue:displayName forKey:@"name"];
            [showObj setValue:sortName forKey:@"sortName"];
            [showObj setValue:[NSNumber numberWithInt:showrssID] forKey:@"showrssID"];
            [showObj setValue:[NSDate date] forKey:@"dateAdded"];
            
            [showDict setValue:displayName forKey:@"displayName"];
            [showDict setValue:displayName forKey:@"name"];
            [showDict setValue:sortName forKey:@"sortName"];
            [showDict setValue:[NSNumber numberWithInt:showrssID] forKey:@"showrssID"];
            [showDict setValue:[NSDate date] forKey:@"dateAdded"];
            
            [PTArrayController addObject:showDict];
            [context insertObject:showObj];
        }
        
        hasDownloadedList = YES;
        
        [context processPendingChanges];
        [delegateClass saveAction];
    }
    
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
        
        // No matter what, reset the Episode Array Controller.
        [[episodeArrayController content] removeAllObjects];
        
        // Make sure we were able to correctly set a selection before continuing,
        // or else searching and the scrollbar will fail.
        if ( ([PTTableView selectedRow] > -1) || ([PTTableView selectedRow] == 0) && ([PTTableView selectedRow]) ) {
            
            // Grab the list of episodes
            NSString *selectedShowURL = [NSString stringWithFormat:@"http://showrss.karmorra.info/feeds/%@.rss",
                                         [[[PTArrayController selectedObjects] valueForKey:@"showrssID"] objectAtIndex:0]];
            [episodeArrayController addObjects:[TSParseXMLFeeds parseEpisodesFromFeed:selectedShowURL
                                                                             maxItems:10]];
            
            // Grab the show description
            NSString *description = [TheTVDB getValueForKey:@"Overview" andShow:
                                     [[[PTArrayController selectedObjects] valueForKey:@"name"] objectAtIndex:0]];
            if (description != NULL) {
                [showDescription setString: [TSRegexFun replaceHTMLEntitiesInString:description]];
            } else {
                [showDescription setString: @"No description was found for this show."];
            }


            
            // Display the show poster now that it's been resized.
            [showPoster setImage: [TheTVDB getPosterForShow:[[[PTArrayController selectedObjects] valueForKey:@"name"] objectAtIndex:0]
                                                 withHeight:187
                                                  withWidth:129] ];
            
            // Update the filter predicate to only display the correct quality.
            // [self showQualityDidChange:nil];
        }
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
    
    TVLog(@"%@",message);
    
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
    // There's probably a better way to do this:
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    
    NSManagedObjectContext *context = [delegateClass managedObjectContext];
    NSManagedObject *newSubscription = [NSEntityDescription insertNewObjectForEntityForName: @"Subscription"
                                                                     inManagedObjectContext: context];
    
    NSArray *selectedShow = [PTArrayController selectedObjects];

    // Set the information about the new show
    [newSubscription setValue:[[selectedShow valueForKey:@"displayName"] objectAtIndex:0] forKey:@"name"];
    [newSubscription setValue:[[selectedShow valueForKey:@"sortName"] objectAtIndex:0] forKey:@"sortName"];
    [newSubscription setValue:[NSString stringWithFormat:@"http://showrss.karmorra.info/feeds/%@.rss",
                               [[selectedShow valueForKey:@"showrssID"] objectAtIndex:0]]
                       forKey:@"url"];
    [newSubscription setValue:[NSDate date] forKey:@"lastDownloaded"];
    [newSubscription setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [newSubscription setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
    
    [SBArrayController addObject:newSubscription];
    [delegateClass saveAction];
    
    // Close the modal dialog box
    [prefTabView selectTabViewItemWithIdentifier:@"tabItemSubscriptions"];
    [self closePresetTorrentsWindow:(id)sender];

    [delegateClass release];
}

@end
