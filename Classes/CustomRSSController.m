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

#import "CustomRSSController.h"
#import "TabController.h"

#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "TSRegexFun.h"

#import "RegexKitLite.h"

#define DEFAULT_PREDICATE [NSCompoundPredicate andPredicateWithSubpredicates:\
    [NSArray arrayWithObject:[NSPredicate predicateWithFormat:@"episodeName contains[cd] ' '"]]]

@implementation CustomRSSController

@synthesize selectedShow, subscriptionsDelegate;

- init
{
    if((self = [super init])) {
        isTranslated = NO;
        selectedShow = nil;
        filterRules = DEFAULT_PREDICATE;
        subscriptionsDelegate = [[SubscriptionsDelegate alloc] init];
    }
    
    return self;
}

- (void) localizeWindow
{
    [rssSectionTitle setStringValue: TSLocalizeString(@"RSS Feed Information:")];
    [filterSectionTitle setStringValue: TSLocalizeString(@"Only download items matching the following rules:")];
    [nameText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Name")]];
    [feedText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Feed URLs")]];
    [tvdbText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"TVDB id")]];
    [showQuality setTitle: TSLocalizeString(@"Download in HD")];
    [cancelButton setTitle: TSLocalizeString(@"Cancel")];
    
    // Localize the headings of the table columns
    [[colHD headerCell] setStringValue: TSLocalizeString(@"HD")];
    [[colName headerCell] setStringValue: TSLocalizeString(@"Episode Name")];
    [[colSeason headerCell] setStringValue: TSLocalizeString(@"Season")];
    [[colEpisode headerCell] setStringValue: TSLocalizeString(@"Episode")];
    [[colDate headerCell] setStringValue: TSLocalizeString(@"Published Date")];
    
    isTranslated = YES;
}

- (IBAction) displayCustomRSSWindow:(id)sender
{
    // Localize things (only needed the first time)
    if(isTranslated == NO) {
        [self localizeWindow];
    }
    
    // Just in case localize the subscribe button
    [subscribeButton setTitle: TSLocalizeString(@"Subscribe")];
    selectedShow = nil;
    
    filterRules = DEFAULT_PREDICATE;
    
    [filtersEditor setObjectValue:filterRules];
    [episodeArrayController setFilterPredicate:filterRules];
    
    [self resetShowView];
    
    // At least a feed must be set
    [self addFeed:nil];
    
    [NSApp beginSheet: CustomRSSWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp endSheet: CustomRSSWindow];
    [NSApp runModalForWindow: CustomRSSWindow];
}

- (IBAction) displayEditWindow:(id)sender
{
    // Localize things (only needed the first time)
    if(isTranslated == NO) {
        [self localizeWindow];
    }
    
    // Localize the subscribe button (now called save)
    [subscribeButton setTitle:TSLocalizeString(@"Save")];
    
    // Get the data and close the modal window
    TabController *infoController = [[sender cell] representedObject];
    selectedShow = [infoController selectedShow];
    [infoController closeShowInfoWindow:nil];
    
    // Set the filter rules
    filterRules = [selectedShow valueForKey:@"filters"];
    
    if (filterRules == nil) {
        filterRules = DEFAULT_PREDICATE;
    }
    
    [filtersEditor setObjectValue:filterRules];
    [episodeArrayController setFilterPredicate:filterRules];
    
    // Set the info
    [nameValue setStringValue:[selectedShow valueForKey:@"name"]];
    [tvdbValue setStringValue:[NSString stringWithFormat:@"%@", [selectedShow valueForKey:@"tvdbID"]]];
    [showQuality setState:[[selectedShow valueForKey:@"quality"] intValue]];
    [showQuality setEnabled:YES];
    [subscribeButton setEnabled:YES];
    [self showQualityDidChange:nil];
    
    // Add the feeds
    [feedArrayController removeObjects:[feedArrayController content]];
    for (NSString *feed in [[selectedShow valueForKey:@"url"] componentsSeparatedByString:@"#"]) {
        if (![feed isEqualToString:@""]) {
            [self addFeed:feed];
        }
    }
    
    // Update the episode list
    [self controlTextDidEndEditing:nil];
    
    [NSApp beginSheet: CustomRSSWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp endSheet: CustomRSSWindow];
    [NSApp runModalForWindow: CustomRSSWindow];
}

