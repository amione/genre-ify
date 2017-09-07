# genre-ify
A quick and dirty ruby script to create new Spotify playlists from existing playlists based on music genre.

# Purpose
I have "eclectic taste" in music, so generally when I make a playlist I just throw anything I like in there and then set it to shuffle. However, sometimes I find myself wishing I could sort my playlists by genre so that I could listen to all the tracks that are "classic rock" or "deep house". Unfortunately, Spotify doesn't include genre info on a track by track basis. So what this script does (only using libraries that come bundled with ruby) is grab all of the track ids from a specified playlist and put them in a database, then it fetches the artists associated with those tracks (artists have genres, tracks don't), then it matches those genres back to the tracks. Finally, it will ask you to select a genre to create a new playlist from. It will grab the tracks that match that genre from your existing playlist and create a new one. It's not a perfect solution. The genres can be crazy specific, so if you choose one of those you might only generate a playlist with a handful of tracks in it.  

### Usage

	From your command line:

		ruby genre-ify.rb


1.	Go Spotify's Interactive API Console and generate an oauth token that has all the permission scopes: https://developer.spotify.com/web-api/console/post-playlist-tracks/  Copy this token, and enter it when prompted by the script.

2. Enter your spotify username

3. Enter the ID of the playlist you want to break down. You can get the ID by right clicking on a playlist and choosing "copy spotify uri". The ID will look like this: 0Zw7uKAwbM810t2isqVahR

4. Once the script has fetched all the relevant info, it will spit out a list of genres. Enter one and hit return. This part of the script uses an SQL like clause. For example: "select track_id from spotify_playlist_tracks where genres like '%rock%';" This would actually match anything in the genre list that has rock in it. So, soft rock, hard rock, progressive rock, etc. You can tweak the query to make it more restrictive.

5. Enter a name for your new playlist.

***
Some color commentary on the script. Initially I had created this script so that you would need to enter your own Spotify App ID and Secret Key. The using that I would generate a token. This was fine for pulling track and artist info, but in order to get a token with enough permissions to create a playlist the user would need to login to spotify and grant access. That meant I would need to handle providing an interface for a user to login and also catch the redirect from the oauth callback, which was more complicated than I wanted...plus I'm lazy. Having the user generate a token from the interactive web console was just easier.
