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

#import <Cocoa/Cocoa.h>


@interface CustomRSSController : NSWindowController
{
    Boolean isTranslated;
    
    IBOutlet NSWindow *CustomRSSWindow;
    
    IBOutlet NSTextField *rssSectionTitle;
    IBOutlet NSTextField *filterSectionTitle;
    IBOutlet NSTextField *nameText;
    IBOutlet NSTextField *feedText;
    IBOutlet NSTextField *tvdbText;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *subscribeButton;
    IBOutlet NSTableColumn *colHD;
    IBOutlet NSTableColumn *colName;
    IBOutlet NSTableColumn *colSeason;
    IBOutlet NSTableColumn *colEpisode;
    IBOutlet NSTableColumn *colDate;
    
    IBOutlet NSArrayController *episodeArrayController;
    IBOutlet NSTableView *episodeTableView;
}

- (IBAction) displayCustomRSSWindow:(id)sender;
- (IBAction) closeCustomRSSWindow:(id)sender;

@end
