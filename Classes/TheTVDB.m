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

#import "AppInfoConstants.h"

#import "TheTVDB.h"
#import "RegexKitLite.h"


@implementation TheTVDB

@synthesize mirrorURL, serverTime;

- init
{
	if((self = [super init])) {
		// Before we can do anything we need to download a list of mirrors.
		// TODO: Grab the list of mirrors. Currently only one server is listed, though.
//		mirrorURL = [NSURL URLWithString:@"http://www.thetvdb.com"];
		
		// Get the current server time.
		// TODO: This isn't actually saved anywhere but will be used for knowing
		// whether we need to update the Cache or not.
//		serverTime = [[[NSString alloc] initWithContentsOfURL: [NSURL URLWithString:@"http://www.thetvdb.com/api/Updates.php?type=none"]
//													 encoding: NSUTF8StringEncoding
//														error: NULL] autorelease];
	}
	
	return self;
}

+ (NSString *) applicationCacheDirectory
{
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	basePath = [basePath stringByAppendingPathComponent:@"TVShows 2"];
	return [basePath stringByAppendingPathComponent:@"Cache"];
}

+ (NSString *) getValueForKey:(NSString *)key andShow:(NSString *)show
{
	// TODO: Save the information returned for each series into the Cache
	NSURL *seriesURL = [NSURL URLWithString:[[NSString stringWithString: @"http://www.thetvdb.com/api/GetSeries.php?seriesname="]
											 stringByAppendingString: [show stringByReplacingOccurrencesOfRegex:@" " withString:@"+"]]];
	NSString *seriesInfo = [[[NSString alloc] initWithContentsOfURL: seriesURL
														   encoding: NSUTF8StringEncoding
															  error: NULL] autorelease];
	
	// For now select the first show in the list that's returned
	// TODO: Get the TVDB ID from the Subscriptions file.
	NSArray *tempSeriesID = [seriesInfo componentsMatchedByRegex:@"(?!<seriesid>)([[:digit:]]+)(?=</seriesid>)"];
	if ( [tempSeriesID count] >= 1 ) {
		NSString *seriesID = [self getIDForShow:show withPossibleID:[tempSeriesID objectAtIndex:0]];
		
		// Now let's grab complete info for the show using the API key.
		// Since we don't need the other list anymore we'll reuse variables.
		// TODO: Grab the correct localization.
		seriesURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.thetvdb.com/api/%@/series/%@/en.xml",API_KEY,seriesID]];
		seriesInfo = [[[NSString alloc] initWithContentsOfURL: seriesURL
													 encoding: NSUTF8StringEncoding
														error: NULL] autorelease];
		
		// Regex fun...
		key = [NSString stringWithFormat:@"<%@>(.+)</%@>",key,key];
		NSArray *tempValue = [seriesInfo componentsMatchedByRegex:key];
		if ( [tempValue count] >= 1 ) {
			NSString *value = [tempValue objectAtIndex:0];
			value = [value stringByReplacingOccurrencesOfRegex:@"<(.+?)>" withString:@""];
			
			return value;
		} else {
			return NULL;
		}

	} else {
		return NULL;
	}
}

+ (NSString *) getShowStatus:(NSString *)showName
{
	// Grab the show's status.
	NSString *status = [self getValueForKey:@"Status" andShow: showName];
	
	// If no known status was returned...
	if (status == NULL) {
		status = @"Unknown";
	}
	
	return status;
	
}

