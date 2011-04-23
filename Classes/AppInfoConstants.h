/*
 *  This file is part of the TVShows 2 ("Phoenix") source code.
 *  http://github.com/victorpimentel/TVShows/
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

#define TVShowsAppDomain            @"com.victorpimentel.TVShows2"
#define TVShowsHelperDomain         @"com.victorpimentel.TVShowsHelper"

#define TVShowsWebsite              @"http://victorpimentel.com/tvshows/"
#define TVShowsTwitter              @"http://twitter.com/TVShows2/"
#define TVShowsDonations            @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=2PARRGESKRQJ6&item_name=TVShows2&item_number=TVShows2&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"

#define TVShowsAppcastURL           @"http://victorpimentel.com/tvshows/tvshows.xml"
#define TVShowsBetaAppcastURL       @"http://victorpimentel.com/tvshows/tvshows-beta.xml"

// This is a TVShows specific API key. Please DO NOT reuse it.
// You can get your own at http://thetvdb.com/?tab=apiregister
#define API_KEY                     @"BB420D2FDA505290"

// Used in the Delegate methods so that we don't have to duplicate files.
#if PREFPANE
    #define CurrentBundleDomain     @"com.victorpimentel.TVShows2"
#elif HELPER_APP
    #define CurrentBundleDomain     @"com.victorpimentel.TVShowsHelper"
#endif