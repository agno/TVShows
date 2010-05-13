# About
TVShows 2 "_Phoenix_" is the next version of [TVShows](http://deathtobunnies.com/tvshows/), the easiest way to download torrents of your favorite shows automatically. It includes a completely rewritten codebase as well as a major overhaul of the UI and a move to System Preferences. _Phoenix_ is currently in the beginning stages of development but I am always open to any feature suggestions.

## Notes on Compiling
* TVShows uses the Clang compiler by default. If you are building TVShows on OS 10.4 you'll need to change the compiler in the project settings.
* There are two different build targets: TVShows and TVShows (Tiger). Please make sure you've selected the correct build.
	* Be sure to Clean All targets before swapping between builds.
	* If anyone can find a workaround to compiling two different builds feel free to let me know.
* By default, the Debug configuration automatically installs TVShows into `~/Library/PreferencePanes/` each time it's built.

## Planned Features
* Custom RSS feeds
* Support for NZB files
* Better support for non-standard naming conventions
* Display show and episode information
* Localized languages for non-English users
* Growl notifications for new downloads
* (?) <del>Multiple sources for each RSS feed</del>
* (?) <del>Feed categories: shows, music, podcasts, etc</del>

## License
TVShows is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For a copy of the GNU General Public License see <http://www.gnu.org/licenses/>.