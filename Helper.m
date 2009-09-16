/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#import "Helper.h"
#import <Security/Security.h>

/* Thanks to http://boinc.berkeley.edu/source_code.php */

static AuthorizationRef gOurAuthRef = NULL;
static char chownPath[] = "/usr/sbin/chown";

static OSStatus getAuthorization(void) {
	static Boolean  			sIsAuthorized = false;
	AuthorizationRights 		ourAuthRights;
	AuthorizationFlags  		ourAuthFlags;
	AuthorizationItem   		ourAuthRightsItem[1];
	AuthorizationEnvironment	ourAuthEnvironment;
	AuthorizationItem   		ourAuthEnvItem[1];
	char						prompt[] = "TVShows needs to access to the ~/Library/LaunchAgents folder.\n\n";
	OSStatus					err = noErr;
	
	if (sIsAuthorized)
		return noErr;
	
	ourAuthRights.count = 0;
	ourAuthRights.items = NULL;
	
	err = AuthorizationCreate (&ourAuthRights, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &gOurAuthRef);
	if (err != noErr) {
		return err;
	}
	
	ourAuthRightsItem[0].name = kAuthorizationRightExecute;
	ourAuthRightsItem[0].value = chownPath;
	ourAuthRightsItem[0].valueLength = strlen (chownPath);
	ourAuthRightsItem[0].flags = 0;
	
	ourAuthRights.count = 1;
	ourAuthRights.items = ourAuthRightsItem;
	
	ourAuthEnvItem[0].name = kAuthorizationEnvironmentPrompt;
	ourAuthEnvItem[0].value = prompt;
	ourAuthEnvItem[0].valueLength = strlen(prompt);
	ourAuthEnvItem[0].flags = 0;
	
	ourAuthEnvironment.count = 1;
	ourAuthEnvironment.items = ourAuthEnvItem;
	
	ourAuthFlags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	err = AuthorizationCopyRights (gOurAuthRef, &ourAuthRights, &ourAuthEnvironment, ourAuthFlags, NULL);
	
	if (err == noErr)
		sIsAuthorized = true;
	
	return err;
}

OSStatus chownToUidAndGidAtPath(uid_t uid, gid_t gid, char *path) {
	
	short   			i;
	char				*args[3];
	OSStatus			err;
	FILE				*ioPipe;
	char				*p, junk[256];
	
	err = getAuthorization();
	if (err != noErr) {
		//if (err == errAuthorizationCanceled)
		return err;
	} else {
		for (i=0; i<5; i++) {   	// Retry 5 times if error
			
			char *arg0;
			asprintf(&arg0,"%d:%d",uid,gid);
			
			args[0] = arg0;
			args[1] = path;
			args[2] = NULL;
			
			
			err = AuthorizationExecuteWithPrivileges(gOurAuthRef, chownPath, 0, args, &ioPipe);
			// We use the pipe to signal us when the command has completed
			do {
				p = fgets(junk, sizeof(junk), ioPipe);
			} while (p);
			
			fclose (ioPipe);
			if (err == noErr)
				break;
		}
	}
	
	return err;
}

@implementation Helper

