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

#import "TVShowsPref.h"
#import "TSUserDefaults.h"
#import "AppInfoConstants.h"
#import "ValueTransformers.h"


@implementation TVShowsPref

@synthesize releaseNotesURL;

- init
{
    if((self = [super init])) {
        // Initialize any transformers we need to use in Interface Builder.
        ShowPosterValueTransformer *trOne = [[[ShowPosterValueTransformer alloc] init] autorelease];
        [NSValueTransformer setValueTransformer:trOne
                                        forName:@"ShowPosterValueTransformer"];
    }
    
    return self;
}

- (void) didSelect
{
    NSString *buildVersion = [[[NSBundle bundleWithIdentifier: TVShowsAppDomain] infoDictionary]
                              valueForKey:@"CFBundleVersion"];
    NSString *installedBuild = [TSUserDefaults getStringFromKey:@"installedBuild"];
    
    // Uninstall previous versions crap if present
    [self uninstallPreviousVersions];
    
    // If detected that the user is using catalan, try to fix it
    if ([[[[NSLocale currentLocale] localeIdentifier] substringToIndex:2] isEqualToString:@"ca"]) {
        [self fixCatalan];
    }
    
    // Check to see if we installed a different version, both updates and rollbacks.
    if ([buildVersion intValue] > [installedBuild intValue]) {
        
        // Update the application build number in installedBuild
        [TSUserDefaults setKey:@"installedBuild" fromString:buildVersion];
        
        // Did we install the update automatically? Display a dialog box with changes.
        if ([TSUserDefaults getBoolFromKey:@"AutomaticallyInstalledLastUpdate" withDefault:NO]) {
            
            // Reset the key for next time.
            [TSUserDefaults setKey:@"AutomaticallyInstalledLastUpdate" fromBool:NO];
            
            [self displayUpdateWindowForVersion:installedBuild];
        }
        
        // Relaunch System Preferences so that we know all the resources have been reloaded
        // correctly. This is due to a bug in how it handles updating bundles.
        [self relaunch:nil];
        
    }
}

- (void) displayUpdateWindowForVersion:(NSString *)installedBuild
{
    // Display a window showing the release notes.
    releaseNotesURL = [NSString stringWithFormat:@"http://tvshowsapp.com/notes-%@",installedBuild];
    
    [NSApp beginSheet: updateWindow
       modalForWindow: [[NSApplication sharedApplication] mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp endSheet: updateWindow];
    [NSApp runModalForWindow: updateWindow];
}

- (IBAction) openMoreInfoURL:(id)sender
{
    // Open the release notes page.
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: releaseNotesURL]];
    
    // Close the modal window.
    [self closeUpdateWindow:nil];
}

- (IBAction) closeUpdateWindow:(id)sender
{
    [NSApp stopModal];
    [updateWindow orderOut:self];
}

- (void) relaunch:(id)sender
{
    NSString *daemonPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] pathForResource:@"relaunch" ofType:nil];
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *prefPath = [[NSBundle bundleWithIdentifier: TVShowsAppDomain] bundlePath];
    
    [NSTask launchedTaskWithLaunchPath:daemonPath
                             arguments:[NSArray arrayWithObjects: bundlePath, prefPath, 
                                        [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]], nil] ];
    
    LogInfo(@"Relaunching TVShows to fix the System Preferences update bug.");
    [NSApp terminate:sender];
}

