/*
 This file is part of the TVShows source code.
 http://github.com/mattprice/TVShows

 TVShows is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
*/

#import "Controller.h"
#import "ValueTransformers.h"
#import "PFMoveApplication.h"

// Toolbar
#define ToolbarFilter			@"Filter"
#define ToolbarPreferences		@"Preferences"
#define ToolbarUpdateShowList	@"UpdateShowList"

// Shows properties
#define ShowsVersion			@"Version"
#define ShowsLatestVersion		@"1.1"
#define ShowsShows				@"Shows"

// Show properties
#define ShowHumanName			@"HumanName"
#define ShowExactName			@"ExactName"
#define ShowLinks				@"Links"
#define ShowEpisode				@"Episode"
#define	ShowSeason				@"Season"
#define ShowSubscribed			@"Subscribed"
#define ShowDate				@"Date"
#define ShowTitle				@"Title"
#define ShowType				@"Type"
#define ShowTime				@"Time"

// Types of shows
#define TypeSeasonEpisode		@"SeasonEpisodeType"
#define TypeDate				@"DateType"		
#define TypeTime				@"TimeType"

// Details keys
#define DetailsEpisodes			@"Episodes"

// Preferences keys
#define TVShowsIsEnabled			@"IsEnabled"
#define TVShowsAutomaticallyOpen	@"AutomaticallyOpen"
#define TVShowsCheckDelay			@"CheckDelay"
#define TVShowsQuality				@"Quality"
#define TVShowsTorrentFolder		@"TorrentFolder"
#define TVShowsScriptInstalledVersion @"ScriptVersion"

// Ruby scripts
#define RubyDownloadShowList		@"DownloadShowList"
#define RubyGetShowDetails			@"GetShowDetails"

// Misc
#define TVShowsURL					@"http://deathtobunnies.com/tvshows/"
#define TVShowsFeedbackURL			@"http://github.com/mattprice/TVShows/issues/"
#define TransmissionURL				@"http://www.transmissionbt.com/"

@implementation Controller

#pragma mark -
#pragma mark Init / AwakeFromNib

