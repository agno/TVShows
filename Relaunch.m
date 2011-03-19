/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/mattprice/TVShows/
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

#import <Cocoa/Cocoa.h>
#import "TVShows_Prefix.pch"

// Thanks to Matt Patenaude and his blog post on how to relaunch an application.
// Slightly modified to work with a Preference Pane.
// http://iloveco.de/relaunching-your-application/

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    pid_t parentPID = atoi(argv[3]);
    ProcessSerialNumber psn;
    while (GetProcessForPID(parentPID, &psn) != procNotFound)
        sleep(1);
    
    NSString *appPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    NSString *prefPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
    BOOL success = [[NSWorkspace sharedWorkspace] openFile:[prefPath stringByExpandingTildeInPath]
                                           withApplication:[appPath stringByExpandingTildeInPath]];
    
    if (!success)
        NSLog(@"Could not relaunch application at %@", appPath);
    
    [pool drain];
    return (success) ? 0 : 1;
}