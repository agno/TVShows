/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#import <Cocoa/Cocoa.h>


@interface Helper : NSObject {

	NSString *libraryFolder;
	NSString *applicationSupportFolder;
	NSString *applicationApplicationSupportFolder;
	NSString *preferencesFolder;
	NSString *preferencesFile;
	NSString *showsPath;
	NSString *launchdPlistPath;
	NSString *scriptPath;
	NSString *logPath;
	NSString *scriptFolder;
	NSString *bundleIdentifier;

}

- (void)createFolderAtPath: (NSString *)path;
- (void)chmodFolderAtPath: (NSString *)path;
- (NSString *)libraryFolder;
- (NSString *)applicationSupportFolder;
- (NSString *)applicationApplicationSupportFolder;
- (NSString *)preferencesFolder;
- (NSString *)preferencesFile;
- (NSString *)showsPath;
- (NSString *)launchdPlistPath;
- (NSString *)scriptPath;
- (NSString *)logPath;
- (NSString *)scriptFolder;
- (NSString *)bundleIdentifier;

/*
+ (NSString *)pathForDirectoryInUserDomain: (NSSearchPathDirectory)directory;
+ (NSString *)applicationSupportFolder;
+ (NSString *)applicationApplicationSupportFolder;
+ (void)initializeFoldersAndFiles;
+ (NSString *)showListPath;
*/
+ (void)dieWithErrorMessage: (NSString *)message;
+ (NSNumber *)negate: (NSNumber *)n;
@end
