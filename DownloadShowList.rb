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
			data = open("http://ezrss.it/shows/")
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

	# Specials, non-Shows, misnamed, etc.
	list1 = ["A+Colbert+Christmas+++The+Greatest+Gift+of+All+%28", "A+Very+British+Gangster", "A+Very+British+Gangster+Extras", "ABC+A+Machine+to+Die+For+The+Quest+for+Free+Energy", "ABC+Dinosaurs+on+Ice", "Afghanistan+Drugs+Guns+And+Money", "Aftermath+Population+Zero", "American+Chopper+Eragon+Bike+Pt1", "American+Gangster+HBO+First+Look", "American+Gladiators", "Americans+in+Paris", "Americas+Deadliest+Prison+Gang", "Americas+Funniest+Home+Videos+S", "Americas+Next+Top+Model+Exposed+Part+2", "Americas+Next+Top+Model+Exposed+Part1", "Anchorwoman", "Ancient+Discoveries+Mega+Machines", "Animal+Planet+Buggin+with+Ruud+Alaskan+Bugs+on+Ice", "Animal+Planet+Buggin+with+Ruud+Bug+Cloud+9", "Antarctica+Dreaming+Wildlife+on+Ice", "Antarctica+Dreaming+Wildlife+on+Ice+Extra+Antarctic+Peninsula+South+Georgia+Island+and+the+Falkland+Island", "Antarctica+Dreaming+Wildlife+on+Ice+Extra+Narration+Removed", "Austin+City+Limits", "Australian+Geographic+Best+of+Australia+Tropical+North+Queensland", "The+Andromeda+Strain", "The+Apprentice+UK+S03+The+Final", "The+Apprentice+UK+S04+Special+The+Worst+Decisions+Ever", "The+Apprentice+UK+S04+Special+Why+I+Fired+Them", "The+Art+of+Barbara+Hepworth", "The+Art+of+Eric+Gill", "The+Art+of+Francis+Bacon", "The+Art+of+Helen+Chadwick", "The+Art+of+Henry+Moore", "Baftas", "Barack+Obama+Presidential+Victory+Speech", "Battlestar+Galactica+Razor", "Battlestar+Galactica+Revealed", "Battlestar+Galactica+The+Last+Frakkin+Special", "Battlestar+Galactica+The+Phenomenon", "Battlestar+Galactica+The+Top+10+Things+You+Need+To+Know", "BBC", "BBC+2008+After+Rome+Holy+War+and+Conquest", "BBC+Alfred+Brendel+Man+and+Mask", "BBC+Amazon+With+Bruce+Parry", "BBC+Black+Power+Salute", "BBC+Castrato", "BBC+Charles+Darwin+and+the+Tree+of+Life", "BBC+Charles+Rennie+Mackintosh+The+Modern+Man", "BBC+Coast+And+Beyond+Series+4", "BBC+Dan+Cruickshanks+Adventures+in+Architecture", "BBC+Darwin", "BBC+Darwins+Struggle+The+Evolution+of+the+Origin+of+Species", "BBC+Did+Darwin+Kill+God", "BBC+Earth+The+Power+Of+The+Planet", "BBC+Earth+Power+of+the+Planet", "BBC+Earth+The+Climate+Wars", "BBC+Electric+Dreams", "BBC+Francescos+Mediterranean+Voyage", "BBC+Future+of+Food", "BBC+Hardcore+Profits", "BBC+Horizon", "BBC+Horizon+How+Mad+Are+You", "BBC+Hotel+California+LA+from+the+Byrds+to+the+Eagles", "BBC+Joanna+Lumley+In+the+Land+of+the+Northern+Lights+DVB+x", "BBC+Johnny+Cash+The+Last+Great+American", "BBC+Law+and+Disorder", "BBC+Life+In+Cold+Blood", "BBC+Lightning+Nature+Strikes+Back", "BBC+Lost+Horizons+The+Big+Bang", "BBC+Lost+Land+of+the+Volcano", "BBC+Medieval+Lives", "BBC+Medieval+Lives+Extra+Gladiators+The+Brutal+Truth", "BBC+Montezuma", "BBC+Natural+World", "BBC+Natures+Great+Events", "BBC+OCEANS", "BBC+Pedigree+Dogs+Exposed", "BBC+Russia+A+Journey+with+Jonathan+Dimbleby", "BBC+Shroud+of+Turin+x", "BBC+South+Pacific", "BBC+Stuart+Sutcliffe+The+Lost+Beatle", "BBC+The+American+Future+A+History+1of4+American+Plenty", "BBC+The+American+Future+A+History+2of4+American+War", "BBC+The+American+Future+A+History+3of4+American+Fervour", "BBC+The+American+Future+A+History+4of4+What+is+an+American", "BBC+The+Atheism+Tapes", "BBC+The+Big+Bang+Machine", "BBC+The+Cell", "BBC+The+Darwin+Debate", "BBC+The+Flapping+Track", "BBC+The+Frankincense+Trail", "BBC+The+Harp", "BBC+The+Incredible+Human+Journey", "BBC+The+Last+Nazis", "BBC+The+Life+And+Death+of+a+Mobile+Phone", "BBC+The+Life+and+Times+of+El+Nino", "BBC+The+Link+Uncovering+Our+Earliest+Ancestor", "BBC+The+Lost+World+of+Tibet", "BBC+The+Love+of+Money", "BBC+The+Machine+that+Made+Us", "BBC+The+Mark+Steel+Lectures+Charles+Darwin", "BBC+The+Podfather", "BBC+The+Pre+Raphaelites", "BBC+The+Private+Life+of+a+Masterpiece+Masterpieces+1800+to+1850", "BBC+The+Private+Life+of+a+Masterpiece+Masterpieces+1851+to+1900", "BBC+The+Private+Life+of+a+Masterpiece+Renaissance+Masterpieces", "BBC+The+Private+Life+of+a+Masterpiece+Seventeenth+Century+Masters", "BBC+The+Secret+Life+Of+Elephants", "BBC+The+Sky+at+Night", "BBC+The+Story+of+India", "BBC+The+Strange+and+The+Dangerous", "BBC+The+Strange+and+The+Dangerous+Extra+The+Weird+World+of+Louis+Theroux", "BBC+The+Voice", "BBC+This+World+Gypsy+Child+Thieves", "BBC+Time", "BBC+Timewatch", "BBC+Upgrade+Me", "BBC+What+Darwin+Didnt+Know", "BBC+What+Happened+Next", "BBC+Who+Killed+The+Honey+Bee", "BBC+Wild+China", "BBC+Yellowstone", "Beijing", "Beijing+Olympic+Games", "Beijing+Olympic+Games+Athletics+Mens", "Beijing+Olympic+Games+Athletics+Mens+Triple+Jump+Final", "Beijing+Olympic+Games+Athletics+Womens", "Beijing+Olympic+Games+Athletics+Womens+High+Jump+Final", "Beijing+Olympic+Games+Diving+Womens+Synchronised+10m+Platform+Final", "Beijing+Olympic+Games+Mens+Marathon", "Beijing+Olympic+Games+Rowing+Mens+Eights+Final", "Beijing+Olympic+Games+Rowing+Mens+Lightweight+Double+Sculls+Final", "Beijing+Olympic+Games+Rowing+Womens+Quadruple+Sculls+Final", "Beijing+Olympic+Games+Swimming+Mens", "Beijing+Olympic+Games+Swimming+Mens+50m+Freestyle+Final", "Beijing+Olympic+Games+Swimming+Womens", "Beijing+Olympic+Games+Swimming+Womens+50m+Freestyle+Final", "Beijing+Olympic+Games+Swimming+Womens+50m+Freestyle+Semifinals", "Beijing+Olympic+Games+Weightlifting+Mens", "Beijing+Olympic+Games+Womens+Marathon", "Beijing+Olympics", "Beijing+Olympics+2008+Day+Eleven+Gymnastics+Highlights", "Beijing+Olympics+2008+Day+Fourteen+Mens+Basketball+Highlights", "Beijing+Olympics+2008+Day+Nine+Highlights", "Beijing+Olympics+2008+Day+Ten+Gymnastics+Highlights", "Beijing+Olympics+2008+Day+Twelve+Basketball+Highlights", "Best+Movies+Ever+Chases", "Best+Of+Top+Gear+Series+11+Part1", "BET+Hip+Hop+Awards", "Beyond+the+Yellow+Brick+Road+The+Making+of+Tin+Man", "Big+Brother", "Big+Brothers+Big+Mouth", "Bigger+Stronger+Faster", "Bigger+Stronger+Faster+Extras", "Biography+Channel+Barack+Obama+Inaugural+Edition", "Biography+Channel+Charles+Darwin+Evolutions+Voice", "Biography+Channel+Chuck+Norris", "Biography+Channel+Hollywoods+10+Best+Cat+Fights", "Biography+Channel+Jackson+Pollock", "Biography+Channel+Jon+Stewart", "Bollywood+Hero+Part+I", "Bollywood+Hero+Part+II", "Bollywood+Hero+Part+III", "Booze+A+Young+Persons+Guide", "Born+Survivor+Bear+Grylls", "Breaking+Bad+Uncensored+IFC", "Britain+From+Above", "Britain+From+Above+Extra", "British+Painting", "Brothers+2009", "Buggin+with+Ruud+Island+of+Giant+Bugs", "The+Bachelor+S12+Special+Where+Are+They+Now", "The+Best+Of+Top+Gear+Series+9+Special", "The+Big+Drugs+Debate", "Cash+Poker", "CBC+Buried+at+Sea", "CH4+Extraordinary+Animals+In+The+Womb", "Ch4+Making+the+Monkees", "Ch4+Sex+Bomb", "Ch4+The+Great+Global+Warming+Swindle", "Ch4+The+Great+Global+Warming+Swindle+EXTRAS", "Charles+Darwin+The+Story+Of", "Checkpoint", "Cheerleader+U", "Christmas+In+Rockefeller+Center", "Claes+Oldenburg", "Clash+of+the+Choirs", "Classic+Albums+Deep+Purple+Machine+Head", "Classic+Albums+Def+Leppard+Hysteria", "Classic+Albums+Jimi+Hendrix+Electric+Ladyland", "Classic+Albums+Pink+Floyd+The+Making+of+The+Dark+Side+of+the+Moon", "Classic+Albums+Queen+The+Making+of+A+Night+At+The+Opera", "Comanche+Moon+E01", "Comanche+Moon+E02", "Comanche+Moon+E03", "Comedy+Central+Last+Laugh", "Comedy+Central+Presents+Dan+Cummins", "Comedy+Central+Presents+Jo+Koy", "Comedy+Central+Presents+Kyle+Grooms", "Comedy+Central+Presents+Sebastian+Maniscalco", "Comedy+Central+Presents+Stephen+Lynch", "Comedy+Inc+CA", "Conan+O+Brian", "Concert+for+Diana+Hour+Five", "Concert+for+Diana+Hour+Four", "Concert+for+Diana+Hour+One", "Concert+for+Diana+Hour+Six", "Concert+for+Diana+Hour+Three", "Concert+for+Diana+Hour+Two", "Constantines+Sword", "Constantines+Sword+Extras", "Countdown+To+The+Emmys", "Crude+Impact", "Crude+Impact+Extras", "CW+Fall+Preview", "The+Catherine+Tate+Christmas+Show", "The+Chopping+Block", "The+Chopping+Block+US", "The+Colbert+Report+08+Aug+07+%28", "The+Colbert+Report+08+Jan+08+%28", "The+Colbert+Report+16+May+07+%28", "The+Colbert+Report+4+Mar+08+%28", "The+CollegeHumor+Show", "Da+Vinci+Seeking+the+Truth", "Dallas+Cowboys+Cheerleaders+Making+The+Team", "Dancing+With+The+Stars+Special+US+Judges+All+Time+Top+10", "Dancing+With+The+Stars+USA", "Deadliest+Catch+Behind+The+Scenes+Special", "Death+Of+A+President", "Defying+Gravity+US", "Democratic+Convention", "Derren+Brown+Something+Wicked+This+Way+Comes", "Desperate+Housewives+Time+To+Come+Clean", "Desperate+Virgins", "Dirty+Jobs+AU", "Dirty+Jobs+Big+Animal+Vet", "Dirty+Jobs+S04+Special+Greenland+Shark+Quest", "Dirty+Jobs+Special", "Discovery+2057", "Discovery+Africas+Super+Seven+x", "Discovery+Ancient+Inventions", "Discovery+Arctic+Exposure+with+Nigel+Marven", "Discovery+Bugging+With+Ruud+Amazon+Kill+or+Cure+x", "Discovery+Bugging+With+Ruud+Hawaii+Moving+Heaven+and+Earth+x", "Discovery+Building+The+Ultimate+Digging+Big", "Discovery+Channel", "Discovery+Channel+American+Chopper+OCC+Roadshow", "Discovery+Channel+American+Chopper+On+The+Road", "Discovery+Channel+Beach+Towns+With+Attitude", "Discovery+Channel+Build+It+Bigger", "Discovery+Channel+Dirty+Jobs+Americans+Worker", "Discovery+Channel+Dirty+Jobs+Roadkill+Cleaners", "Discovery+Channel+Dirty+Jobs+Veterinarian", "Discovery+Channel+Discovering+Ardi+x", "Discovery+Channel+Egypt+Uncovered", "Discovery+Channel+Egypts+Ten+Greatest+Discoveries", "Discovery+Channel+Forensic+Detectives+Trail+Of+Evidence", "Discovery+Channel+Kings+of+Construction+Gotthard+Base+Tunnel+In+Switzerland", "Discovery+Channel+Kings+of+Construction+Tung+Chung+Hong+Kongs+New+Cable+Car", "Discovery+Channel+Most+Evil+Mastermind", "Discovery+Channel+Raising+The+Mammoth+CD1", "Discovery+Channel+Raising+The+Mammoth+CD2", "Discovery+Channel+Scientists+Guinea+Pigs", "Discovery+Channel+Seven+Wonders+of+Ancient+Egypt", "Discovery+Channel+Sleeping+With+Teacher", "Discovery+Channel+Time+Warp", "Discovery+Channel+Why+Ancient+Egypt+Fell", "Discovery+Channel+Worlds+Biggest+Airliner", "Discovery+Channel+Worlds+Toughest+Jobs+Pyrotechnician", "Discovery+Civilisation+Future+Weapons", "Discovery+Civilisation+Unsolved+History+Aztec+Temple+Of+Blood", "Discovery+Edge+of+Existence", "Discovery+Egypts+New+Tomb+Revealed", "Discovery+End+of+Extinction+Cloning+the+Tasmanian+Tiger", "Discovery+Into+the+Unknown+with+Josh+Bernstein+Season+1", "Discovery+Jack+the+Ripper+The+First+Serial+Killer", "Discovery+Mastodon+in+your+Backyard+The+Ultimate+Guide", "Discovery+Mayday+Air+India+Explosive+Evidence+x", "Discovery+Mayday+Bomb+on+Board+x", "Discovery+Megabuilders+Season+3", "Discovery+Naica+Secrets+of+the+Crystal+Cave+x", "Discovery+Nile+River+of+Gods", "Discovery+On+the+Volcanoes+of+the+World", "Discovery+Planet+Luxury+Season+2", "Discovery+Presents+Ted+Koppel+The+Price+of+Freedom", "Discovery+Science+First+Alien+Encounter", "Discovery+Science+Men+Are+Better+Than+Women+Rafting", "Discovery+Science+Men+Are+Better+Than+Women+Sailing", "Discovery+Science+Tornado+Touchdown", "Discovery+Shark+Feeding+Frenzy+x", "Discovery+Skull+Wars+The+Missing+Link", "Discovery+Solar+Empire+On+Jupiter", "Discovery+Stephen+Hawking+and+the+Theory+of+Everything+1of", "Discovery+The+Beauty+of+Snakes+x", "Discovery+The+Body+Machine+x", "Discovery+The+Leopard+Son+x", "Discovery+Traveler+Thailand+1of", "Discovery+Traveler+Thailand+2of", "Discovery+Turbo+Engineering+The+World+Rally+Monte+Carlo+Or+Bust", "Discovery+Turbo+Firepower+Destroyer", "Discovery+Understanding+Bacteria", "Discovery+Understanding+Flight", "Discovery+Understanding+Time", "Discovery+Unwrapped+The+Mysterious+World+of+Mummies", "Discovery+Valley+of+the+T+Rex", "Discovery+Whats+That+About+The+Airport+x", "Dispatches+Drinking+Yourself+To+Death", "Doctor+Who+At+The+Proms", "Doctor+Who+at+The+Proms+Behind+The+Scenes", "Doctor+Who+Confidential", "Doctor+Who+Confidential+S04+Special+The+Eleventh+Doctor", "Doctor+Who+Confidential+S04+Xmas+Special", "Doctor+Who+S04+Christmas+Special+%28", "Doctor+Who+S04+Special+Planet+Of+The+Dead", "Doctor+Who+Special", "Doctor+Who+Xmas+Special", "Dogface", "Dracula", "Drosera+Documentary+Carnivorous+Plants+FS", "Duet+Impossible", "The+Da+Vinci+Detective", "The+Daily+Show+04+Jun+07+%28", "The+Daily+Show+08+Jan+08+%28", "The+Daily+Show+11+Oct+07+%28", "The+Daily+Show+3+Mar+08+%28", "The+Daily+Show+4+Mar+08+%28", "The+Daily+Show+and+The+Colbert+Report+Mid+Term+Midtacular", "The+Devil+Came+On+Horseback", "The+Devils+Whore+Part1", "The+Devils+Whore+Part2", "The+Devils+Whore+Part3", "The+Devils+Whore+Part4", "The+Dudesons", "E+True+Hollywood+Story", "Early+Renaissance+Painting", "Eurovision+Song+Contest", "Evanescence+Live+At+Rock+In+Rio", "Extras+S02+Christmas+Special", "Extras+Xmas+Special", "Faceless", "Fallen+Part+1+The+Beginning", "Fallen+Part+2", "Fallen+Part+3", "Family+Guy+S06+Special", "Fast+And+Furious", "Fearless+Planet+Part1+Hawaii", "Fearless+Planet+Part2+Alaska", "Fearless+Planet+Part3+Saraha", "Fearless+Planet+Part4+Earth+Story", "Fearless+Planet+Part5+Great+Barrier+Reef", "Fearless+Planet+Part6+Grand+Canyon", "Flying+Confessions+of+a+Free+Woman+EXTRA+Interview", "Fonejacker+Christmas+Special", "Forensic+Files+Photo+Finish", "Four+Kings", "Fox+Fall+Preview", "Friday+Nights+Lights", "Fringe+S02+Access+All+Areas", "Future+Focus+Biometrics", "Geologic+Journey", "Get+Lost", "Ghost_Whisperer", "Goya+Crazy+Like+A+Genius", "The+Genius+of+Charles+Darwin", "The+Genius+of+Charles+Darwin+EXTRAS", "The+God+Who+Wasnt+There+Extra+Extended+Intervie", "The+Great+Global+Warming+Swindle", "Hacking+Democracy", "Halfway+Home", "Harpers+Island+Solved", "Harpers+Island+Unsolved", "Harry+Potter+And+The+Order+Of+The+Pheonix+Behind+The+Magic", "Harry+Potter+and+the+Order+of+the+Phoenix+HBO+First+Look", "Hawthrone", "HDTV+ABC+Earth", "HDTV+BBC+The+Medici+Makers+of+Modern+Art+DVB+x", "HDTV+Discovery+Destroyer+Forged+In+Steel+x", "HDTV+Discovery+Naked+Science+Asteroid+Alert+x", "HDTV+Discovery+Paul+Merton+In+China", "HDTV+Discovery+The+Last+Maneater+Killer+Tigers+of+India+x", "HDTV+Discovery+The+True+Legend+of+the+Eiffel+Tower+x", "HDTV+Discovery+Worlds+Biggest+and+Baddest+Bugs+x", "Heroes+Unmasked", "High+Stakes+Poker", "His+Dark+Materials+Book+1+Northern+Lights", "His+Dark+Materials+Book+2+The+Subtle+Knife", "His+Dark+Materials+Book+3+The+Amber+Spyglass", "History+Channel+Ancient+Aliens", "History+Channel+Ape+to+Man", "History+Channel+Conspiracy+The+Robert+Kennedy+Assassination", "History+Channel+Dead+Mens+Secrets+Plotting+To+Kill+Hitler", "History+Channel+Decoding+the+Past+The+Real+Sorcerers+Stone+x", "History+Channel+Digging+For+The+Truth+WS", "History+Channel+Dinosaur+Secrets+Revealed", "History+Channel+Disasters+of+the+Century+Second+Narro", "History+Channel+Great+Spy+Stories+Hitlers+Spies", "History+Channel+Journey+to+10", "History+Channel+Life+After+People", "History+Channel+Modern+Marvels+Machu+Picchu", "History+Channel+Modern+Marvels+The+Hoover+Dam", "History+Channel+Star+Wars+The+Legacy+Revealed", "History+Channel+Sun+Tzus+The+Art+Of+War", "History+Channel+Test+Lab", "History+Channel+The+Universe+Season+1", "History+Channel+The+Universe+Season+2", "History+Channel+The+Universe+Season+3", "Hitlers+War+On+America", "House+S06+An+Insiders+Guide", "How+I+Met+Your+Mother+%28", "Hunt+the+Kaisers+Cruisers", "The+Heros+Journey", "The+Hills+Presents+Speidis+Wedding+Unveiled", "The+Hills+S04+The+Lost+Scenes", "The+Howlin+Wolf+Story"]

	# Old shows, not updated, etc.
	list2 = ["Alive", "All+of+Us", "American+Hot+Rod", "American+Inventor", "Andy+Barker+P+I", "Andy+Barker+PI", "Angelas+Eyes", "Australias+Funniest+Home+Videos", "The+Andromeda+Strain", "Babylon+Fields", "Badger+Or+Bust", "Beyond+the+Break", "Big+Brother+Allstars", "Big+Day", "Bionic+Woman", "Blade+The+Series", "Blood+Ties", "Boy+Meets+Girl+2009", "Brainiac+Science+Abuse", "Bullrun", "The+Beautiful+Life", "The+Black+Donnellys", "Cane", "Caprica", "Catastrophe", "Cavemen", "Celebrity+Duets", "Clone", "Close+To+Home", "Comedy+Lab", "Crash+UK", "Creature+Comforts+US", "Criss+Angel+Mindfreak", "Crooked+House", "Crossing+Jordan", "Cupid+2009", "The+Class", "The+Collector", "The+Company", "The+Contender", "Dancelife", "Dancing+With+The+Stars", "Day+Break", "Demons+UK", "Doctor+Who+%282005%29", "Dont+Forget+The+Lyrics", "Drawn+Together", "Drive", "Driving+Force", "The+Dead+Zone", "The+Dresden+Files", "E+Ring", "Echo+Beach", "Extras", "Extreme+Makeover+Home+Edition", "Fear+Factor", "Feasting+On+Waves", "Fight+Girls", "Flash+Gordon+2007", "Flavor+Of+Love", "Fonejacker", "Frank+TV", "FutureWeapons", "Gene+Simmons+Family+Jewels", "George+Lopez", "Gilmore+Girls", "Grease+Is+The+Word", "Grease+Youre+the+One+That+I+Want", "The+Girls+Next+Door", "Happy+Hour", "Harley+Street", "Hells+Kitchen", "Help+Me+Help+You", "Hidden+Palms", "Hole+in+the+Wall+US", "Honest", "House+Of+Saddam", "How+Stuff+Works", "How+To+Look+Good+Naked", "Hows+Your+News", "Human+Weapon", "Hyperdrive", "The+Hills+After+Show", "The+Holy+Hottie"]

	blockedShows = list1 + list2

	# Merge
	if (File.exists?(path)) then
		begin
			knownShows = Plist::parse_xml(path)
		rescue => e
			printException(e)
			exit(1)
		end
		
		if !knownShows.nil? then
			showsToAdd = []
			shows["Shows"].each { |show|
				if (!knownShows["Shows"].find{|ks| ks["ExactName"] == show["ExactName"]}) then
					showsToAdd << show
				end
			}
		
			knownShows["Shows"] += showsToAdd
			knownShows["Version"] = version

			blockedShows.each_index { |x|
				knownShows["Shows"].delete_if {|ks| ks["ExactName"] == blockedShows[x]}
			}

			shows = knownShows
		end
	end

	shows["Shows"] = shows["Shows"].sort_by{ |x| x["HumanName"].sub(/^(the)\s/i, '').downcase }
	shows.save_plist(path)

rescue Exception, Timeout::Error => e
	printException(e) 
	exit(1)
end

exit(0)