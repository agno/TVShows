/*
 This file is part of the TVShows source code.
 http://github.com/mattprice/TVShows

 TVShows is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
*/

#import <Cocoa/Cocoa.h>

@interface NonZeroValueTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface DownloadBooleanToTitleTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface EnabledToImagePathTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface EnabledToStringTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface PathToNameTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface QualityIndexToLabelTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface DetailToStringTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end

@interface DateToShortDateTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end