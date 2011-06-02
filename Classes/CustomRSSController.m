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

#import "SubscriptionsDelegate.h"

#import "TSParseXMLFeeds.h"
#import "TSUserDefaults.h"
#import "TSRegexFun.h"

#import "RegexKitLite.h"

#define DEFAULT_PREDICATE [NSCompoundPredicate andPredicateWithSubpredicates:\
    [NSArray arrayWithObject:[NSPredicate predicateWithFormat:@"episodeName contains[cd] ' '"]]]

@implementation CustomRSSController

@synthesize selectedShow;

- init
{
    if((self = [super init])) {
        isTranslated = NO;
        selectedShow = nil;
        filterRules = DEFAULT_PREDICATE;
    }
    
    return self;
}

- (void) localizeWindow
{
    [rssSectionTitle setStringValue: TSLocalizeString(@"RSS Feed Information:")];
    [filterSectionTitle setStringValue: TSLocalizeString(@"Only download items matching the following rules:")];
    [nameText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Name")]];
    [feedText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Feed URL")]];
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
    [subscribeButton setTitle: TSLocalizeString(@"Save")];
    
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
    [feedValue setStringValue:[selectedShow valueForKey:@"url"]];
    [nameValue setStringValue:[selectedShow valueForKey:@"name"]];
    [tvdbValue setStringValue:[NSString stringWithFormat:@"%@", [selectedShow valueForKey:@"tvdbID"]]];
    [showQuality setState:[[selectedShow valueForKey:@"quality"] intValue]];
    [showQuality setEnabled:YES];
    [subscribeButton setEnabled:YES];
    [self showQualityDidChange:nil];
    
    [NSApp beginSheet: CustomRSSWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp endSheet: CustomRSSWindow];
    [NSApp runModalForWindow: CustomRSSWindow];
}

- (void) controlTextDidEndEditing:(NSNotification *)notification
{
    // Check if the field that changed was the name or the feed URL
    if ([notification object] == nameValue) {
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
        NSString *cleanFeed = [[feedValue stringValue] stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Try to set the new episodes
        if ([NSURL URLWithString:cleanFeed] != nil) {
            [self performSelectorInBackground:@selector(setEpisodesFromRSS:) withObject:cleanFeed];
            return;
        } else {
            // Otherwise disallow the subscription to this invalid show
            [showQuality setEnabled:NO];
            [subscribeButton setEnabled:NO];
        }
    }
}

- (void) setEpisodesFromRSS:(NSString *)feedURL
{
    // Now we can trigger the time-expensive task
    NSArray *results = [NSArray arrayWithObjects:feedURL,
                        [TSParseXMLFeeds parseEpisodesFromFeeds:[feedURL componentsSeparatedByString:@"#"]
                                                       maxItems:100], nil];
    
    [self performSelectorOnMainThread:@selector(updateEpisodes:) withObject:results waitUntilDone:NO];
}

- (void) updateEpisodes:(NSArray *)data
{
    // Extract the data
    NSString *feedURL = [data objectAtIndex:0];
    NSArray *results = [data objectAtIndex:1];
    
    // We are back after probably a lot of time, so check carefully if the user has changed the text field
    NSString *cleanFeed = [[feedValue stringValue] stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Continue only if the selected show is the same as before
    if ([feedURL isEqualToString:cleanFeed]) {
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
    [feedValue setStringValue:@""];
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
    // To force the view to sort the new subscription
    [SBArrayController setUsesLazyFetching:NO];
    
    // There's probably a better way to do this:
    id delegateClass = [[[SubscriptionsDelegate class] alloc] init];
    NSManagedObjectContext *context = [delegateClass managedObjectContext];
    
    // Calculate the sort name, i.e. remove "The"
    NSString *sortName = [[nameValue stringValue] stringByReplacingOccurrencesOfRegex:@"^The[[:space:]]"
                                                                           withString:@""];
    
    if (selectedShow != nil) {
        NSManagedObject *selectedShowObj = [context objectWithID:[selectedShow objectID]];
        
        // Update the per-show preferences
        [selectedShow setValue:[nameValue stringValue] forKey:@"name"];
        [selectedShow setValue:sortName forKey:@"sortName"];
        [selectedShow setValue:[feedValue stringValue] forKey:@"url"];
        [selectedShow setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [selectedShow setValue:[NSDate date] forKey:@"lastDownloaded"];
        [selectedShow setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [selectedShow setValue:filterRules forKey:@"filters"];
        [selectedShowObj setValue:[nameValue stringValue] forKey:@"name"];
        [selectedShowObj setValue:sortName forKey:@"sortName"];
        [selectedShowObj setValue:[feedValue stringValue] forKey:@"url"];
        [selectedShowObj setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [selectedShowObj setValue:[NSDate date] forKey:@"lastDownloaded"];
        [selectedShowObj setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [selectedShowObj setValue:filterRules forKey:@"filters"];
    } else {
        NSManagedObject *newSubscription = [NSEntityDescription insertNewObjectForEntityForName:@"Subscription"
                                                                         inManagedObjectContext:context];
        
        // Set the information about the new show
        [newSubscription setValue:[nameValue stringValue] forKey:@"name"];
        [newSubscription setValue:sortName forKey:@"sortName"];
        [newSubscription setValue:[feedValue stringValue] forKey:@"url"];
        [newSubscription setValue:[NSNumber numberWithInt:[[tvdbValue stringValue] intValue]] forKey:@"tvdbID"];
        [newSubscription setValue:[NSDate date] forKey:@"lastDownloaded"];
        [newSubscription setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [newSubscription setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
        [newSubscription setValue:filterRules forKey:@"filters"];
        
        // Don't do this at home, kids, it's a horrible coding practice.
        // Here until I can figure out why Core Data hates me.
#if __x86_64__ || __ppc64__
        [SBArrayController addObject:newSubscription];
#else
        NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
        
        [showDict setValue:[nameValue stringValue] forKey:@"name"];
        [showDict setValue:sortName forKey:@"sortName"];
        [showDict setValue:[feedValue stringValue] forKey:@"url"];
        [showDict setValue:[NSDate date] forKey:@"lastDownloaded"];
        [showDict setValue:[NSNumber numberWithInt:[showQuality state]] forKey:@"quality"];
        [showDict setValue:[NSNumber numberWithBool:YES] forKey:@"isEnabled"];
        
        [SBArrayController addObject:showDict];
        [context insertObject:newSubscription];
#endif
    }
    
    // Be sure to process pending changes before saving or it won't save correctly.
    [[delegateClass managedObjectContext] processPendingChanges];
    [delegateClass saveAction];
    
    // Close the modal dialog box
    [self closeCustomRSSWindow:(id)sender];
    
    [delegateClass release];
}

- (void)dealloc
{
    [filterRules release];
    [super dealloc];
}

@end
