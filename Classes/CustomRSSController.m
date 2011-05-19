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

#import "CustomRSSController.h"
#import "SubscriptionsDelegate.h"
#import "RegexKitLite.h"


@implementation CustomRSSController

- init
{
    if((self = [super init])) {
        isTranslated = NO;
    }
    
    return self;
}

- (IBAction) displayCustomRSSWindow:(id)sender
{
    // Localize things and prepare the window (only needed the first time)
    if(isTranslated == NO) {
        [rssSectionTitle setStringValue: TSLocalizeString(@"RSS Feed Information:")];
        [filterSectionTitle setStringValue: TSLocalizeString(@"Only download items matching the following rules:")];
        [nameText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Name")]];
        [feedText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"Feed URL")]];
        [tvdbText setStringValue: [NSString stringWithFormat:@"%@:", TSLocalizeString(@"TVDB Link")]];
        [cancelButton setTitle: TSLocalizeString(@"Cancel")];
        [subscribeButton setTitle: TSLocalizeString(@"Subscribe")];
        
        // Localize the headings of the table columns
        [[colHD headerCell] setStringValue: TSLocalizeString(@"HD")];
        [[colName headerCell] setStringValue: TSLocalizeString(@"Episode Name")];
        [[colSeason headerCell] setStringValue: TSLocalizeString(@"Season")];
        [[colEpisode headerCell] setStringValue: TSLocalizeString(@"Episode")];
        [[colDate headerCell] setStringValue: TSLocalizeString(@"Published Date")];
    }
    
    [NSApp beginSheet: CustomRSSWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp runModalForWindow: CustomRSSWindow];
    [NSApp endSheet: CustomRSSWindow];
}

- (IBAction) closeCustomRSSWindow:(id)sender
{   
    [NSApp stopModal];
    [CustomRSSWindow orderOut:self];
}

@end
