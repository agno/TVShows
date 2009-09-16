#!/usr/bin/ruby
if ENV["CONFIGURATION"] == "Release" then
	folder = ENV["TARGET_BUILD_DIR"]
	file = "#{ENV["TARGET_NAME"]}_#{ENV["CURRENT_PROJECT_VERSION"]}.zip"
	path = File.join(folder,file)
	`mv "#{folder}/TVShows" ~/.Trash`
	`mv #{folder}/*.zip ~/.Trash`
	`mv #{folder}/appcast.xml ~/.Trash`
	`mkdir "#{folder}/TVShows"`
	`cp "#{File.join(ENV["PROJECT_DIR"],"..","utils","uninstall.sh")}" "#{folder}/TVShows"`
	`mv "#{folder}/#{ENV["FULL_PRODUCT_NAME"]}" "#{folder}/TVShows"`
	`cd "#{folder}" && zip -qr "#{file}" TVShows`
	key = `openssl dgst -sha1 -binary < #{path} | openssl dgst -dss1 -sign #{File.join(ENV["PROJECT_DIR"],"..","keys","dsa_priv.pem")} | openssl enc -base64`
	key = key.split("\n").first
	File.open("#{ENV["TARGET_BUILD_DIR"]}/appcast.xml", "w") { |f|
		f << "<item>\n"
		f << "\t<title>TVShows #{ENV["CURRENT_PROJECT_VERSION"]}</title>\n"
		f << "\t<pubDate>#{Time.now}</pubDate>\n"
		f << "\t<enclosure sparkle:version=\"#{ENV["CURRENT_PROJECT_VERSION"]}\" sparkle:dsaSignature=\"#{key}\" url=\"http://downloads.sourceforge.net/tvshows/#{file}\" length=\"#{File.size(path)}\" type=\"application/octet-stream\"/>\n"
		f << "\t<description><![CDATA[Changes in version #{ENV["CURRENT_PROJECT_VERSION"]}:\n"
		f << "\t\t<ul>\n"
		f << "\t\t\t<li></li>\n"
		f << "\t\t\t<li></li>\n"
		f << "\t\t\t<li></li>\n"
		f << "\t\t</ul>\n\t]]></description>\n"
		f << "</item>"
	}
end


