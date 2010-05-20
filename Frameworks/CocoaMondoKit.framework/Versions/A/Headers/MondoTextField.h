//  Copyright (c) MMIX Matthieu Cormier. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided 
//  that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the 
//      following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and 
//      the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Matthieu Cormier nor the names of its contributors may be used to endorse or promote 
//      products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT,  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
//  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#import <Cocoa/Cocoa.h>

@interface MondoTextField : NSTextField {

  // The title for the zoom window can be set in one of two places.
  //
  // 1. You can directly set "Window Title" in inspector field attributes
  // tab in Interface Builder. 
  //
  // 2. You can bind to an NSTextField.  
  //
  // When setting the title of the zoomed window, option 1 is checked and then option 2.
  // If all else fails the title is blank.  See the logic in the fieldLabel method.
  //
  NSString *windowTitle;
  IBOutlet NSTextField* windowTitleTextField;
  
@private  
  // Stores the font information.   
  // Used for calculating the length of the displayed string.
  NSDictionary	*_attrDict;  
}

@property(retain) NSString* windowTitle;

- (NSString*) fieldLabel;

@end
