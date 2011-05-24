/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/victorpimentel/TVShows/
 *
 *  TVShows is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with TVShows. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "WebsiteFunctions.h"
#import <SystemConfiguration/SCNetworkReachability.h>


@implementation WebsiteFunctions

// Currently broken if the user has OpenDNS or similar
+ (BOOL) canConnectToHostname:(NSString *)hostName {
    SCNetworkConnectionFlags flags;
    
    if (SCNetworkCheckReachabilityByName([hostName UTF8String], &flags) && flags > 0) {
        return TRUE;
    } else {
        return FALSE;
    }
}

+ (NSData *) downloadDataFrom:(NSString *)url
{
    // Set a restrictive timeout
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:10.0];
    
    // Get the data
    return [NSURLConnection sendSynchronousRequest:request
                                 returningResponse:nil
                                             error:nil];
}

+ (NSString *) downloadStringFrom:(NSString *)url
{
    // Get the data
    NSString *content = [[[NSString alloc] initWithData:[WebsiteFunctions downloadDataFrom:url]
                                               encoding:NSUTF8StringEncoding] autorelease];
    
    return content;
}

@end
