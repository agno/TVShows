#!/usr/bin/env ruby

# This file is part of the TVShows source code.
# http://tvshows.sourceforge.net
# It may be used under the terms of the GNU General Public License.

requires = [
	'open-uri',
	File.join(File.dirname(__FILE__), 'TVShowsScript/TVShowsConstants.rb'),
	File.join(File.dirname(__FILE__), 'TVShowsScript/lib/plist.rb')
]

def die(message,exitstatus = 1)
	$stderr.puts "TVShows Error: #{message}"
	exit(exitstatus)
end
def printError(message)
	$stderr.puts "TVShows Error: #{message}"
end
def printException(exception)
	$stderr.puts "TVShows Error: #{exception.inspect}\n\t#{exception.backtrace.join("\n\t")}"
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
			data = open("http://ezrss.it/shows")
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

	# Merge
	if ( File.exists?(path) ) then
		begin
			knownShows = Plist::parse_xml(path)
		rescue => e
			printException(e)
			exit(1)
		end
		
		if !knownShows.nil? then
			showsToAdd = []
			shows["Shows"].each { |show|
				if ( !knownShows["Shows"].find{|ks| ks["ExactName"] == show["ExactName"]} ) then
					showsToAdd << show
				end
			}
		
			knownShows["Shows"] += showsToAdd
			knownShows["Version"] = version
			shows = knownShows
		end
	end

	shows["Shows"] = shows["Shows"].sort_by{ |s| s["HumanName"] }
	shows.save_plist(path)

rescue Exception, Timeout::Error => e
	printException(e) 
	exit(1)
end

exit(0)