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


@interface TheTVDB : NSObject {
	NSURL *mirrorURL;
}

@property (retain) NSURL *mirrorURL;
@property (retain) NSString *serverTime;

+ (NSString *) applicationCacheDirectory;
+ (NSString *) getValueForKey:(NSString *)key andShow:(NSString *)show;

+ (NSString *) getShowStatus:(NSString *)showName;
+ (NSImage *) getPosterForShow:(NSString *)showName withHeight:(float)height withWidth:(float)width;
- (NSImage *) getPosterForShow:(NSString *)showName withHeight:(float)height withWidth:(float)width;
+ (NSString *) getIDForShow:(NSString *)showName;

@end
