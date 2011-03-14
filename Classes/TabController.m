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

#import "AppInfoConstants.h"
#import "TabController.h"

#import "SubscriptionsDelegate.h"

#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"

#import "TheTVDB.h"


@implementation TabController

@synthesize selectedShow;

- (void) awakeFromNib
{
    // Set displayed version information
    NSString *bundleVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary] 
                               valueForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
                              valueForKey:@"CFBundleVersion"];
    NSString *buildDate = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
                           valueForKey:@"TSBundleBuildDate"];
    
    [sidebarHeader setStringValue:@"TVShows 2"];
    [sidebarVersionText setStringValue: [NSString stringWithFormat:@"%@ (r%@)", bundleVersion, buildVersion]];
    [sidebarDateText setStringValue: buildDate];
    
    [aboutTabVersionText setStringValue: [NSString stringWithFormat:@"TVShows %@ (%@)", bundleVersion, buildVersion]];
    
    // Localize everything
    [[prefTabView tabViewItemAtIndex:0] setLabel: TSLocalizeString(@"Subscriptions")];
    [[prefTabView tabViewItemAtIndex:1] setLabel: TSLocalizeString(@"Preferences")];
    [[prefTabView tabViewItemAtIndex:2] setLabel: TSLocalizeString(@"About")];
    
    [feedbackButton setTitle: TSLocalizeString(@"Submit Feedback")];
    [gettingStartedText setStringValue: TSLocalizeString(@"Please choose one of the following actions:")];
    
    [optionOneTitle setStringValue: TSLocalizeString(@"Select a preset show from showRSS")];
    [optionOneDesc setStringValue: TSLocalizeString(@"Choose this to download torrent files from a list of preset shows.")];
    
    [optionTwoTitle setStringValue: TSLocalizeString(@"Add a show from NZBs.org")];
    [optionTwoDesc setStringValue: TSLocalizeString(@"Choose this to download Usenet files using your NZBs.org account.")];
    
    [optionThreeTitle setStringValue: TSLocalizeString(@"Add a custom RSS source")];
    [optionThreeDesc setStringValue: TSLocalizeString(@"Choose this to input your own RSS feed.")];
    
    // Sort the subscription list and draw the About box
    [self sortSubscriptionList];
    [self drawAboutBox];
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSRect  tabFrame;
    int newWinHeight;
    
    tabFrame = [[tabView window] frame];
    
    // newWinHeight should be equal to the wanted window size (in Interface Builder) + 54 (title bar height)
    if ([[tabViewItem identifier] isEqualTo:@"tabItemPreferences"]) {
        newWinHeight = 475;
        
    } else if ([[tabViewItem identifier] isEqualTo:@"tabItemSubscriptions"]) {
        newWinHeight = 570;
        
    }  else if ([[tabViewItem identifier] isEqualTo:@"tabItemAbout"]) {
        newWinHeight = 422;
        
    } else {
        newWinHeight = 429;
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

- (IBAction) openTwitter:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: TVShowsTwitter]];
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
#pragma mark Subscriptions Tab
- (IBAction) displayShowInfoWindow:(id)sender
{
    selectedShow = [[[sender cell] representedObject] representedObject];
    
    // Set up the date formatter
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // Set the displayed values
    [showName setStringValue: [selectedShow valueForKey:@"name"]];
    [showStatus setStringValue: [TheTVDB getShowStatus:[selectedShow valueForKey:@"name"]]];
    [showLastDownloaded setStringValue: [dateFormatter stringFromDate:[selectedShow valueForKey:@"lastDownloaded"]]];
    [showQuality setTitle: TSLocalizeString(@"Download in HD")];
    [showQuality setState: [[selectedShow valueForKey:@"quality"] intValue]];
    [showIsEnabled setTitle: TSLocalizeString(@"Enable downloading new episodes")];
    [showIsEnabled setState: [[selectedShow valueForKey:@"isEnabled"] boolValue]];
    
    // Localize everything else
    [statusTitle setStringValue: TSLocalizeString(@"Status")];
    [lastAiredTitle setStringValue: TSLocalizeString(@"Last Aired")];
    [lastDownloadedTitle setStringValue: TSLocalizeString(@"Last Downloaded")];
    [infoBoxTitle setTitle: TSLocalizeString(@"Info")];
    [prefBoxTitle setTitle: TSLocalizeString(@"Preferences")];
    [closeButton setTitle: TSLocalizeString(@"Close")];
//  [unsubscribeButton setTitle: TSLocalizeString(@"Unsubscribe")];
    
    // Reset the Episode Array Controller and grab the new list of episodes
    [[episodeArrayController content] removeAllObjects];
    [episodeArrayController addObjects:[TSParseXMLFeeds parseEpisodesFromFeed:[selectedShow valueForKey:@"url"]
                                                                     maxItems:10]];
    
    // Display the show poster now that it's been resized.
    [showPoster setImage: [TheTVDB getPosterForShow:[selectedShow valueForKey:@"name"]
                                         withHeight:184
                                          withWidth:127] ];
    
    // Update the filter predicate to only display the correct quality.
    // [self showQualityDidChange:nil];
    
    [NSApp beginSheet: showInfoWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp runModalForWindow: showInfoWindow];
    [NSApp endSheet: showInfoWindow];
}

