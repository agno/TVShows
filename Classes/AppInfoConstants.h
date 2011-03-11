/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/mattprice/TVShows/
 *
 *  TVShows is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with TVShows. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#define TVShowsAppDomain            @"com.embercode.TVShows2"
#define TVShowsHelperDomain         @"com.embercode.TVShowsHelper"
#define TVShowsWebsite              @"http://embercode.com/tvshows/"
#define TVShowsTwitter              @"http://twitter.com/embercode/"
#define TVShowsAppcastURL           @"http://embercode.com/updates/tvshows.xml"
#define TVShowsBetaAppcastURL       @"http://embercode.com/updates/tvshows-beta.xml"

// This is a TVShows specific API key. Please DO NOT reuse it.
// You can get your own at http://thetvdb.com/?tab=apiregister
#define API_KEY                     @"E455EEEEFF5E6E2B"

// Used in the Delegate methods so that we don't have to duplicate files.
#if PREFPANE
    #define CurrentBundleDomain     @"com.embercode.TVShows2"
#elif HELPER_APP
    #define CurrentBundleDomain     @"com.embercode.TVShowsHelper"
#endif