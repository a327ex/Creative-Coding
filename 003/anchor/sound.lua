--[[
  Module responsible for playing a specific sound.
  For example:
    an:sound('jump', 'assets/jump.ogg')
  Will create the "jump" sound object. You can then access this at an.sounds.jump and play it with "sound_play":
    an.sounds.jump:sound_play(1, an:random_float(0.95, 1.05))
  This will play the jump sound effect at full volume (1), and with a random pitch between 0.95 and 1.05.
  This small pitch randomization is useful for playing repeated sounds so that they don't sound too repeated.
]]--
sound = class:class_new()
function sound:_sound(filename, music) -- this is named _sound as otherwise it collides with the an:sound function.
  if music then self.tags.music = true
  else self.tags.sound = true end
  local info = love.filesystem.getInfo(filename)
  self.source = love.audio.newSource(filename, music and 'stream' or 'static')
  self.sound_instances = {}
  table.insert(an.sounds, self)
  return self
end

--[[
  Updates this object's sound state.
  This removes instances that are not playing, and sets all instances' volume/pitch.
  Setting the pitch every frame, especially, is useful if you want to slow down or speed up all sounds when something happens.
  You can use "an:sound_set_pitch(0.5)" and this will set the pitch of all sounds to 0.5.
  More generally, if you want to, for instance, slow down everything by a certain amount whenever the player gets hit:
    an:slow(0.5, 0.5) -- slows everything to 0.5 linearly increasing to 1 during 0.5 seconds
  And then in some update function somewhere:
    an:sound_set_pitch(an.slow_amount)
    an:music_set_pitch(an.slow_amount)
  And this would match an's slow function with sounds and music.
]]--
function sound:sound_update(dt)
  for i = #self.sound_instances, 1, -1 do
    if not self.sound_instances[i].instance:isPlaying() then
      table.remove(self.sound_instances, i)
    end
  end
  for _, instance in ipairs(self.sound_instances) do
    if self:is('music') then
      instance.instance:setVolume(instance.volume*an.music_volume)
      instance.instance:setPitch(instance.pitch*an.music_pitch)
    else
      instance.instance:setVolume(instance.volume*an.sound_volume)
      instance.instance:setPitch(instance.pitch*an.sound_pitch)
    end
  end
end

--[[
  Plays a sound.
  This is supposed to play short sounds that don't loop. If you want looping sounds use the music_player module instead.
  Offset is the amount of time in seconds from the start that the sound starts playing from.
  Examples:
    an:sound('jump', 'assets/jump.ogg')
    an.sounds.jump:sound_play(0.5)
]]--
function sound:sound_play(volume, pitch, offset)
  local instance = self.sound_source:clone()
  local an_volume, an_pitch
  if self:is('music') then an_volume, an_pitch = an.music_volume, an.music_pitch
  else an_volume, an_pitch = an.sound_volume, an.sound_pitch end
  instance:setVolume((volume or 1)*an_volume)
  instance:setPitch((pitch or 1)*an_pitch)
  if offset then instance:seek(offset, 'seconds') end
  instance:play()
  table.insert(self.sound_instances, {instance = instance, volume = volume or 1, pitch = pitch or 1})
  return instance
end

--[[
  Sets the volume for all active instances of this sound.
  Example:
    sounds.jump:sound_set_volume(0)
]]--
function sound:sound_set_volume(volume)
  for _, instance in ipairs(self.sound_instances) do
    instance.volume = volume or 1
  end
end

--[[
  Sets the pitch for all active instances of this sound.
  Similarly to what was mentioned in the comments for sound_update, use this to slow down all instance of a specific sound.
  Example:
    sounds.jump:sound_set_pitch(0.5)
]]--
function sound:sound_set_pitch(pitch)
  for _, instance in ipairs(self.sound_instances) do
    instance.pitch = pitch or 1
  end
end
