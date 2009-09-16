/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#import <Cocoa/Cocoa.h>
#import "Helper.h"

@interface Controller : NSObject {

	// Experimental
	NSArray *tableItems;
	IBOutlet NSView *mainView;
	IBOutlet NSView *preferencesView;
	IBOutlet NSTableColumn *mainColumn;
	
	NSArray *qualities;
	NSDictionary *shows;
	Helper *h;
	NSArray *details;
	
	// Main window
	IBOutlet NSWindow *mainWindow;
	NSToolbar *mainToolbar;
	IBOutlet NSView *searchToolbarItemView;
	IBOutlet NSSearchField *searchToolbarItemTextField;
	IBOutlet NSArrayController *showsController;
	IBOutlet NSUserDefaultsController *defaultsController;
	IBOutlet NSTableView *showsTable;

	// Preferences window
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSButton *enableDisableButton;
	IBOutlet NSTextField *enableDisableLabel;
	
	// Progress panel
	IBOutlet NSWindow *progressPanel;
	IBOutlet NSProgressIndicator *progressPanelIndicator;
	
	// Details sheet
	IBOutlet NSWindow *detailsSheet;
	IBOutlet NSProgressIndicator *detailsProgressIndicator;
	IBOutlet NSScrollView *detailsTable;
	IBOutlet NSButton *detailsOKButton;
	IBOutlet NSArrayController *detailsController;
	IBOutlet NSTextField *detailsErrorText;
	int retries;
	
	// Download show
	NSPipe *downloadShowListPipe;
	NSTask *downloadShowListTask;
	NSTask *getShowDetailsTask;
	NSPipe *getShowDetailsPipe;
	int currentShowIndex;
	NSDictionary *currentShow;
	
}

// Toolbar
- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;

// Download Show List
- (IBAction)downloadShowList;
- (void)downloadShowListDidFinish: (NSNotification *)notification;

// Setters/getters
- (NSArray *)qualities;
- (void)setQualities: (NSArray *)someQualities;
- (NSDictionary *)shows;
- (void)setShows: (NSDictionary *)someShows;
- (NSArray *)details;
- (void)setDetails: (NSArray *)someDetails;

// Preferences
- (IBAction)openPreferences: (id)sender;
- (IBAction)closePreferences: (id)sender;
- (IBAction)enableDisable: (id)sender;
- (IBAction)changeSaveFolder: (id)sender;

// Show list
- (IBAction)subscribe: (id)sender;
- (IBAction)cancelSubscription: (id)sender;
- (IBAction)okSubscription: (id)sender;
- (IBAction)okSubscriptionToNextAiredEpisode: (id)sender;
- (void)getShowDetailsDidFinish: (NSNotification *)notification;
- (void) tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)row;
- (IBAction)filterShows: (id)sender;

// Launchd
- (void)saveLaunchdPlist;
- (void)unloadFromLaunchd;
- (void)loadIntoLaunchd;

// Menu handlers
- (IBAction)find: (id)sender;
- (IBAction)help: (id)sender;
- (IBAction)sendFeedback: (id)sender;

// Misc
- (void)applicationWillTerminate: (NSNotification *)aNotification;
- (IBAction)test: (id)sender;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (void)checkForBittorrentClient;
- (void)checkForBittorrentClientAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end
