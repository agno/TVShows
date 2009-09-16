#!/usr/bin/env ruby

# This file is part of the TVShows source code.
# http://tvshows.sourceforge.net
# It may be used under the terms of the GNU General Public License.

require File.join(File.dirname(__FILE__), 'TVShowsScript/lib/simple-rss.rb')
require 'open-uri'

begin
	feed = "http://ezrss.it/search/index.php?show_name=%s&show_name_exact=true&mode=rss"
	url = feed % ARGV[0]
	begin
		episodes = SimpleRSS.parse(open(url))
	rescue => exception
		exit(-1)
	end
	
	maxSeason = 0
	maxEpisode = 0
	episodes.items.each do |episode|
		seasonNoMatch = /Season\s*:\ ([0-9]*?);/.match(episode.description)
		if ( !seasonNoMatch.nil? ) then
			seasonNo = seasonNoMatch[1].to_i
			episodeNoMatch = /Episode\s*:\ ([0-9]*?)$/.match(episode.description)
			if ( !episodeNoMatch.nil? ) then
				episodeNo = episodeNoMatch[1].to_i
				if ( (maxSeason == seasonNo and maxEpisode < episodeNo) or (maxSeason < seasonNo) ) then
					maxSeason = seasonNo
					maxEpisode = episodeNo
				end
			end
		end
	end

	print "#{maxSeason}-#{maxEpisode}"

	exit(0)
rescue
	exit(-1)
end