- (void) fixCatalan
{
    // There is a problem with the catalan localization (and I'm sure there are a lot more)
    // Since the System Preferences.app is not localized into that language, no preference pane can be localized to catalan
    // A quick and dirty fix is deceiving System Preferences.app by linking the missing localization to a fallback language
    // Then the panel is shown in this fallback localization (as before), but our app is shown in this other language
    // The only problem with this solution is that we have to ask for admin privileges
    NSString *link = @"/Applications/System Preferences.app/Contents/Resources/ca.lproj";
    NSString *original = @"/Applications/System Preferences.app/Contents/Resources/Spanish.lproj";
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:link]) {
        LogInfo(@"Fixing the catalan localization for System Preferences.app");
        [[[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"display dialog \"La aplicación Preferencias del Sistema no está traducida al Catalán, así que TVShows necesita arreglarla para que se pueda mostrar en tu idioma.\n\nPor favor introduce tu contraseña en la siguiente ventana para que podamos arreglarla.\"\ndo shell script \"sudo /usr/bin/env ln -s \\\"%@\\\" \\\"%@\\\"\" with administrator privileges", original, link]] autorelease] executeAndReturnError:nil];
    }
}

- (void) uninstallPreviousVersions
{
    NSString *tvshowsLaunchAgent = [@"~/Library/LaunchAgents/net.sourceforge.tvshows.plist" stringByExpandingTildeInPath];
    NSString *tvshows2LaunchAgent = [@"~/Library/LaunchAgents/com.embercode.TVShowsHelper.plist"stringByExpandingTildeInPath];
    NSString *tvshowsPreferences = [@"~/Library/Preferences/net.sourceforge.tvshows.plist" stringByExpandingTildeInPath];
    NSString *tvshows2Preferences = [@"~/Library/Preferences/com.embercode.TVShows2.plist" stringByExpandingTildeInPath];
    NSString *tvshowsAppSupport = [@"~/Library/Application\\ Support/TVShows" stringByExpandingTildeInPath];
    NSString *tvshows2AppCache = [@"~/Library/Caches/com.embercode.TVShowsHelper" stringByExpandingTildeInPath];
    
    // Unload and remove the TVShows 0.4 LaunchAgent if it exists, with all the preferences
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshowsLaunchAgent]) {
        LogInfo(@"Removing %@...", tvshowsLaunchAgent);
        [self unloadPlist:tvshowsLaunchAgent];
        [[NSFileManager defaultManager] removeItemAtPath:tvshowsLaunchAgent error:nil];
    }
    
    // Remove the old TVShows 0.4 preference plist if it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshowsPreferences]) {
        LogInfo(@"Removing %@...", tvshowsPreferences);
        [[NSFileManager defaultManager] removeItemAtPath:tvshowsPreferences error:nil];
    }
    
    // Remove the old TVShows 0.4 support folder if it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshowsAppSupport]) {
        LogInfo(@"Removing %@...", tvshowsAppSupport);
        [[NSFileManager defaultManager] removeItemAtPath:tvshowsAppSupport error:nil];
    }
    
    // Unload and remove the old TVShows 2 LaunchAgent if it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshows2LaunchAgent]) {
        LogInfo(@"Removing %@...", tvshows2LaunchAgent);
        [self unloadPlist:tvshows2LaunchAgent];
        [[NSFileManager defaultManager] removeItemAtPath:tvshows2LaunchAgent error:nil];
    }
    
    // Remove the old TVShows 2 preference plist if it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshows2Preferences]) {
        LogInfo(@"Removing %@...", tvshows2Preferences);
        [[NSFileManager defaultManager] removeItemAtPath:tvshows2Preferences error:nil];
    }
    
    // Remove the old TVShows 2 cache folder if it exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:tvshows2AppCache]) {
        LogInfo(@"Removing %@...", tvshows2AppCache);
        [[NSFileManager defaultManager] removeItemAtPath:tvshows2AppCache error:nil];
    }
}

- (void) unloadPlist:(NSString*)aPath
{
    NSTask *aTask = [[NSTask alloc] init];
    [aTask setLaunchPath:@"/bin/launchctl"];
    [aTask setArguments:[NSArray arrayWithObjects:@"unload",@"-w",aPath,nil]];
    [aTask launch];
    [aTask waitUntilExit];
    [aTask release];
}

- (void) dealloc
{
    [releaseNotesURL release];
    [super dealloc];
}

@end
