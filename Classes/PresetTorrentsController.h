/*
 *	This file is part of the TVShows 2 ("Phoenix") source code.
 *	http://github.com/mattprice/TVShows/
 *
 *	TVShows is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with TVShows. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import <Cocoa/Cocoa.h>


@interface PresetTorrentsController : NSWindowController
{
	Boolean errorHasOccurred;
	Boolean hasDownloadedList;
	IBOutlet NSWindow *PTWindow;
	IBOutlet NSTableView *PTTableView;
	IBOutlet NSArrayController *PTArrayController;
	IBOutlet NSButton *showQuality;
	
	IBOutlet NSWindow *PTErrorWindow;
	IBOutlet NSTextField *PTErrorText;
	IBOutlet NSTextField *PTErrorHeader;
	
	IBOutlet NSArrayController *SBArrayController;
	IBOutlet NSArrayController *episodeArrayController;
	IBOutlet NSTabView *prefTabView;
}

#pragma mark -
#pragma mark Preset Torrents Window
- (IBAction) displayPresetTorrentsWindow:(id)sender;
- (IBAction) closePresetTorrentsWindow:(id)sender;
- (void) downloadTorrentShowList;
- (void) tableViewSelectionDidChange:(NSNotification *)notification;

#pragma mark -
#pragma mark Error Window Methors
- (void) errorWindowWithStatusCode:(int)code;
- (IBAction) closeErrorWindow:(id)sender;

#pragma mark -
#pragma mark Subscription Methods
- (IBAction) subscribeToShow:(id)sender;

@end