- (IBAction) addFeed:(id)sender {
    // Set the text
    NSMutableDictionary *newFeed = [NSMutableDictionary dictionary];
    if (sender != nil && [sender isKindOfClass:[NSString class]]) {
        [newFeed setValue:sender forKey:@"url"];
    } else {
        [newFeed setValue:@"http://" forKey:@"url"];
    }
    
    // Add the new row
    [feedArrayController addObject:newFeed];
    
    // Select the last row!
    NSInteger lastRow = [feedsValue numberOfRows]-1;
    [feedsValue selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
    
    // And edit it if the user added a new row
    if (sender == nil || ![sender isKindOfClass:[NSString class]]) {
        [feedsValue editColumn:0 row:lastRow withEvent:nil select:YES];
    }
}

- (IBAction) removeFeed:(id)sender {
    NSInteger selectedRow = [feedsValue selectedRow];
    
    // If something is selected, remove it
    if (selectedRow != -1) {
        [feedArrayController removeObjectAtArrangedObjectIndex:selectedRow];
        
        // If there are no more entries, add one
        if ([[feedArrayController arrangedObjects] count] == 0) {
            [self addFeed:nil];
        } else {
            // Then just select the previous row
            NSInteger previousRow = selectedRow - 1;
            if (previousRow == -1) {
                previousRow = 0;
            }
            
            [feedsValue selectRowIndexes:[NSIndexSet indexSetWithIndex:previousRow] byExtendingSelection:NO];
        }
        
        // Force changes!
        [self controlTextDidEndEditing:nil];
    }
}

- (void) controlTextDidEndEditing:(NSNotification *)notification
{
    // Check if the field that changed was the name or the feed URL
    if (notification != nil && [notification object] == nameValue) {
        NSString *cleanName = [[nameValue stringValue] stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Enable the subscription if there is a name and there are episodes
        if (![cleanName isEqualToString:@""] && [[episodeArrayController content] count] > 0) {
            [subscribeButton setEnabled:YES];
        } else {
            // Otherwise disallow the subscription to this invalid show
            [subscribeButton setEnabled:NO];
        }
    } else {
        NSArray *feeds = [[feedArrayController arrangedObjects] performSelector:@selector(valueForKey:) withObject:@"url"];
        
        // Try to set the new episodes
        [self performSelectorInBackground:@selector(setEpisodesFromRSS:) withObject:feeds];
    }
}

- (void) setEpisodesFromRSS:(NSArray *)feeds
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:feeds,
                        [TSParseXMLFeeds parseEpisodesFromFeeds:feeds
                                                       maxItems:100], nil];
    
    [self performSelectorOnMainThread:@selector(updateEpisodes:) withObject:results waitUntilDone:NO];
    
    [pool drain];
}

- (void) updateEpisodes:(NSArray *)data
{
    // Extract the data
    NSArray *feeds = [data objectAtIndex:0];
    NSArray *results = [data objectAtIndex:1];
    
    // We are back after probably a lot of time, so check carefully if the user has changed the text field
    NSArray *copy = [[feedArrayController arrangedObjects] performSelector:@selector(valueForKey:) withObject:@"url"];
    
    // Continue only if the selected show is the same as before
    if ([feeds isEqualToArray:copy]) {
        [episodeArrayController removeObjects:[episodeArrayController content]];
        if ([results count] == 0) {
            [showQuality setEnabled:NO];
            [subscribeButton setEnabled:NO];
            [nameValue removeAllItems];
        } else {
            [episodeArrayController addObjects:results];
            
            // Check if there are HD episodes, if so enable the "Download in HD" checkbox
            BOOL feedHasHDEpisodes = [TSParseXMLFeeds feedHasHDEpisodes:results];
            
            if (feedHasHDEpisodes) {
                [showQuality setEnabled:YES];
            }
            
            // Update the filter predicate to only display the correct quality.
            [self showQualityDidChange:nil];
            
            // Allow the subscription!
            [subscribeButton setEnabled:YES];
            
            // Set the possible names for autocompletion
            [self setPossibleNamesFromFeed];
        }
    }
}

