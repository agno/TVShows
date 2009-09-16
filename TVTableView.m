/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

/* Thanks http://developer.apple.com/samplecode/MP3_Player/index.html */

#import "TVTableView.h"

#define SoftGreenRed	(169.0 / 255.0)
#define SoftGreeGreen	(191.0 / 255.0)
#define SoftGreenBlue	(098.0 / 255.0)
static NSColor *sStripeColor = nil;

@class Controller;

@implementation TVTableView

// This is called after the table background is filled in, but before the cell contents are drawn.
- (void) highlightSelectionInClipRect:(NSRect)rect
{
    [self drawStripesInRect:rect];
    [super highlightSelectionInClipRect:rect];
}

- (void) drawStripesInRect:(NSRect)clipRect
{
	//NSLog(@"(%f,%f)->(%f,%f)",clipRect.origin.x,clipRect.origin.y,clipRect.size.width,clipRect.size.height);
    NSRect stripeRect;
    int rowIndex = 0;
	float fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
    float clipBottom = NSMaxY(clipRect);
    int firstStripe = clipRect.origin.y / fullRowHeight;
    stripeRect.origin.x = clipRect.origin.x;
    stripeRect.origin.y = firstStripe * fullRowHeight;
    stripeRect.size.width = clipRect.size.width;
    stripeRect.size.height = fullRowHeight;
    // set the color
    if (sStripeColor == nil)
        sStripeColor = [[NSColor colorWithCalibratedRed:SoftGreenRed green:SoftGreeGreen blue:SoftGreenBlue alpha:1.0] retain];
    [sStripeColor set];
    // and draw the stripes
	while (stripeRect.origin.y < clipBottom) {
        if ( [(Controller *)[self delegate] shouldGreenRowAtIndex:(int)(stripeRect.origin.y/fullRowHeight)] ) {
			NSRectFill(stripeRect);
		}
        stripeRect.origin.y += fullRowHeight;
		rowIndex++;
    }
}
@end