- (id)init
{
	self = [super init];
	if (self != nil) {
		
		// Experimental
		/*
		tableItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:@"GENERAL",@"Label",[NSNumber numberWithBool:YES],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Preferences",@"Label",[NSNumber numberWithBool:NO],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"AVAILABLE SHOWS",@"Label",[NSNumber numberWithBool:YES],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"The Shield",@"Label",[NSNumber numberWithBool:NO],@"IsHeading",nil],
			nil];
		*/
		
		h = [[Helper alloc] init];
		[self unloadFromLaunchd];
		
		[NSApp setDelegate:self];
		[self setDetails:[NSArray array]];
		
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		
		retries = 0;
		
		// Merge the UserDefaults.plist with defaults in ~/Application Support/
		NSDictionary *userDefaultsPlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
		NSEnumerator *enumerator = [userDefaultsPlist keyEnumerator];
		NSString *key;
		while ( key = [enumerator nextObject] ) {
			if ( ![[NSUserDefaults standardUserDefaults] objectForKey:key] ) {
				[[NSUserDefaults standardUserDefaults] setObject:[userDefaultsPlist objectForKey:key] forKey:key];
			}
		}
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[h showsPath]] ) {
			[self setShows:[NSDictionary dictionaryWithContentsOfFile:[h showsPath]]];
		} else {
			[self setShows:nil];
		}
		
		NonZeroValueTransformer *tr1 = [[[NonZeroValueTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr1
										forName:@"NonZeroValueTransformer"];
		
		DownloadBooleanToTitleTransformer *tr2 = [[[DownloadBooleanToTitleTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr2
										forName:@"DownloadBooleanToTitleTransformer"];
		
		EnabledToImagePathTransformer *tr3 = [[[EnabledToImagePathTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr3
										forName:@"EnabledToImagePathTransformer"];
		
		EnabledToStringTransformer *tr4 = [[[EnabledToStringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr4
										forName:@"EnabledToStringTransformer"];
		
		PathToNameTransformer *tr5 = [[[PathToNameTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr5
										forName:@"PathToNameTransformer"];
		
		QualityIndexToLabelTransformer *tr6 = [[[QualityIndexToLabelTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr6
										forName:@"QualityIndexToLabelTransformer"];
		
		DetailToStringTransformer *tr7 = [[[DetailToStringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr7
										forName:@"DetailToStringTransformer"];
		
		DateToShortDateTransformer *tr8 = [[[DateToShortDateTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr8
										forName:@"DateToShortDateTransformer"];
		
		

	}
	return self;
}

- (void)awakeFromNib
{

	// Experimental
	/*
	[mainColumn setDataCell:[[TVTextFieldCell alloc] init]];
	*/
	
	
	// Ask the user to move the app to /Applications
	PFMoveToApplicationsFolderIfNecessary();
	
	[mainView addSubview:preferencesView];
	[mainView setNeedsDisplay:YES];
	[preferencesView setNeedsDisplay:YES];
	
	
	[showsTable setIntercellSpacing:NSMakeSize(3.0,10.0)];
	
	[defaultsController setAppliesImmediately:YES];
	
	// Register to some notifications		
	// Dowload shows
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mainWindowDidBecomeMain:)
												 name:NSWindowDidBecomeMainNotification
											   object:nil];
	
	// Toolbar
	mainToolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
	[mainToolbar setDelegate:self];
	[mainToolbar setAllowsUserCustomization:YES];
	[mainToolbar setAutosavesConfiguration:YES];
	[mainWindow setToolbar:mainToolbar];
	
	[showsController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:ShowSubscribed ascending:NO] autorelease]]];
	
}

#pragma mark -
#pragma mark Toolbar

- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
    if ( [itemIdentifier isEqualToString:ToolbarFilter] ) {
		[toolbarItem setLabel:@"Search"];
		[toolbarItem setPaletteLabel:@"Search"];
		[toolbarItem setToolTip:@"Search for a show"];
		[toolbarItem setView:searchToolbarItemView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([searchToolbarItemView frame]),NSHeight([searchToolbarItemView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(150,NSHeight([searchToolbarItemView frame]))];
	} else if ( [itemIdentifier isEqualToString:ToolbarPreferences] ) {
		[toolbarItem setLabel:@"Preferences"];
		[toolbarItem setPaletteLabel:@"Preferences"];
		[toolbarItem setToolTip:@"Opens the preferences window"];
		[toolbarItem setImage:[NSImage imageNamed:@"Preferences.png"]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(openPreferences:)];
	} else if ( [itemIdentifier isEqualToString:ToolbarUpdateShowList] ) {
		[toolbarItem setLabel:@"Update List"];
		[toolbarItem setPaletteLabel:@"Update List"];
		[toolbarItem setToolTip:@"Updates the list of shows"];
		[toolbarItem setImage:[NSImage imageNamed:@"Reload.png"]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(downloadShowList)];
    } else {
		[toolbarItem release];
		toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:ToolbarFilter,NSToolbarFlexibleSpaceItemIdentifier,ToolbarUpdateShowList,ToolbarPreferences,nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:ToolbarFilter,NSToolbarFlexibleSpaceItemIdentifier,ToolbarUpdateShowList,ToolbarPreferences,nil];
}

#pragma mark -
#pragma mark Download Show List

- (void)mainWindowDidBecomeMain: (NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	[self checkForBittorrentClient];
	if ( ![shows valueForKey:ShowsShows] || ([shows valueForKey:ShowsShows] && NSOrderedAscending == [[shows valueForKey:ShowsVersion] compare:ShowsLatestVersion options:NSNumericSearch])) 
		[self downloadShowList];
}

- (IBAction)downloadShowList
{
	[NSApp beginSheet:progressPanel
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
	[progressPanelIndicator startAnimation:nil];
	
	[shows writeToFile:[h showsPath] atomically:YES];
	
	NSTask *aTask = [[NSTask alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadShowListDidFinish:) name:NSTaskDidTerminateNotification object:aTask];
	[aTask setArguments:[NSArray arrayWithObjects:[h showsPath],ShowsLatestVersion,nil]];
	[aTask setLaunchPath:[[NSBundle mainBundle] pathForResource:RubyDownloadShowList ofType:@"rb"]];
	[aTask launch];

}

- (void)downloadShowListDidFinish: (NSNotification *)notification
{
	if ( [(NSTask *)[notification object] terminationStatus] != 0 ) {
		[NSApp endSheet:progressPanel];
		[progressPanel close];
		[Helper dieWithErrorMessage:@"Could not download the show list. Are you connected to the internet?"];
	} else {
		[self setShows:[NSDictionary dictionaryWithContentsOfFile:[h showsPath]]];
		[NSApp endSheet:progressPanel];
		[progressPanel close];
	}
}


#pragma mark -
#pragma mark Setters/Getters
- (NSDictionary *)shows
{
	return shows;
}

- (void)setShows: (NSDictionary *)someShows
{
	if ( someShows != shows ) {
		[shows release];
		shows = [someShows retain];
	}
}

- (NSArray *)details;
{
	return details;
}

- (void)setDetails: (NSArray *)someDetails
{
	if ( someDetails != details ) {
		[details release];
		details = [someDetails retain];
	}
}
		

#pragma mark -
#pragma mark Preferences

- (IBAction)openPreferences: (id)sender
{
	[NSApp beginSheet:preferencesWindow
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
	if ( ( [[[NSUserDefaults standardUserDefaults] valueForKey:TVShowsIsEnabled] boolValue] && [[enableDisableButton title] isEqualToString:@"Enabled"] ) ||
		( ![[[NSUserDefaults standardUserDefaults] valueForKey:TVShowsIsEnabled] boolValue] && [[enableDisableButton title] isEqualToString:@"Disable"] ) ) {
		[self enableDisable:enableDisableButton];
	}
	[preferencesWindow makeKeyAndOrderFront:sender];
}

- (IBAction)closePreferences: (id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	[NSApp endSheet:preferencesWindow];
	[preferencesWindow close];
}

- (IBAction)enableDisable: (id)sender
{
	if ( [[sender title] isEqualToString:@"Enable"] ) {
		[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:TVShowsIsEnabled];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[sender setTitle:@"Disable"];
		[enableDisableLabel setStringValue:@"TVShows is enabled"];
	} else if ( [[sender title] isEqualToString:@"Disable"] ) {
		[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:TVShowsIsEnabled];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[sender setTitle:@"Enable"];
		[enableDisableLabel setStringValue:@"TVShows is disabled"];
	}
}

- (IBAction)changeSaveFolder: (id)sender
{
	if (0 == [sender indexOfSelectedItem]) {
		return;
	} else if (2 == [sender indexOfSelectedItem]) {
		int result;
		NSOpenPanel *oPanel = [NSOpenPanel openPanel];
		[oPanel setAllowsMultipleSelection:YES];
		[oPanel setTitle:@"Save torrents in..."];
		[oPanel setMessage:@"Choose the folder where you want the torrent files to be downloaded."];
		[oPanel setDelegate:self];
		[oPanel setCanChooseFiles:NO];
		[oPanel setCanChooseDirectories:YES];
		result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];
		[sender selectItemAtIndex:0];
		if (result == NSOKButton) {
			[[NSUserDefaults standardUserDefaults] setObject:[oPanel filename] forKey:TVShowsTorrentFolder];
		}
	}
}

#pragma mark -
#pragma mark Show list

- (IBAction)subscribe: (id)sender
{	
	if ( retries == 0 ) currentShow = [[showsController arrangedObjects] objectAtIndex:[sender clickedRow]];
	if ( ![[currentShow valueForKey:ShowSubscribed] boolValue] ) {
		if ( retries > 0 ) {
			[detailsErrorText setStringValue:[NSString stringWithFormat:@"Could not reach ezrss.it, retrying (%d)...",retries]];
			[detailsErrorText setHidden:NO];
			[detailsErrorText display];
			sleep(2); // That's bad, I know
		} else {
			[self setDetails:[NSArray array]];
			[detailsErrorText setHidden:YES];
			[detailsProgressIndicator setHidden:NO];
			[detailsTable setHidden:YES];
			[detailsOKButton setEnabled:NO];
			[NSApp beginSheet:detailsSheet
			   modalForWindow:mainWindow
				modalDelegate:self
			   didEndSelector:nil
				  contextInfo:nil];
			[detailsProgressIndicator startAnimation:nil];
		}
		getShowDetailsTask = [[NSTask alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getShowDetailsDidFinish:) name:NSTaskDidTerminateNotification object:getShowDetailsTask];
		[getShowDetailsTask setArguments:[NSArray arrayWithObject:
				[[[showsController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:ShowLinks]
		]];
		[getShowDetailsTask setLaunchPath:[[NSBundle mainBundle] pathForResource:RubyGetShowDetails ofType:@"rb"]];
		getShowDetailsPipe = [NSPipe pipe];
		[getShowDetailsTask setStandardOutput:getShowDetailsPipe];
		[getShowDetailsTask launch];
	} else {
		[currentShow setValue:[NSNumber numberWithBool:NO] forKeyPath:ShowSubscribed];
		[showsController rearrangeObjects];
	}
}

- (void)getShowDetailsDidFinish: (NSNotification *)notification
{	
	// Already retried
	if ( retries >= 2 ) {
		
		retries = 0;
		[detailsProgressIndicator setHidden:YES];
		[detailsErrorText setStringValue:@"Could not reach ezrss.it, please retry later."];
		return;
		
	// Should retry
	} else if ( 0 != [getShowDetailsTask terminationStatus] ) {
		
		retries++;
		[self subscribe:nil];
	
	// Ok
	} else {
		retries = 0;
		NSString *errorString;
		id someDetails = [NSPropertyListSerialization
			propertyListFromData:[[getShowDetailsPipe fileHandleForReading] readDataToEndOfFile]
				mutabilityOption:NSPropertyListImmutable
						  format:NULL
				errorDescription:&errorString];
		
		if ( errorString ) {
			NSLog(@"TVShows: Error getting show details (%@).",errorString);
			[errorString release];
			return;
		}
		
		[self setDetails:(NSArray *)someDetails];
		[detailsProgressIndicator setHidden:YES];
		[detailsErrorText setHidden:YES];
		[detailsTable setHidden:NO];
		[detailsOKButton setEnabled:YES];
		[detailsController setSelectedObjects:nil];
		if ( [[[details lastObject] objectForKey:ShowType] isEqualToString:TypeSeasonEpisode] ) {
			[detailsController setSortDescriptors:[NSArray arrayWithObjects:
				[[[NSSortDescriptor alloc] initWithKey:ShowSeason ascending:NO] autorelease],
				[[[NSSortDescriptor alloc] initWithKey:ShowEpisode ascending:NO] autorelease],
				nil]];
		} else if ( [[[details lastObject] objectForKey:ShowType] isEqualToString:TypeDate] ) {
			[detailsController setSortDescriptors:[NSArray arrayWithObject:
				[[[NSSortDescriptor alloc] initWithKey:ShowDate ascending:NO] autorelease]]];
		} else {
			[detailsController setSortDescriptors:[NSArray arrayWithObject:
				[[[NSSortDescriptor alloc] initWithKey:ShowTime ascending:NO] autorelease]]];
		}
		
	}
}

- (IBAction)cancelSubscription: (id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:getShowDetailsTask];
	[getShowDetailsTask terminate];
	[currentShow setValue:[NSNumber numberWithBool:NO] forKeyPath:ShowSubscribed];
	
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}

- (IBAction)okSubscription: (id)sender
{	
	NSDictionary *selectedShow = [[detailsController selectedObjects] objectAtIndex:0];
	
	if ( [[selectedShow objectForKey:ShowType] isEqualToString:TypeSeasonEpisode] ) {
		[currentShow setValue:[selectedShow objectForKey:ShowSeason] forKeyPath:ShowSeason];
		[currentShow setValue:[NSNumber numberWithInt:([[selectedShow objectForKey:ShowEpisode] intValue]-1)] forKeyPath:ShowEpisode];
		[currentShow setValue:[selectedShow objectForKey:ShowType] forKeyPath:ShowType];
		
	} else if ( [[selectedShow objectForKey:ShowType] isEqualToString:TypeDate] ) {
		[currentShow setValue:[[selectedShow objectForKey:ShowDate] addTimeInterval:-3600.0*24.0] forKeyPath:ShowDate];
		[currentShow setValue:[selectedShow objectForKey:ShowType] forKeyPath:ShowType];
		
	} else {
		[currentShow setValue:[[selectedShow objectForKey:ShowTime] addTimeInterval:-3600.0] forKeyPath:ShowTime];
		[currentShow setValue:[selectedShow objectForKey:ShowType] forKeyPath:ShowType];
		
	}
	[currentShow setValue:[NSNumber numberWithBool:YES] forKeyPath:ShowSubscribed];

	[showsController rearrangeObjects];
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}

- (IBAction)okSubscriptionToNextAiredEpisode: (id)sender
{	
	NSDictionary *firstShow = [[detailsController arrangedObjects] objectAtIndex:0];
	
	if ( [[firstShow objectForKey:ShowType] isEqualToString:TypeSeasonEpisode] ) {
		[currentShow setValue:[firstShow objectForKey:ShowSeason] forKeyPath:ShowSeason];
		[currentShow setValue:[firstShow objectForKey:ShowEpisode] forKeyPath:ShowEpisode];
		[currentShow setValue:[firstShow objectForKey:ShowType] forKeyPath:ShowType];
		
	} else if ( [[firstShow objectForKey:ShowType] isEqualToString:TypeDate] ) {
		[currentShow setValue:[firstShow objectForKey:ShowDate] forKeyPath:ShowDate];
		[currentShow setValue:[firstShow objectForKey:ShowType] forKeyPath:ShowType];
		
	} else {
		[currentShow setValue:[firstShow objectForKey:ShowTime] forKeyPath:ShowTime];
		[currentShow setValue:[firstShow objectForKey:ShowType] forKeyPath:ShowType];
		
	}
	[currentShow setValue:[NSNumber numberWithBool:YES] forKeyPath:ShowSubscribed];
	
	[showsController rearrangeObjects];
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}

- (void) tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)row 
{
	if ( [[tableView tableColumns] lastObject] == tableColumn ) {
		[cell bind:@"title" toObject:[[showsController arrangedObjects] objectAtIndex:row] withKeyPath:ShowSubscribed options:[NSDictionary dictionaryWithObject:@"DownloadBooleanToTitleTransformer" forKey:NSValueTransformerNameBindingOption]];
	}
}

- (IBAction)filterShows: (id)sender
{
	if ( [[sender stringValue] length] > 0 ) {
		[showsController setFilterPredicate:[NSPredicate predicateWithFormat:@"HumanName CONTAINS[cd] %@",[sender stringValue]]];
	} else {
		[showsController setFilterPredicate:nil];
	}
}

#pragma mark -
#pragma mark launchd

- (void)unloadFromLaunchd
{
	NSTask *aTask = [[NSTask alloc] init];
	[aTask setLaunchPath:@"/bin/launchctl"];
	[aTask setArguments:[NSArray arrayWithObjects:@"unload",[h launchdPlistPath],nil]];
	[aTask launch];
	[aTask waitUntilExit];
	[aTask release];
}

- (void)loadIntoLaunchd
{
	NSTask *aTask = [[NSTask alloc] init];
	[aTask setLaunchPath:@"/bin/launchctl"];
	[aTask setArguments:[NSArray arrayWithObjects:@"load",[h launchdPlistPath],nil]];
	[aTask launch];
	[aTask waitUntilExit];
	[aTask release];
}

- (void)saveLaunchdPlist
{
	NSMutableDictionary *launchdProperties = [NSMutableDictionary dictionary];
	[[NSFileManager defaultManager] removeFileAtPath:[h launchdPlistPath] handler:nil];
	int checkDelay = [[[NSUserDefaults standardUserDefaults] objectForKey:TVShowsCheckDelay] intValue];
	if ( checkDelay <= 2 ) {
		switch (checkDelay) {
		case 0:
			[launchdProperties setObject:[NSNumber numberWithInt:15*60] forKey:@"StartInterval"];
			break;
		case 1:
			[launchdProperties setObject:[NSNumber numberWithInt:30*60] forKey:@"StartInterval"];
			break;
		}
		[launchdProperties setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSCalendarDate calendarDate] minuteOfHour]],@"Minute",nil]
							  forKey:@"StartCalendarInterval"];
	} else {
		[launchdProperties setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSCalendarDate calendarDate] hourOfDay]],@"Hour",nil]
							  forKey:@"StartCalendarInterval"];
	}	
	[launchdProperties setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] 
						  forKey:@"Label"];
	[launchdProperties setObject:[NSArray arrayWithObjects:[h scriptPath],[h preferencesFile],[h showsPath],nil]
						  forKey:@"ProgramArguments"];
	[launchdProperties setObject:[Helper negate:[[NSUserDefaults standardUserDefaults] objectForKey:TVShowsIsEnabled]]
						  forKey:@"Disabled"];
	[launchdProperties setObject:[h logPath]
						  forKey:@"StandardErrorPath"];
	[launchdProperties setObject:[NSDictionary dictionaryWithObject:[h scriptFolder] forKey:@"TVSHOWSPATH"]
						  forKey:@"EnvironmentVariables"];
	[launchdProperties setObject:[NSNumber numberWithBool:YES]
						  forKey:@"RunAtLoad"];
	
	if ( ![launchdProperties writeToFile:[h launchdPlistPath] atomically:YES] )
		[Helper dieWithErrorMessage:@"Could not write the ~/Library/LaunchAgents/net.sourceforge.tvshows.plist"];
}


#pragma mark -
#pragma mark Menu handlers

- (IBAction)find: (id)sender
{
	[mainWindow makeFirstResponder:searchToolbarItemTextField];
}

- (IBAction)help: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TVShowsURL]];
}

- (IBAction)sendFeedback: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TVShowsFeedbackURL]];
}

#pragma mark -
#pragma mark Misc

- (void)applicationWillTerminate: (NSNotification *)aNotification
{
	[shows writeToFile:[h showsPath] atomically:YES];
	[self saveLaunchdPlist];
	[self loadIntoLaunchd];	
}

- (BOOL)shouldGreenRowAtIndex: (int)index
{
	if ( index < [[showsController arrangedObjects] count] )
		return [[[[showsController arrangedObjects] objectAtIndex:index] objectForKey:ShowSubscribed] boolValue];
	return NO;
}

- (void)checkForBittorrentClient
{
	if (kLSApplicationNotFoundErr == LSGetApplicationForInfo(kLSUnknownType,kLSUnknownCreator,CFSTR("torrent"),kLSRolesAll,NULL,NULL)) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Download"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"TVShows Requires a Bittorrent Client"];
		[alert setInformativeText:@"You need a bittorent client in order to download episodes. Clicking Download will take you to Transmission's website, a free bittorent client which we recommend."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(checkForBittorrentClientAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void)checkForBittorrentClientAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TransmissionURL]];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
