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


#import "TSCollectionView.h"
#import "TheTVDB.h"


@implementation TSCollectionView

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object
{
	
    // Get a copy of the item prototype, set represented object.
    NSCollectionViewItem *newItem = [[self itemPrototype] copy];
    [newItem setRepresentedObject:object];
	
    // Set the show poster now that we have the object
	[object setValue:[TheTVDB getPosterForShow:[object valueForKey:@"name"]
									withHeight:96
									 withWidth:66] forKey:@"showPoster"];
	
	// Return the newly created CollectionViewItem
    return newItem;
}

@end
