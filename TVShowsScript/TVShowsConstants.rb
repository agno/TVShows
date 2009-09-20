# This file is part of the TVShows source code.
# http://github.com/mattprice/TVShows

# TVShows is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

PREFS_IS_ENABLED					= "IsEnabled"
PREFS_AUTOMATICALLY_OPEN_TORRENT	= "AutomaticallyOpenTorrent"
PREFS_TORRENT_FOLDER				= "TorrentFolder"
PREFS_QUALITY						= "Quality"
PREFS_SCRIPTVERSION					= "ScriptVersion"
PREFS_LASTVERSIONCHECK				= "SULastCheckTime"

TYPE_SEASONEPISODE					= "SeasonEpisodeType"	# Shows organised by season/episode (eg: Lost)
TYPE_DATE							= "DateType"			# Shows organised by date (eg: The Daily Show)
TYPE_TIME							= "TimeType"			# Shows not organised at all (eg: Dicovery Channel), so we organize them by published time
                            		
SHOWS_SHOWS							= "Shows"
SHOWS_VERSION						= "Version"
SHOW_HUMANNAME						= "HumanName"
SHOW_EXACTNAME						= "ExactName"
SHOW_EPISODE						= "Episode"
SHOW_SEASON							= "Season"
SHOW_SUBSCRIBED						= "Subscribed"
SHOW_DATE							= "Date"
SHOW_TITLE							= "Title"
SHOW_TYPE							= "Type"
SHOW_TIME							= "Time"

FEED = "http://ezrss.it/search/index.php?show_name=%s&show_name_exact=true&mode=rss"
REQUIRED_KEYS = [SHOW_HUMANNAME,SHOW_EXACTNAME,SHOW_SUBSCRIBED,SHOW_TYPE]
QUALITIES = [
	[/\[HD/,/\[DSRIP/,/\[TVRIP/,/\[PDTV/,/\[DVD/],
	[/\[HR/],
	[/\[720p/i]
]

VERSIONCHECK_VERSIONPLIST = "/System/Library/CoreServices/SystemVersion.plist"
VERSIONCHECK_URL = "http://deathtobunnies.com/tvshows/appcast.xml"