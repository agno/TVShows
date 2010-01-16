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
	File.join(File.dirname(__FILE__), 'TVShowsScript/lib/simple-rss.rb'),
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

if ( ARGV.length != 1 ) then
	die("Usage: GetShowDetails.rb RSSLink")
	exit(-1)
end
requires.each { |r|
	begin
		die("Could not load #{r}") unless require r
	rescue => e
		printException(e)
	end
}

class Show
	def initialize(links)
		@feed = links
	end
	
	def getDetails
		url = @feed
		begin
			rawEpisodes = SimpleRSS.parse(open(url))
		rescue => exception
			printError("Could not connect to ezrss.it (#{exception.message})")
			raise "GetShowDetailsError"
		end
		
		episodesBySeasonAndEpisodeNumber = []
		episodesByDate = []
		episodesByTitle = []
		
		blockedTorrents = ["http://torrent.zoink.it/CSI.New.York.S07E03.HDTV.XviD-LOL.%5Beztv%5D.torrent", "http://www.bt-chat.com/download1.php?info_hash=6f22dae012c3563508141cbc6fec3fcffd9e8cd3", "http://torrent.zoink.it/Doctor.Who.2005.The.Waters.Of.Mars.2009.Special.HDTV.XviD-FoV.%5Beztv%5D.torrent", "http://torrent.zoink.it/Doctor.Who.2005.The.Waters.Of.Mars.2009.Special.720p.HDTV.x264-FoV.%5Beztv%5D.torrent", "http://torrent.zoink.it/Doctor.Who.2005.S04.Special.The.End.Of.Time.Part1.720p.HDTV.x264-BiA.%5Beztv%5D.torrent","http://torrent.zoink.it/Doctor.Who.2005.S04.Special.The.End.Of.Time.Part2.720p.HDTV.x264-BiA.%5Beztv%5D.torrent"]
		
		rawEpisodes.items.each do |episode|
			
			#nameMatch		= /Show\ Name\s*:\ (.*?);/.match(episode.description)[1].sub(/\/|:/,'-')
			titleMatch		= /Show\s*Title\s*:\s*(.*?);/.match(episode.description)
			seasonNoMatch	= /Season\s*:\s*([0-9]*?);/.match(episode.description)
			episodeNoMatch	= /Episode\s*:\s*([0-9]*?)$/.match(episode.description)
			dateMatch		= /Episode\s*Date:\s*([0-9\-]+)$/.match(episode.description)
			
			torrentURL = episode.link.gsub(/\[/, '%5B').gsub(/\]/, '%5D')
			
			if ( blockedTorrents.include?(torrentURL) )
				printError("The torrent #{torrentURL} was blocked.")
			else
  			if ( !seasonNoMatch.nil? and !episodeNoMatch.nil? ) then
  				# Season/episode style of show (eg: Lost)
				
  				s = seasonNoMatch[1].to_i
  				e = episodeNoMatch[1].to_i
  				t = episode.pubDate
				
  				if ( episodesBySeasonAndEpisodeNumber.find_all { |ep| ep[SHOW_SEASON] == s and ep[SHOW_EPISODE] == e and (ep[SHOW_TIME] <=> t) > 0 }.length == 0 ) then
  					episodesBySeasonAndEpisodeNumber << {
  						SHOW_SEASON => s,
  						SHOW_EPISODE => e,
  						SHOW_TIME => t,
  						SHOW_TYPE => TYPE_SEASONEPISODE
  					}
  				end
				
        elsif ( !dateMatch.nil? )
  				# Date style of show (eg: The Daily Show)
				
  				begin
  					d = Time.parse(dateMatch[1])
  					t = episode.pubDate
				
  					if ( episodesByDate.find_all { |ep| ep[SHOW_DATE] == d and (ep[SHOW_TIME] <=> t) > 0 }.length == 0 ) then
  						episodesByDate << {
  							SHOW_DATE => d,
  							SHOW_TIME => episode.pubDate,
  							SHOW_TYPE => TYPE_DATE
  						}
  					end
  				  rescue Exception => e
  				end
				
  			elsif ( !titleMatch.nil? and titleMatch[1] != "n/a")
  				# Get-all-episodes style of show (eg: Discovery Channel)
  				ti = titleMatch[1]
  				t = episode.pubDate
				
  				if ( episodesByTitle.find_all { |ep| ep[SHOW_TIME] == ti and (ep[SHOW_TIME] <=> t) > 0 }.length == 0 ) then
  					episodesByTitle << {
  						SHOW_TITLE => titleMatch[1],
  						SHOW_TIME => episode.pubDate,
  						SHOW_TYPE => TYPE_TIME
  					}
  				end
  			  else
  				  # Should not happen
  				  printError("Could not categorize episode.")
  			end
			end
			
		end
    
		return [episodesBySeasonAndEpisodeNumber,episodesByDate,episodesByTitle].max{|a,b| a.length<=>b.length}.to_plist
	end
	
end

begin
	$stdout.puts Show.new(ARGV[0]).getDetails
rescue Timeout::Error, Exception => e
	printError("GetShowDetails Error: (#{e.inspect})")
	exit(1)
end

exit(0)