# About
TVShows 2 "_Phoenix_" is the next version of [TVShows][tvshows], the easiest way to download your favorite shows automatically. It includes a completely rewritten codebase as well as a major overhaul of the UI and a move to System Preferences. _Phoenix_ is currently in the late stages of development but I am always open to any feature suggestions.

## Screenshots
<a href="http://embercode.com/blog/category/tvshows-news/" title="TVShows News">![Getting Started][preview-1] ![About][preview-2] ![Preferences][preview-3]</a>

## Collaboration Notes
* The current TVShows Roadmap can be found [here][roadmap] -- all issue numbers in commits refer to those in the Roadmap.
* Compiling TVShows will require you to download all submodules:
    * `$ git submodule init`
    * `$ git submodule update`
* Modifying the interface will require the [BWToolkit][bwtoolkit] IB plugin. It can be found in the `IB Plugins` folder.
* By default, the Debug configuration automatically installs TVShows into `~/Library/PreferencePanes/` each time it's built.

## Planned Features
* Custom RSS feeds
* Support for NZBs.org
* Better support for non-standard naming conventions
* Display show and episode information
* The ability to download subtitles for new episodes
* Localized languages for non-English users ([read more][translate])
* Growl notifications for new downloads

## License
TVShows is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For a copy of the GNU General Public License see &lt;[http://www.gnu.org/licenses/][license]&gt;.

[tvshows]:http://embercode.com/tvshows/ "TVShows Website"
[translate]:http://embercode.com/blog/2010/help-translate-tvshows-2/ "Help Translate TVShows 2"
[roadmap]:http://labs.embercode.com/projects/tvshows/roadmap "TVShows Roadmap"

[preview-1]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r175_Preview-300x201.png "TVShows 2 (r175) Preview"
[preview-2]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r191_AboutTeaser-300x201.png "TVShows 2 Teaser: About Tab"
[preview-3]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r191_PrefTeaser-300x243.png "TVShows 2 Teaser: Preferences"

[bwtoolkit]:http://www.brandonwalkin.com/bwtoolkit/ "BWToolkit Information"
[license]:http://www.gnu.org/licenses/ "GNU General Public License"