- (id) init {
	self = [super init];
	if (self != nil) {
		
		NSFileManager	*fm						= [NSFileManager defaultManager];
		NSString		*bundleName				= [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
		NSString		*bundleNamePlist		= [bundleName stringByAppendingPathExtension:@"plist"];
		bundleIdentifier						= [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]; // Don't move this line, it is needed for the next one
		NSString		*bundleIdentifierPlist	= [bundleIdentifier stringByAppendingPathExtension:@"plist"];
		NSString		*resourcesScriptFolder	= [[NSBundle mainBundle] pathForResource:@"TVShowsScript" ofType:nil];
		NSString		*launchAgentsFolder;
		//NSString *script = [[NSBundle mainBundle] pathForResource:@"TVShows" ofType:@"rb"];
		
		libraryFolder						= [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) objectAtIndex:0];
		applicationSupportFolder			= [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0];
		applicationApplicationSupportFolder	= [applicationSupportFolder stringByAppendingPathComponent:bundleName];
		preferencesFolder					= [libraryFolder stringByAppendingPathComponent:@"Preferences"];
		preferencesFile						= [preferencesFolder stringByAppendingPathComponent:bundleIdentifierPlist];
		showsPath							= [applicationApplicationSupportFolder stringByAppendingPathComponent:bundleNamePlist];
		launchAgentsFolder					= [libraryFolder stringByAppendingPathComponent:@"LaunchAgents"];
		launchdPlistPath					= [launchAgentsFolder stringByAppendingPathComponent:bundleIdentifierPlist];
		scriptFolder						= [applicationApplicationSupportFolder stringByAppendingPathComponent:[resourcesScriptFolder lastPathComponent]];
		scriptPath							= [[applicationApplicationSupportFolder stringByAppendingPathComponent:[resourcesScriptFolder lastPathComponent]] stringByAppendingPathComponent:@"TVShows.rb"];
		logPath								= [applicationApplicationSupportFolder stringByAppendingPathComponent:[bundleName stringByAppendingPathExtension:@"log"]];
		
		[libraryFolder retain];
		[applicationSupportFolder retain];
		[applicationApplicationSupportFolder retain];
		[preferencesFolder retain];
		[preferencesFile retain];
		[showsPath retain];
		[launchdPlistPath retain];
		[scriptPath retain];
		[logPath retain];
		[scriptFolder retain];
		[bundleIdentifier retain];
		
		[self createFolderAtPath:applicationSupportFolder];
		[self createFolderAtPath:applicationApplicationSupportFolder];
		[self createFolderAtPath:launchAgentsFolder];
		[self chmodFolderAtPath:launchAgentsFolder];
		
		// Remove scriptFolder if we have a newer version to install
		if ( [fm fileExistsAtPath:scriptPath] ) {
			NSString *scriptVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScriptVersion"];
			if ( !scriptVersion || NSOrderedAscending == [scriptVersion compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] options:NSNumericSearch] )
				if ( ![fm removeFileAtPath:scriptFolder handler:nil] )
					[Helper dieWithErrorMessage:@"Could not remove the TVShows script folder in the Application Support folder in order to install the new one."];
		}
		
		// Install the script in the Application Support folder
		if ( ![fm fileExistsAtPath:scriptFolder] ) {
			if ( ![fm copyPath:resourcesScriptFolder toPath:scriptFolder handler:nil] ) {
				[Helper dieWithErrorMessage:@"Could not copy the TVShows script in the Application Support folder."];
			} else {
				// Chmod the scripts to make sure they're executable
				[fm changeFileAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0744] forKey:NSFilePosixPermissions] atPath:scriptPath];
				
				// Set the new version
				[[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:@"ScriptVersion"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}
		
		// Chmod the ruby scripts in the resource folder
		NSEnumerator *scripts = [[[NSBundle mainBundle] pathsForResourcesOfType:@"rb" inDirectory:@""] objectEnumerator];
		NSString *script;
		while ( script = [scripts nextObject] ) {
			[fm changeFileAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0744] forKey:NSFilePosixPermissions] atPath:script];
		}
		
	}
	return self;
}

- (void) dealloc {
	
	[libraryFolder release];
	[applicationSupportFolder release];
	[applicationApplicationSupportFolder release];
	[preferencesFolder release];
	[preferencesFile release];
	[showsPath release];
	[launchdPlistPath release];
	[scriptPath release];
	[logPath release];
	[scriptFolder release];
	[bundleIdentifier release];
	
	[super dealloc];
}


- (void)createFolderAtPath: (NSString *)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( ![fm fileExistsAtPath:path] )
		if ( ![fm createDirectoryAtPath:path attributes:nil] )
			[Helper dieWithErrorMessage:[NSString stringWithFormat:@"the folder %@ doesn't exist and I can't create it.",path]];
}

- (void)chmodFolderAtPath: (NSString *)path
{	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ( ![fm changeFileAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:@"NSFilePosixPermissions"] atPath:path] ) {
		if ( noErr == chownToUidAndGidAtPath(getuid(),getgid(),(char *)[path cStringUsingEncoding:NSUTF8StringEncoding]) ) {
			if ( ![fm changeFileAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:@"NSFilePosixPermissions"] atPath:path] ) {
				[Helper dieWithErrorMessage:[NSString stringWithFormat:@"Could not change permissions for %@",path]];
			}
		} else {
			[Helper dieWithErrorMessage:[NSString stringWithFormat:@"I'm not authorized to change permissions for %@.",path]];
		}
	}
}

- (NSString *)libraryFolder
{
	return libraryFolder;
}

- (NSString *)applicationSupportFolder
{
	return applicationSupportFolder;
}

- (NSString *)applicationApplicationSupportFolder
{
	return applicationApplicationSupportFolder;
}

- (NSString *)preferencesFolder
{
	return preferencesFolder;
}

- (NSString *)preferencesFile
{
	return preferencesFile;
}

- (NSString *)showsPath
{
	return showsPath;
}

- (NSString *)launchdPlistPath
{
	return launchdPlistPath;
}

- (NSString *)scriptPath
{
	return scriptPath;
}

- (NSString *)logPath
{
	return logPath;
}

- (NSString *)scriptFolder
{
	return scriptFolder;
}

- (NSString *)bundleIdentifier
{
	return bundleIdentifier;
}

+ (void)dieWithErrorMessage: (NSString *)message
{
	NSRunAlertPanel(@"Alert", message, @"Quit", nil, nil);
	[[NSApplication sharedApplication] terminate:self];
}

+ (NSNumber *)negate: (NSNumber *)n
{
	if ( [n boolValue] ) {
		return [NSNumber numberWithBool:NO];
	}
	return [NSNumber numberWithBool:YES];
}
@end
