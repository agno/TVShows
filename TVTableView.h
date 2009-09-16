/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#import <Cocoa/Cocoa.h>

@interface TVTableView : NSTableView {

}

- (void) highlightSelectionInClipRect:(NSRect)rect;
- (void) drawStripesInRect:(NSRect)clipRect;

@end
