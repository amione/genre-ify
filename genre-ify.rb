require 'rubygems'
require 'sqlite3'
require 'json'
require 'base64'
require 'net/http'
require 'uri'

puts "Please go here: https://developer.spotify.com/web-api/console/post-playlists/"
puts "Generate a bearer token using the interface that has all the scopes."

print "Enter Your Generated Token Here: "
scoped_token = gets.strip

print "Enter Your Spotify Username: "
spotify_user = gets.strip

print "Enter ID of playlist to analyze: "
playlist_id = gets.strip


db = SQLite3::Database.new("#{playlist_id}_spotify.db")

db.execute( "create table spotify_playlist_tracks (id INTEGER PRIMARY KEY, playlist_id TEXT, track_name TEXT, track_id TEXT, track_url TEXT,  artist_name TEXT, artist_id  Text, artist_url TEXT, genres TEXT);")

db.execute( "create table spotify_playlist_artists (id INTEGER PRIMARY KEY, band_id TEXT, band_name TEXT, band_url TEXT, band_genres TEXT);")

db.execute( "create table spotify_playlist_genres (id INTEGER PRIMARY KEY, playlist_genres TEXT);")

##playlist request

uri = URI.parse("https://api.spotify.com/v1/users/#{spotify_user}/playlists/#{playlist_id}/tracks")
request = Net::HTTP::Get.new(uri)
request["Accept"] = "application/json"
request["Authorization"] = "Bearer #{scoped_token}"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end


##playlist loop begin

playlist_response = JSON.parse(response.body)

track_total = playlist_response["total"].to_i

iterations = (track_total / 100.0).ceil

counter = 0

fetch_next = "first_loop"

while counter <= iterations do

	puts "Please Be patient. Fetching tracks in groups of 100 from playlist with id: #{playlist_id}..."

	if fetch_next != "first_loop" && fetch_next != nil

		#puts fetch_next

		counter += 1

		uri = URI.parse("#{fetch_next}")
		request = Net::HTTP::Get.new(uri)
		request["Accept"] = "application/json"
		request["Authorization"] = "Bearer #{scoped_token}"

		req_options = {
		  use_ssl: uri.scheme == "https",
		}

		response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		  http.request(request)
		end

		playlist_response = JSON.parse(response.body)

	elsif fetch_next != "first_loop" && fetch_next == nil

		counter +=1

	end

	item_total = playlist_response["items"].count - 1

	for x in 0..item_total do

		local_track = playlist_response["items"][x]["is_local"]

		if local_track != "true"

			track_name = playlist_response["items"][x]["track"]["name"]
			track_id = playlist_response["items"][x]["track"]["id"]
			track_url = playlist_response["items"][x]["track"]["href"]
			artist_name = playlist_response["items"][x]["track"]["artists"][0]["name"]
			artist_id = playlist_response["items"][x]["track"]["artists"][0]["id"]
			artist_url = playlist_response["items"][x]["track"]["artists"][0]["href"]

			if track_name.include? "'"
				track_name_clean = track_name.gsub("'", "''")
			else
				track_name_clean = track_name
			end

			if artist_name.include? "'"
				artist_name_clean = artist_name.gsub("'", "''")
			else
				artist_name_clean = artist_name
			end

#			puts "insert into spotify_playlist_tracks (playlist_id,track_name,track_id,track_url,artist_name,artist_id,artist_url) values ('#{playlist_id}','#{track_name_clean}','#{track_id}','#{track_url}','#{artist_name_clean}','#{artist_id}','#{artist_url}');"

			db.execute("insert into spotify_playlist_tracks (playlist_id,track_name,track_id,track_url,artist_name,artist_id,artist_url) values ('#{playlist_id}','#{track_name_clean}','#{track_id}','#{track_url}','#{artist_name_clean}','#{artist_id}','#{artist_url}');")

		end

	end

	fetch_next = playlist_response["next"]

end

puts "Generating artist table and fetching artist genres..."

bands = db.execute("select distinct artist_id from spotify_playlist_tracks")

all_bands = bands.count - 1

band_counter = 0

artist_array = []

url_counter = 0
urls_to_generate = all_bands / 50

