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
#import <Sparkle/SUUpdater.h>
#import <Growl/GrowlApplicationBridge.h>


@interface TVShowsHelper : NSObject <GrowlApplicationBridgeDelegate>
{
    NSThread *checkerThread;
    NSTimer *checkerLoop;
    NSData *TVShowsHelperIcon;
    IBOutlet NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *lastUpdateItem;
    IBOutlet NSMenuItem *checkShowsItem;
    IBOutlet NSMenuItem *subscriptionsItem;
    IBOutlet NSMenuItem *preferencesItem;
    IBOutlet NSMenuItem *feedbackItem;
    IBOutlet NSMenuItem *aboutItem;
    IBOutlet NSMenuItem *disableItem;
}

@property (retain) NSTimer *checkerLoop;
@property (retain) NSData *TVShowsHelperIcon;

- (void) runLoop;
- (void) checkAllShows;
- (void) checkForNewEpisodes:(NSArray *)show;

#pragma mark -
#pragma mark Status Menu

- (void) activateStatusMenu;
- (void) updateLastCheckedItem;
- (IBAction) checkNow:(id)sender;
- (IBAction) openApplication:(id)sender;
- (IBAction) showSubscriptions:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) showFeedback:(id)sender;
- (IBAction) quitHelper:(id)sender;

#pragma mark -
#pragma mark Download Methods
- (void) startDownloadingURL:(NSString *)url withFileName:(NSString *)fileName showInfo:(NSArray *)show;

#pragma mark -
#pragma mark Sparkle Delegate Methods
- (void) updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update;

@end
