/*
 This file is part of the TVShows source code.
 http://github.com/mattprice/TVShows

 TVShows is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
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
