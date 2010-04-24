/*
 *	This file is part of the TVShows 2 ("Phoenix") source code.
 *	http://github.com/mattprice/TVShows/tree/Phoenix
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

#import "WindowController.h"
#import "FeedParser.h"


@implementation WindowController

- (IBAction)showRssFeed:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSError * error;
	NSURL * url = [NSURL URLWithString:@"http://antwrp.gsfc.nasa.gov/apod.rss"];
	NSData * data = [NSData dataWithContentsOfURL:url];
	FPFeed * feed = [FPParser parsedFeedWithData:data error:&error];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Title: %@\n", feed.title]];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Description: %@\n", feed.feedDescription]];
	[mainTextView insertText:[NSString
			stringWithFormat:@"Date published: %@\n\n", [feed.pubDate description]]];
	for (FPItem * item in feed.items)
	{
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Title: %@\n", item.title]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Link: href:%@ \t + rel: %@ + \t type: %@ \t + title:%@\n", item.link.href, item.link.rel, item.link.type, item.link.title]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item GUID: %@\n", item.guid]];  
		[mainTextView insertText:[NSString
				stringWithFormat:@"\t Item Description: %@\n", item.description]];  
	}
	[pool drain];
}

@end
