--[[
  Module responsible for playing songs.
  Songs can be played using the "music_player_play_song" or "music_player_play_songs" functions.
  The current playing song will always be referenced in self.current_song.
  Examples:
    an:music_player_play_song(sound'assets/song1.ogg', 0.5) -> plays song1 looping forever at 0.5 volume

    an:music_player_play_songs({
      song1 = sound'assets/song1.ogg',
      song2 = sound'assets/song2.ogg',
      song3 = sound'assets/song3.ogg'
    }, {'song2', 'song3', 'song1'}, 0.5)                     -> plays song2 then song3 then song1 then repeats this loop

    an:music_player_play_songs({
      song1 = sound'assets/song1.ogg',
      song2 = sound'assets/song2.ogg',
      song3 = sound'assets/song3.ogg'
    }, nil, 0.5)                                            -> plays the 3 songs in random order while ensuring that no song is
                                                               repeated before all others have been played at least once per loop
]]--
music_player = class:class_new()
function music_player:music_player()
  self.tags.music_player = true
  self.songs = {}
  self.current_loop_songs = {}
  self.play_sequence = {}
  self.play_index = 1
  self.play_volume = 1
  self.current_song = nil
  return self
end

--[[
  Updates music player state.
  This checks if the current song is still playing, and if it isn't then it changes to the next.
]]--
function music_player:music_player_update(dt)
  if self.current_song and not self.current_song:isPlaying() then
    self.play_index = self.play_index + 1
    if self.play_index > #self.play_sequence then
      self.play_index = 1
      array.shuffle(self.play_sequence)
    end
    self.current_song = self.songs[self.play_sequence[self.play_index]]:sound_play(self.play_volume)
  end
end

--[[
  Plays a single song in a loop.
  Offset is the amount of time in seconds from the start that the songs starts playing from.
  Examples:
    an:music_player_play_song sound'assets/song1.ogg', 0.5     -> plays song1 looping forever at 0.5 volume
    an:music_player_play_song sound'assets/song1.ogg', 0.5, 60 -> same as above but starting at the 1 minute marker
]]--
function music_player:music_player_play_song(song, volume, offset)
  self.play_volume = volume or 1
  self:music_player_play_songs({song = song}, {'song'}, volume or 1, offset or 0)
end

--[[
  Plays multiple songs in a loop.
  If play_sequence is passed in, then it will play songs in that sequence before looping again.
  If play_sequence isn't passed in, then the songs will be played in random order while ensuring no song is repeated before
    all others have been played at least once per loop.
  Offsets are the amount of time in seconds from the start that each song starts playing from.
  Examples:
    an:music_player_play_songs({          -> plays song2 then song3 then song1 at 0.5 volume, then repeats this loop
      song1 = sound'assets/song1.ogg',
      song2 = sound'assets/song2.ogg',
      song3 = sound'assets/song3.ogg'
    }, {'song2', 'song3', 'song1'}, 0.5)

    an:music_player_play_songs({          -> plays the 3 songs in random order at 0.5 volume, then repeats this loop
      song1 = sound'assets/song1.ogg',
      song2 = sound'assets/song2.ogg',
      song3 = sound'assets/song3.ogg'
    }, nil, 0.5)

    an:music_player_play_songs({
      song1 = sound'assets/song1.ogg',
      song2 = sound'assets/song2.ogg',
      song3 = sound'assets/song3.ogg'
    }, nil, 0.5, {60, 20, 42})             -> plays the 3 songs in random order at 0.5 volume, then repeats this loop
                                              the first song starts at the 1 minute marker,
                                              the second starts at the 20s marker,
                                              and the third starts at the 42s marker
]]--
function music_player:music_player_play_songs(songs, play_sequence, volume, offsets)
  self.play_sequence = play_sequence or {}
  self.play_index = 1
  if not play_sequence then
    for song_name, _ in pairs(self.songs) do table.insert(self.play_sequence, song_name) end
    array.shuffle(self.play_sequence)
  end
  self.play_volume = volume or 1
  self.current_song = self.songs[self.play_sequence[self.play_index]]:sound_play(self.play_volume, nil, (offsets or {})[self.play_index] or 0)
end

--[[
  Stops playing the current songs and removes any active play sequences.
  No song will play until "music_player_play_song" or "music_player_play_songs" are called again.
  Example:
    an:music_player_stop()
]]--
function music_player:music_player_stop()
  self.play_sequence = {}
  self.play_index = 1
  self.current_song:stop()
  self.current_song = nil
end