for x in 0..all_bands do

	if bands[x][0] != ""

		if band_counter <= 49
			#puts "band counter is less than or equal to 49"
			artist_array << bands[x][0]

			if band_counter == 49

				band_counter = 0
				url_counter += 1

				#puts url_counter
				#puts "https://api.spotify.com/v1/artists?ids=#{artist_array * ","}"

				uri = URI.parse("https://api.spotify.com/v1/artists?ids=#{artist_array * ","}")
				#puts "https://api.spotify.com/v1/artists/#{bands[x][0]}"
				request = Net::HTTP::Get.new(uri)
				request["Accept"] = "application/json"
				request["Authorization"] = "Bearer #{scoped_token}"

				req_options = {
			  		use_ssl: uri.scheme == "https",
				}

				response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
			  		http.request(request)
				end

				artist_response = JSON.parse(response.body)

				artist_total = artist_response["artists"].count - 1

				for x in 0..artist_total do

					band_name = artist_response["artists"][x]["name"]
					#puts band_name

					band_id = artist_response["artists"][x]["id"]
					#puts band_id

					band_url = artist_response["artists"][x]["href"]
					band_genres = artist_response["artists"][x]["genres"]

					puts "artist name: #{band_name} | spotify_id: #{band_id}"

					if band_name.include? "'"
						band_name_clean = band_name.gsub("'", "''")
					else
						band_name_clean = band_name
					end

					non_array_band_genres = band_genres * ","

					if non_array_band_genres.include? "'"
						non_array_band_genres_clean = non_array_band_genres.gsub("'", "''")
					else
						non_array_band_genres_clean = non_array_band_genres
					end

					db.execute("insert into spotify_playlist_artists (band_id, band_name, band_url, band_genres) values ('#{band_id}','#{band_name_clean}','#{band_url}','#{non_array_band_genres_clean}');")

				end

				artist_array = []

				sleep 2
			else
				band_counter += 1

			end # end band counter == 49

		end #end band counter <= 49

	end #end if bands != ""

end #end all_bands do

#getting last group of bands

url_counter += 1
#puts url_counter
#puts "https://api.spotify.com/v1/artists?ids=#{artist_array * ","}"

uri = URI.parse("https://api.spotify.com/v1/artists?ids=#{artist_array * ","}")
#puts "https://api.spotify.com/v1/artists/#{bands[x][0]}"
request = Net::HTTP::Get.new(uri)
request["Accept"] = "application/json"
request["Authorization"] = "Bearer #{scoped_token}"