- (void) setPossibleNamesFromFeed
{
    // Remove the previous data
    [nameValue removeAllItems];
    
    NSMutableSet *shows = [[[NSMutableSet alloc] init] autorelease];
    
    // Add every show name to a set (to avoid repetitions)
    for (NSDictionary *episode in [episodeArrayController content]) {
        [shows addObject:[TSRegexFun parseShowFromTitle:[episode valueForKey:@"episodeName"]]];
    }
    
    // And finally update the object!
    [nameValue addItemsWithObjectValues:[shows allObjects]];
}

- (void) resetShowView
{
    [episodeArrayController removeObjects:[episodeArrayController content]];
    [feedArrayController removeObjects:[feedArrayController content]];
    [nameValue setStringValue:@""];
    [tvdbValue setStringValue:@""];
    [self setUserDefinedShowQuality];
    [showQuality setEnabled:NO];
    [subscribeButton setEnabled:NO];
}

- (void) setUserDefinedShowQuality {
    [showQuality setState: [TSUserDefaults getBoolFromKey:@"AutoSelectHDVersion" withDefault:1]];
}

- (IBAction) showQualityDidChange:(id)sender
{
    // Mix HD option with the filters
    if ([showQuality state]) {
        [episodeArrayController setFilterPredicate:
         [NSCompoundPredicate andPredicateWithSubpredicates:
          [NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"isHD == '1'"], filterRules, nil]]];
    } else if (![showQuality state]) {
        [episodeArrayController setFilterPredicate:
         [NSCompoundPredicate andPredicateWithSubpredicates:
          [NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"isHD == '0'"], filterRules, nil]]];
    }
}

- (IBAction) closeCustomRSSWindow:(id)sender
{
    [episodeArrayController setFilterPredicate:nil];
    [NSApp stopModal];
    [CustomRSSWindow orderOut:self];
}

#pragma mark -
#pragma mark Subscription Methods
- (IBAction) subscribeToShow:(id)sender
{
    // Close the modal dialog box
    [self closeCustomRSSWindow:(id)sender];
    
    // To force the view to sort the new subscription
    [SBArrayController setUsesLazyFetching:NO];
    
    // Calculate the sort name, i.e. remove "The"
    NSString *sortName = [[nameValue stringValue] stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]"
                                                                           withString:@""];
    
    // Build the url for storage (joining them with #)
    NSString *url = [[[feedArrayController arrangedObjects] performSelector:@selector(valueForKey:)
                                                                 withObject:@"url"]
                     componentsJoinedByString:@"#"];
    
    if (selectedShow != nil) {
        NSManagedObject *selectedShowObj = [[subscriptionsDelegate managedObjectContext] objectWithID:[selectedShow objectID]];
        
        // Update the per-show preferences
        [selectedShow setValue:[nameValue stringValue] forKey:@"name"];
        [selectedShow setValue:sortName forKey:@"sortName"];
        [selectedShow setValue:url forKey:@"url"];
        [selectedShow setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [selectedShow setValue:[NSDate date] forKey:@"lastDownloaded"];
        [selectedShow setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [selectedShow setValue:filterRules forKey:@"filters"];
        [selectedShowObj setValue:[nameValue stringValue] forKey:@"name"];
        [selectedShowObj setValue:sortName forKey:@"sortName"];
        [selectedShowObj setValue:url forKey:@"url"];
        [selectedShowObj setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [selectedShowObj setValue:[NSDate date] forKey:@"lastDownloaded"];
        [selectedShowObj setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [selectedShowObj setValue:filterRules forKey:@"filters"];
    } else {
        NSManagedObject *newSubscription = [NSEntityDescription insertNewObjectForEntityForName:@"Subscription"
                                                                         inManagedObjectContext:[subscriptionsDelegate managedObjectContext]];
        
        // Set the information about the new show
        [newSubscription setValue:[nameValue stringValue] forKey:@"name"];
        [newSubscription setValue:sortName forKey:@"sortName"];
        [newSubscription setValue:url forKey:@"url"];
        [newSubscription setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [newSubscription setValue:[NSDate date] forKey:@"lastDownloaded"];
        [newSubscription setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [newSubscription setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
        [newSubscription setValue:filterRules forKey:@"filters"];
        
        [SBArrayController addObject:newSubscription];
    }
    
    // Be sure to process pending changes before saving or it won't save correctly.
    [[subscriptionsDelegate managedObjectContext] processPendingChanges];
    [subscriptionsDelegate saveAction];
}

- (void)dealloc
{
    [filterRules release];
    [super dealloc];
}

@end