+ (NSImage *) getPosterForShow:(NSString *)showName withHeight:(float)height withWidth:(float)width
{
	// If the TVShows cache directory doesn't exist then create it.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *applicationCacheDirectory = [self applicationCacheDirectory];
	NSError *error = nil;
	
	if ( ![fileManager fileExistsAtPath:applicationCacheDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationCacheDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
			TVLog(@"Error creating application cache directory: %@",error);
			return nil;
		}
	}
	
	// If the image already exists then return the data, otherwise we need to download it.
	NSString *imagePath = [[[self applicationCacheDirectory] stringByAppendingPathComponent:showName] stringByAppendingFormat:@".jpg"];
	
	if ( [fileManager fileExistsAtPath:imagePath] ) {
		NSImage *sourceImage = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
		NSImage *finalImage = [[[NSImage alloc] initWithSize: NSMakeSize(width, height)] autorelease];
		
		NSSize originalSize = [sourceImage size];
		
		// Resize the cached image so that it fits the actual situation.
		[finalImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[sourceImage drawInRect: NSMakeRect(0, 0, width, height)
					   fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height)
					  operation: NSCompositeSourceOver fraction: 1.0];
		[finalImage unlockFocus];
		
		return finalImage;
	} else {
		// Grab the URL of the show poster
		NSImage *sourceImage;
		NSString *posterURL = [self getValueForKey:@"poster" andShow: showName];
		
		// If a poster URL was returned, download the image.
		if (posterURL != NULL) {
			sourceImage = [[[NSImage alloc] initWithContentsOfURL:
							[NSURL URLWithString: [NSString stringWithFormat:@"http://www.thetvdb.com/banners/%@",posterURL]]] autorelease];
		} else {
			sourceImage = [[[NSImage alloc] initWithContentsOfFile:
							[[NSBundle bundleWithIdentifier: TVShowsAppDomain] pathForResource: @"posterArtPlaceholder"
																						ofType: @"jpg"]] autorelease];
		}
		
		// Resize the show poster so that it scales smoothly and still fits the box.
		NSImage *resizedImage = [[[NSImage alloc] initWithSize: NSMakeSize(129, 187)] autorelease];
		NSImage *finalImage = [[[NSImage alloc] initWithSize: NSMakeSize(width, height)] autorelease];
		
		NSSize originalSize = [sourceImage size];
		
		[resizedImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[sourceImage drawInRect: NSMakeRect(0, 0, 129, 187)
					   fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height)
					  operation: NSCompositeSourceOver fraction: 1.0];
		[resizedImage unlockFocus];
		
		// If a poster URL was returned, save the image so that it's not downloaded again.
		if (posterURL != NULL) {
			// Turn the NSImage into an NSData TIFFRepresentation. We do this since
			// it will always work, no matter what the source image's type is.
			NSData *imageData = [resizedImage TIFFRepresentation];

			// Now it's safe to turn the NSData into an NSBitmapImageRep...
			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
			
			// From BitmapImageRep we can turn it into anything we want. Here, we're using a JPEG.
			NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:0.8]
																   forKey: NSImageCompressionFactor];
			NSData *resizedData = [imageRep representationUsingType: NSJPEGFileType
														 properties: imageProps];
			
			// The conversion is done, so save it to the disk.
			[resizedData writeToFile:imagePath atomically:YES];
		}
		
		// Now we need to resize the image in memory one last time so that it fits the actual situation.
		[finalImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[sourceImage drawInRect: NSMakeRect(0, 0, width, height)
					   fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height)
					  operation: NSCompositeSourceOver fraction: 1.0];
		[finalImage unlockFocus];
		
		return finalImage;
	}
}

- (NSImage *) getPosterForShow:(NSString *)showName withHeight:(float)height withWidth:(float)width
{
	return [[TheTVDB class] getPosterForShow:showName withHeight:height withWidth:width];
}

+ (NSString *) getIDForShow:(NSString *)showName withPossibleID:(NSString *)oldID
{
	DLog(showName);
	DLog(oldID);
	
	// TODO: Use an NSDictionary instead.
	// * Means a show never made it to this method.
	if ([showName isEqualToString:@"30 Seconds AU"])		return @"114461";	// Broken *
	if ([showName isEqualToString:@"Archer"])				return @"110381";
	if ([showName isEqualToString:@"Big Brother US"])		return @"76706";	// Broken *
	if ([showName isEqualToString:@"Bob's Burger"])			return @"194031";	// Broken *
	if ([showName isEqualToString:@"Brothers and Sisters"])	return @"79506";
	if ([showName isEqualToString:@"The Cape"])				return @"160671";
	if ([showName isEqualToString:@"Castle"])				return @"83462";
	if ([showName isEqualToString:@"Chase"])				return @"163541";
	if ([showName isEqualToString:@"Conan"])				return @"194751";
	if ([showName isEqualToString:@"Cops"])					return @"74709";
	if ([showName isEqualToString:@"CSI"])					return @"72546";	// Broken
	if ([showName isEqualToString:@"Cupid"])				return @"83615";	// Broken
	if ([showName isEqualToString:@"The Daily Show"])		return @"71256";
	if ([showName isEqualToString:@"David Letterman"])		return @"75088";
	if ([showName isEqualToString:@"The Defenders"])		return @"164521";
	if ([showName isEqualToString:@"Doctor Who"])			return @"112671";	// Broken
	if ([showName isEqualToString:@"Eastbound and Down"])	return @"82467";	// Broken *
	if ([showName isEqualToString:@"The Good Guys"])		return @"140101";
	if ([showName isEqualToString:@"Human Target"])			return @"94801";
	if ([showName isEqualToString:@"Law & Order: Special Victims Unit"])	return @"75692";	// Broken *
	if ([showName isEqualToString:@"Law & Order: Los Angeles"])				return @"168161";	// Broken
	if ([showName isEqualToString:@"Law and Order"])		return @"72368";
	if ([showName isEqualToString:@"Law & Order: UK"])		return @"85228";	// Broken *
	if ([showName isEqualToString:@"The Life and Times of Tim"])			return @"83130";	// Broken *
	if ([showName isEqualToString:@"Lights Out"])			return @"194051";
	if ([showName isEqualToString:@"Louie"])				return @"155201";	// Broken
	if ([showName isEqualToString:@"Melissa and Joey"])		return @"168621";	// Broken *
	if ([showName isEqualToString:@"Merlin"])				return @"83123";
	
	else return oldID;
}

- (void) dealloc
{
	[serverTime release];
	[mirrorURL release];
	[super dealloc];
}

@end