req_options = {
		use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		http.request(request)
end

artist_response = JSON.parse(response.body)

artist_total = artist_response["artists"].count - 1

for x in 0..artist_total do

	band_name = artist_response["artists"][x]["name"]
#	puts band_name

	band_id = artist_response["artists"][x]["id"]
#	puts band_id

	band_url = artist_response["artists"][x]["href"]
	band_genres = artist_response["artists"][x]["genres"]

	puts "artist name: #{band_name} | spotify_id: #{band_id}"

	if band_name.include? "'"
		band_name_clean = band_name.gsub("'", "''")
	else
		band_name_clean = band_name
	end

	non_array_band_genres = band_genres * ","

	if non_array_band_genres.include? "'"
		non_array_band_genres_clean = non_array_band_genres.gsub("'", "''")
	else
		non_array_band_genres_clean = non_array_band_genres
	end

	db.execute("insert into spotify_playlist_artists (band_id, band_name, band_url, band_genres) values ('#{band_id}','#{band_name_clean}','#{band_url}','#{non_array_band_genres_clean}');")

end

puts "Building Genre Selection Table..."

big_genre_array = db.execute( "select band_genres from spotify_playlist_artists;")

genre_groups = big_genre_array.count - 1

huge_genre_array = []

for x in 0..genre_groups do
	huge_genre_array << big_genre_array[x][0]
end

smoosh_genres = huge_genre_array * ","

smoosh_and_split = smoosh_genres.split(",")

unique_smoosh_and_split = smoosh_and_split.uniq

reduced_genre_count = unique_smoosh_and_split.count - 1

for x in 0..reduced_genre_count do
	solo_genre = unique_smoosh_and_split[x]
	if solo_genre != ""

		if solo_genre.include? "'"
			solo_genre_clean = solo_genre.gsub("'", "''")
		else
			solo_genre_clean = solo_genre
		end

		db.execute( "insert into spotify_playlist_genres (playlist_genres) values ('#{solo_genre_clean}');")
	end
end

puts "Matching genres back to original playlist tracks..."

artist_genre_arrays = db.execute("select band_id, band_genres from spotify_playlist_artists;")

aga_count = artist_genre_arrays.count - 1

for x in 0..aga_count do

	band_id_lookup = artist_genre_arrays[x][0]
	band_genre_lookup = artist_genre_arrays[x][1]

	if band_id_lookup.include? "'"
		band_id_lookup_clean = band_id_lookup.gsub("'", "''")
	else
		band_id_lookup_clean = band_id_lookup
	end

	if band_genre_lookup.include? "'"
		band_genre_lookup_clean = band_genre_lookup.gsub("'", "''")
	else
		band_genre_lookup_clean = band_genre_lookup
	end

	if band_genre_lookup_clean != ""
		db.execute("update spotify_playlist_tracks set genres = '#{band_genre_lookup_clean}' where artist_id = '#{band_id_lookup_clean}';")
	end

end

puts "Please select a genre from the following list that you want to create a new playlist from based on your existing playlist:"

sleep 5

genre_values = db.execute("select playlist_genres from spotify_playlist_genres;")

gv_count = genre_values.count - 1

for x in 0..gv_count do
	puts genre_values[x]
end

print "Enter Your Genre Selection: "
genre_selection = gets.strip

if genre_selection.include? "'"
	genre_selection_clean = genre_selection.gsub("'", "''")
else
	genre_selection_clean = genre_selection
end

puts "Selecting tracks that match your genre selection..."

matching_tracks = db.execute("select track_id from spotify_playlist_tracks where genres like '%#{genre_selection_clean}%';")

match_count = matching_tracks.count - 1

#for x in 0..match_count do
#	puts "https://open.spotify.com/track/#{matching_tracks[x][0]}"
#end

print "Enter Your New Playlist Name: "
new_playlist_name = gets.strip

uri = URI.parse("https://api.spotify.com/v1/users/#{spotify_user}/playlists")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Accept"] = "application/json"
request["Authorization"] = "Bearer #{scoped_token}"
request.body = JSON.dump({
  "description" => "#{genre_selection} playlist created programmatically from playlist with ID = #{playlist_id}",
  "public" => false,
  "name" => "#{new_playlist_name}"
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

puts "#{new_playlist_name} created..."
#puts response.body

new_playlist_response = JSON.parse(response.body)
new_playlist_id = new_playlist_response["id"]

puts "Adding selected tracks to #{new_playlist_name}..."

uri_array = []

track_add_counter = 0
uri_array_counter = 0

uri_arrays_to_generate = match_count / 100
#puts uri_arrays_to_generate

for x in 0..match_count do

	if matching_tracks[x] != nil

		if track_add_counter <= 99
			#puts "band counter is less than or equal to 99"
			uri_array << "spotify:track:#{matching_tracks[x][0]}"

			if track_add_counter == 99

				track_add_counter = 0
				uri_array_counter += 1

#				puts uri_array_counter
#				puts uri_array.uniq

				uri = URI.parse("https://api.spotify.com/v1/users/#{spotify_user}/playlists/#{new_playlist_id}/tracks")
				request = Net::HTTP::Post.new(uri)
				request.content_type = "application/json"
				request["Accept"] = "application/json"
				request["Authorization"] = "Bearer #{scoped_token}"
				request.body = JSON.dump({
				  "uris" => uri_array.uniq
				})

				req_options = {
				  use_ssl: uri.scheme == "https",
				}

				response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				  http.request(request)
				end

				uri_array = []

				sleep 2
			else
				track_add_counter += 1

			end # end track add counter == 99

		end #end track add counter <= 99

	end #end if matching tracks != nil

end #end match count do

uri_array_counter += 1
#puts uri_array_counter

#puts uri_array.uniq

uri = URI.parse("https://api.spotify.com/v1/users/#{spotify_user}/playlists/#{new_playlist_id}/tracks")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Accept"] = "application/json"
request["Authorization"] = "Bearer #{scoped_token}"
request.body = JSON.dump({
  "uris" => uri_array.uniq
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

track_add_response = JSON.parse(response.body)

#puts track_add_response
puts "Playlist created. Open up Spotify and enjoy!"