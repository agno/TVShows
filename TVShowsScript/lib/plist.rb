#--
##############################################################
# Copyright 2006, Ben Bleything <ben@bleything.net> and      #
# Patrick May <patrick@hexane.org>                           #
#                                                            #
# Distributed under the MIT license.                         #
##############################################################
#++
# = Plist
#
# This is the main file for plist.  Everything interesting happens in Plist and Plist::Emit.

require 'base64'
require 'cgi'
require 'stringio'

require File.join(File.dirname(__FILE__), 'plist/generator')
require File.join(File.dirname(__FILE__), 'plist/parser')

module Plist
  VERSION = '3.0.0'
end
