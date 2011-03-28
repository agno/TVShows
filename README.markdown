# About
TVShows 2 is the next version of [TVShows][tvshows], the easiest way to download your favorite shows automatically. It includes a completely rewritten codebase as well as a major overhaul of the UI and a move to System Preferences.

No actual videos are downloaded by TVShows, only torrents which require other programs to use. It is up to the user to decide the legality of using any files downloaded by this application, in accordance with applicable copyright laws of their country.

## Screenshots
<a href="http://embercode.com/blog/category/tvshows-news/" title="TVShows News">![Show List][preview-1]&nbsp;&nbsp;![Subscriptions][preview-2]&nbsp;&nbsp;![Show Info][preview-3]</a>

<!-- ## Translations
* Help localize TVShows 2 into your native language! [Click here][translate] ([more info][translate-info]) to be added to the translation team. -->

## Collaboration Instructions
1. Checkout the repository:
    * `$ git clone http://github.com/mattprice/TVShows.git`
1. Download all the required submodules:
    * `$ cd TVShows`
    * `$ git submodule init`
    * `$ git submodule update`

## Collaboration Notes
* You can also use GitHub's forking feature to make changes and then send me a pull request.
* By default, the Debug configuration automatically installs TVShows into `~/Library/PreferencePanes/` each time it's built.
* Xcode 4 users will need to make sure the 10.5 SDK is in `/Developer/SDKs/`. Install Xcode 3 first if you do not have it, or change the target OS version.

## Roadmap
### Beta 6
* Download episode names.
* Add a loading bar to the show list and show info window.
* Fade out subscribed shows from the show list.
* Fade out "disabled" shows.
* Make it more obvious what's happening with SD/HD episodes.
* Fix the two shows who have no posters, but don't display the placeholder.

### Beta 7
* Add a list view to the Subscriptions tab.
* Use NSTask for downloading torrents, posters, and descriptions.

## License
TVShows is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For a copy of the GNU General Public License see &lt;[http://www.gnu.org/licenses/][license]&gt;.

[tvshows]:http://embercode.com/tvshows/ "TVShows Website"
[translate]:https://webtranslateit.com/en/projects/874-TVShows-2/invitation_request "Help Translate TVShows 2"
[translate-info]:http://embercode.com/blog/2010/help-translate-tvshows-2/ "Help Translate TVShows 2"

[preview-1]:http://embercode.com/_tvshows/screenshots/show-list_small.png "TVShows 2: Show List"
[preview-2]:http://embercode.com/_tvshows/screenshots/subscriptions_small.png "TVShows 2: Subscriptions"
[preview-3]:http://embercode.com/_tvshows/screenshots/show-info_small.png "TVShows 2: Show Info Window"

[license]:http://www.gnu.org/licenses/ "GNU General Public License"