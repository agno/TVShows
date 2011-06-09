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


@interface PresetTorrentsController : NSWindowController
{
    // Preset Torrents window
    Boolean errorHasOccurred;
    Boolean hasDownloadedList;
    Boolean isTranslated;
    
    IBOutlet NSWindow *PTWindow;
    IBOutlet NSTableView *PTTableView;
    IBOutlet NSArrayController *PTArrayController;
    IBOutlet NSSearchField *PTSearchField;
    IBOutlet NSButton *showQuality;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *subscribeButton;
    IBOutlet NSButton *moreInfoButton;
    IBOutlet NSImageView *showPoster;
    IBOutlet NSTextView *showDescription;
    IBOutlet NSScrollView *descriptionView;
    IBOutlet NSTextField *startFromText;
    IBOutlet NSButtonCell *nextAiredButton;
    IBOutlet NSButtonCell *otherEpisodeButton;
    IBOutlet NSTableColumn *colHD;
    IBOutlet NSTableColumn *colName;
    IBOutlet NSTableColumn *colSeason;
    IBOutlet NSTableColumn *colEpisode;
    IBOutlet NSTableColumn *colDate;
    IBOutlet NSProgressIndicator *loading;
    IBOutlet NSTextField *loadingText;
    
    // Error window
    IBOutlet NSWindow *PTErrorWindow;
    IBOutlet NSTextField *PTErrorText;
    IBOutlet NSTextField *PTErrorHeader;
    IBOutlet NSButton *okayButton;
    
    // Selected show arrays
    IBOutlet NSArrayController *SBArrayController;
    IBOutlet NSArrayController *episodeArrayController;
    IBOutlet NSTableView *episodeTableView;
    IBOutlet NSTabView *prefTabView;
}

#pragma mark -
#pragma mark Preset Torrents Window
- (IBAction) displayPresetTorrentsWindow:(id)sender;
- (IBAction) closePresetTorrentsWindow:(id)sender;
- (IBAction) showQualityDidChange:(id)sender;
- (void) sortTorrentShowList;
- (IBAction) reloadShowList:(id)sender;
- (void) downloadTorrentShowList;
- (void) tableViewSelectionDidChange:(NSNotification *)notification;
- (void) resetShowView;
- (void) setDefaultPoster;
- (void) setUserDefinedShowQuality;
- (void) showLoadingThrobber;
- (void) hideLoadingThrobber;
- (IBAction) openMoreInfoURL:(id)sender;
- (IBAction) selectNextAired:(id)sender;
- (IBAction) selectOtherEpisode:(id)sender;

#pragma mark -
#pragma mark Background workers
- (void) setEpisodesForShow:(NSString *)showFeeds;
- (void) setPosterForShow:(NSArray *)arguments;
- (void) setDescriptionForShow:(NSArray *)arguments;
- (void) updateEpisodes:(NSArray *)data;
- (void) updatePoster:(NSArray *)data;
- (void) updateDescription:(NSArray *)data;

#pragma mark -
#pragma mark Error Window Methors
- (void) errorWindowWithStatusCode:(int)code;
- (IBAction) closeErrorWindow:(id)sender;

#pragma mark -
#pragma mark Subscription Methods
- (IBAction) subscribeToShow:(id)sender;
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName andShowName:(NSString *)show;
- (BOOL) userIsSubscribedToShow:(NSString*)showName;

@end
