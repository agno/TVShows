#!/usr/bin/env ruby

# This file is part of the TVShows source code.
# http://github.com/mattprice/TVShows

# TVShows is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

requires = [
	'open-uri',
	File.join(File.dirname(__FILE__), 'TVShowsScript/TVShowsConstants.rb'),
	File.join(File.dirname(__FILE__), 'TVShowsScript/lib/plist.rb')
]

def die(message)
	time = Time.new
	$stderr.puts "#{time.strftime("%m/%d/%y %H:%M:%S")}\tTVShows Error: #{message}"
	exit(-1)
end
def printError(message)
	time = Time.new
	$stderr.puts "#{time.strftime("%m/%d/%y %H:%M:%S")}\tTVShows Error: #{message}"
end
def printException(exception)
	time = Time.new
	$stderr.puts "#{time.strftime("%m/%d/%y %H:%M:%S")}\tTVShows Error: #{exception.inspect}\n\t#{exception.backtrace.join("\n\t")}"
end

requires.each { |r|
	begin
		die("Could not load #{r}") unless require r
	rescue => e
		printException(e)
	end
}

exit(2) if ( ARGV.length != 2 )

begin

	path = ARGV[0]
	version = ARGV[1]

	shows = {
		"Shows" => [],
		"Version" => version
	}

	data = nil
	3.times { |n|
		begin
			data = open("http://ezrss.it/shows/")
			break
		rescue Exception, Timeout::Error => e
			printError("Failed to download the list, retrying...")
		end
	}
	
	raise "Data is nil." if data.nil?	
	
	data.read.scan(/show_name=(.*?)&amp;show_name_exact=true\">(.*?)</i).each { |show|
		shows["Shows"] << {
			"ExactName"		=> show[0],
			"HumanName"		=> show[1],
			"Subscribed"	=> false,
			"Type"			=> ""
		}
	}

	list1 = ["A+Colbert+Christmas+++The+Greatest+Gift+of+All+%28", "The+Colbert+Report+08+Aug+07+%28", "The+Colbert+Report+08+Jan+08+%28", "The+Colbert+Report+16+May+07+%28", "The+Colbert+Report+4+Mar+08+%28", "The+Daily+Show+04+Jun+07+%28", "The+Daily+Show+08+Jan+08+%28", "The+Daily+Show+11+Oct+07+%28", "The+Daily+Show+3+Mar+08+%28", "The+Daily+Show+4+Mar+08+%28", "Doctor+Who+S04+Christmas+Special+%28", "How+I+Met+Your+Mother+%28", "The+Lost+Room+Part+1+%28", "The+Lost+Room+Part+2+%28", "The+Lost+Room+Part+3+%28", "Red+Dwarf+S9+Special+%28", "Wire+in+the+Blood+S5+Special+%28", "Without+a+Trace+%28"]
	list2 = ["Little+Britain+Xmas+Special+Part1", "Little+Britain+Xmas+Special+Part2", "Lost+S03+The+Answers", "Lost+S05+A+Journey+In+Time+Recap+Special", "Lost+Missing+Pieces+E10+Jack+Meet+Ethan", "Lost+Survival+Guide", "Lost+Uncovered", "The+Last+Templar+Part1", "The+Last+Templar+Part2", "The+Last+Templar+Pt+2", "The+Last+Templar+Pt+I", "The+Last+Templar+Pt+II+PROPER"]

	blockedShows = list1 + list2

	# Merge
	if (File.exists?(path)) then
		begin
			knownShows = Plist::parse_xml(path)
		rescue => e
			printException(e)
			exit(1)
		end
		
		if !knownShows.nil? then
			showsToAdd = []
			shows["Shows"].each { |show|
				if (!knownShows["Shows"].find{|ks| ks["ExactName"] == show["ExactName"]}) then
					showsToAdd << show
				end
			}
		
			knownShows["Shows"] += showsToAdd
			knownShows["Version"] = version

			blockedShows.each_index { |x|
				knownShows["Shows"].delete_if {|ks| ks["ExactName"] == blockedShows[x]}
			}

			shows = knownShows
		end
	end

	shows["Shows"] = shows["Shows"].sort_by{ |x| x["HumanName"].sub(/^(the)\s/i, '').downcase }
	shows.save_plist(path)

rescue Exception, Timeout::Error => e
	printException(e) 
	exit(1)
end

exit(0)