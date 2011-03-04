# About
TVShows 2 is the next version of [TVShows][tvshows], the easiest way to download your favorite shows automatically. It includes a completely rewritten codebase as well as a major overhaul of the UI and a move to System Preferences.

## Screenshots
<a href="http://embercode.com/blog/category/tvshows-news/" title="TVShows News">![Getting Started][preview-1] ![About][preview-2] ![Preferences][preview-3]</a>

<!-- ## Translations
* Help localize TVShows 2 into your native language! [Click here][translate] ([more info][translate-info]) to be added to the translation team. -->

## Collaboration Instructions
1. Checkout the repository:
    * `$ git clone http://github.com/mattprice/TVShows.git`
1. Download all the required submodules:
    * `$ cd TVShows`
    * `$ git submodule init`
    * `$ git submodule update`
1. Install the [BWToolkit][bwtoolkit] IB plugin if you haven't before. It can be found in the `IB Plugins` folder.

## Collaboration Notes
* You can also use GitHub's forking feature to make changes and then send me a pull request.
* By default, the Debug configuration automatically installs TVShows into `~/Library/PreferencePanes/` each time it's built.

## License
TVShows is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For a copy of the GNU General Public License see &lt;[http://www.gnu.org/licenses/][license]&gt;.

[tvshows]:http://embercode.com/tvshows/ "TVShows Website"
[translate]:https://webtranslateit.com/en/projects/874-TVShows-2/invitation_request "Help Translate TVShows 2"
[translate-info]:http://embercode.com/blog/2010/help-translate-tvshows-2/ "Help Translate TVShows 2"

[preview-1]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r175_Preview-300x201.png "TVShows 2 (r175) Preview"
[preview-2]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r191_AboutTeaser-300x201.png "TVShows 2 Teaser: About Tab"
[preview-3]:http://embercode.com/blog/wp-content/uploads/2010/05/TVShows2_r191_PrefTeaser-300x243.png "TVShows 2 Teaser: Preferences"

[bwtoolkit]:http://www.brandonwalkin.com/bwtoolkit/ "BWToolkit Information"
[license]:http://www.gnu.org/licenses/ "GNU General Public License"