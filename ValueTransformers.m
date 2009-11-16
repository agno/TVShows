/*
 This file is part of the TVShows source code.
 http://github.com/mattprice/TVShows

 TVShows is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
*/

#import "ValueTransformers.h"

@implementation NonZeroValueTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( ![value isKindOfClass:[NSNumber class]] || [value intValue] == 0 ) {
		return @"";
	} else {
		return [value stringValue];
	}
}
@end

@implementation DownloadBooleanToTitleTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return @"Unsubscribe";
	} else {
		return @"Subscribe";
	}
}
@end

@implementation EnabledToImagePathTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return [[NSBundle mainBundle] pathForResource:@"Green" ofType:@"tif"];
	} else {
		return [[NSBundle mainBundle] pathForResource:@"Red" ofType:@"tif"];
	}
}
@end

@implementation EnabledToStringTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return @"Status: Enabled";
	} else {
		return @"Status: Disabled";
	}
}
@end

@implementation PathToNameTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value isKindOfClass:[NSString class]] ) {
		return [[NSFileManager defaultManager] displayNameAtPath:value];
	}
	return @"";
}
@end

@implementation QualityIndexToLabelTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{	
	if ([value intValue] == 0) {
		return @"About 350MB per hour of show time.";
	} else if ([value intValue] == 1) {
		return @"About 700MB per hour of show time.";
	} else if ([value intValue] == 2) {
		return @"About 1.2GB per hour of show time.";
	} else {
		return @"No selection.";
	}
}
@end

@implementation DetailToStringTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( ( nil == [value objectForKey:@"Subscribed"]) || [[value objectForKey:@"Subscribed"] boolValue] ) {
		if ( [[value objectForKey:@"Type"] isEqualToString:@"SeasonEpisodeType"] ) {
			return [NSString stringWithFormat:@"Season %@, Ep %@",[value objectForKey:@"Season"],[value objectForKey:@"Episode"]];
		} else if ( [[value objectForKey:@"Type"] isEqualToString:@"DateType"] ) {
			NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
			[df setDateStyle:NSDateFormatterMediumStyle];
			[df setTimeStyle:NSDateFormatterNoStyle];
			return [df stringFromDate:[value objectForKey:@"Date"]];
		} else if ( [[value objectForKey:@"Type"] isEqualToString:@"TimeType"] ) {
			if ( [value objectForKey:@"Title"] ) {
				return [value objectForKey:@"Title"];
			} else {
				NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
				[df setDateStyle:NSDateFormatterMediumStyle];
				[df setTimeStyle:NSDateFormatterShortStyle];
				return [df stringFromDate:[value objectForKey:@"Time"]];
			}
		}
	}
	return @"";
}
@end

@implementation DateToShortDateTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterShortStyle];
	return [df stringFromDate:value];
}
@end