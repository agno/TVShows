/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
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

@interface IndexesToIndexTransformer : NSValueTransformer {
}
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
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