- (IBAction) closeShowInfoWindow:(id)sender
{   
    // NSManagedContext objectWithID is required for it to save changes to the disk.
    // We also need to update the original selectedShow NSManagedObject so that the
    // interface displays any changes when the window is opened multiple times a session.
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    NSManagedObject *selectedShowObj = [[delegateClass managedObjectContext] objectWithID:[selectedShow objectID]];
    
    // Update the per-show preferences
    [selectedShow setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [selectedShow setValue:[NSNumber numberWithBool:[showIsEnabled state]] forKey:@"isEnabled"];
    [selectedShowObj setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
    [selectedShowObj setValue:[NSNumber numberWithBool:[showIsEnabled state]] forKey:@"isEnabled"];
    
    // Be sure to process pending changes before saving or it won't save correctly.
    [[delegateClass managedObjectContext] processPendingChanges];
    [delegateClass saveAction];
    [delegateClass release];
    
    // Reset the selected show and close the window
    selectedShow = nil;
    [NSApp stopModal];
    [showInfoWindow orderOut: self];
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

- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName
{
    // Method copied from TVShowsHelper.m
    NSData *fileContents = [NSData dataWithContentsOfURL: [NSURL URLWithString:url]];
    NSString *saveLocation = [[TSUserDefaults getStringFromKey:@"downloadFolder"] stringByAppendingPathComponent:fileName];
    
    [fileContents writeToFile:saveLocation atomically:YES];
    
    if (!fileContents) {
        TVLog(@"Unable to download file: %@",url);
    }
    
    // Check to see if the user wants to automatically open new downloads
    if([TSUserDefaults getBoolFromKey:@"AutoOpenDownloadedFiles" withDefault:1]) {
        [[NSWorkspace sharedWorkspace] openFile:saveLocation withApplication:nil andDeactivate:NO];
    }
}

- (BOOL) tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    // Check to see whether or not this is the GET button or not.
    // If it's not, then return YES for shouldSelectRow.
    BOOL result = YES;
    
    // Which column and row was clicked?
    NSInteger clickedCol = [episodeTableView clickedColumn];
    NSInteger clickedRow = [episodeTableView clickedRow];
    
    if (clickedRow >= 0 && clickedCol >= 0) {
        // Grab information about the clicked cell.
        NSCell *cell = [episodeTableView preparedCellAtColumn:clickedCol row:clickedRow];
        
        // If the cell is an NSButtonCell and it's enabled...
        if ([cell isKindOfClass:[NSButtonCell class]] && [cell isEnabled]) {
            // Don't select the row
            result = NO;
            
            // This currently only returns a Torrent file and should eventually regex
            // out the actual file extension of the item we're downloading.
            NSObject *episode = [[episodeArrayController content] objectAtIndex:clickedRow];
            [self startDownloadingURL:[episode valueForKey:@"link"]
                         withFileName:[[episode valueForKey:@"episodeName"] stringByAppendingString:@".torrent"] ];
        }           
    }
    
    return result;
}

- (void) sortSubscriptionList
{
    NSSortDescriptor *SBSortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"sortName"
                                                                     ascending: YES 
                                                                      selector: @selector(caseInsensitiveCompare:)];
    [SBArrayController setSortDescriptors:[NSArray arrayWithObject:SBSortDescriptor]];
    
    [SBSortDescriptor release];
}

- (IBAction) unsubscribeFromShow:(id)sender
{
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    
    // I don't understand why I have to remove the object from both locations
    // but it works so I won't question it.
    [SBArrayController removeObject:selectedShow];
    [[delegateClass managedObjectContext] deleteObject:selectedShow];
    
    [self closeShowInfoWindow:(id)sender];
    
    [delegateClass saveAction];
    [delegateClass release];
}


- (void) dealloc
{
    [selectedShow release];
    [super dealloc];
}

@end
