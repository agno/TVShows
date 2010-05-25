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
	IBOutlet NSWindow *PTShowList;
	IBOutlet NSArrayController *PTArrayController;
	
	IBOutlet NSWindow *PTErrorWindow;
	IBOutlet NSTextField *PTErrorText;
	IBOutlet NSTextField *PTErrorHeader;
}

- (IBAction) displayPresetTorrentsWindow:(id)sender;
- (IBAction) closePresetTorrentsWindow:(id)sender;
- (void) downloadTorrentShowList;

- (void) displayErrorWindowWithMessage:(NSString *)message;
- (IBAction) closeErrorWindow:(id)sender;

- (IBAction) subscribeToShow:(id)sender;

@end
