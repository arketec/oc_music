--[[
   nbs music player
   
A simple program for playing music format nbs, using music blocks from Computronics.
   Music and editor for it can be found, google Minecraft Note Block Studio.

   To use, connect to the computer cable iron music blocks. The recommended number is 8, more or less.

   TxN, 2016   
]]

local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local computer = require("computer")
local event = require("event")

local players_list = {}

local song = {}

function get_players()
  local i = 1
  for k,v in pairs(component.list("iron_noteblock")) do
    local pl = {}
  pl.index = i
  pl.instrument = 0
  pl.note = 0
  pl.interface =  component.proxy(k)
  pl.busy = false
    table.insert(players_list,pl)
  i = i + 1
  end
end

function set_player(player,instr, nt)
   player.instrument = instr
   player.note = nt
   player.busy = true
end

function players_list:get_free_player()
    for k,v in pairs (self) do
    if (type(v) == 'table') then
      if v.busy == false then
        return v
      end
    end
  end
  
  return nil
end

function players_list:clear_players()
    for k,v in pairs (self) do
    if (type(v) == "table") then
      v.busy = false
      v.instrument = 0
      v.note = 0
    end
  end   
end

function players_list:play_chord()
    for k,v in pairs (self) do
    if (type(v) == "table") then
      if v.busy == true then
         v.interface.playNote(v.instrument, v.note)
      end
    end
  end   
end

function song:loadSong(path)
  -- Throw an error if such a file does not exist
  if not fs.exists(path) then error("File \""..path.."\" does not exist.\n") end
  local file = io.open(path, "rb")
  self.length = get_int_16(getByte(file),getByte(file))
  
  self.height = get_int_16(getByte(file),getByte(file))
  self.name = readString(file)
  self.author = readString(file)
  self.org_author = readString(file)
  self.description = readString(file)
  
  self.tempo =  get_int_16(getByte(file),getByte(file))
  self.tempo = self.tempo * 0.01
  local tmp = file:read(23) -- there is unnecessary information, well, absolutely unnecessary
  tmp = readString(file) -- here too, but this is a string in addition
  
  print(self.name)
  print(self.description)
  print("Length in ticks: "..self.length)
  
  self.song_ticks = {}
  
  local tick = -1
  local jumps = 0
  
  local counter = 1
  while (true) do
    
    jumps = get_int_16(getByte(file),getByte(file))
    if jumps == 0 then
      break
    end
    
    tick = tick + jumps
    local layer = -1
    
    
    while (true) do
      self.song_ticks[counter] = {}
      jumps = get_int_16(getByte(file),getByte(file))
    if jumps == 0 then
      break
    end
    layer = layer + jumps
    self.song_ticks[counter].instrument = getByte(file)
    local nextNote = ( getByte(file) - 33 )
    while (nextNote < 0) do
      nextNote = nextNote + 12
    end
    self.song_ticks[counter].note = nextNote % 24
    self.song_ticks[counter].layer = layer
    self.song_ticks[counter].tick = tick
    counter = counter + 1
    end
  end
  
  self.blocks_num = counter -1
  
    print("Load complete")  
  file:close()
end
  
  
function song:set_tick(players, cur_tick, position)
    while (true) do
   if self.song_ticks[position].tick == cur_tick then
     player = players:get_free_player()
     if (player ~= nil) then
       set_player(player,self.song_ticks[position].instrument,self.song_ticks[position].note)
     end
     position = position + 1
   else
     break
   end
  end
  
  return position
end

function getByte(f)
  return string.byte(f:read(1))
end 

function readString(file)
  local strln = get_int_32(getByte(file),getByte(file),getByte(file),getByte(file))
  local str = ""
  str = file:read(strln)
  return str
 end
  
function get_int_16(b1, b2)
    local n = b1 + 256 * b2
  n = (n > 32767) and (n - 32768) or n
  return n
end  

function get_int_32(b1, b2, b3, b4)
      if not b4 then error("need four bytes to convert to int",2) end
      local n = b1 + b2*256 + b3*65536 + b4*16777216
      n = (n > 2147483647) and (n - 4294967296) or n
      return n
end

--------
-- Here the actual entry point of the program
--------

local args = shell.parse(...)
if #args == 0 then
  io.write("Usage: musicPlayer <path_to_song_file>\n")
  return 1
end

local path = args[1]
-- we find the musical blocks connected to the computer
get_players()
-- Load a song from file
song:loadSong(path)

-- Set the initial parameters
local play_complete = false
current_tick = 0
block_position = 1

-- We play a song until it ends
local stop = false
local paused = false
while not stop do
  if (not paused) then
    -- Get information about the notes from the current tick, set up music block
    block_position = song:set_tick(players_list, current_tick, block_position)
  
    -- Playing a chord
    players_list:play_chord()
    players_list:clear_players()
    -- Incremental tick
    current_tick = current_tick + 1
    -- We are waiting for the set time until the next tick
    stop = event.pullFiltered(1/song.tempo * 2, 
      function(name,...)
        if (name == "pause_song") then
          print("pausing...")
          paused = true 
        end
        return (name == "interrupted" or name == "stop_song")
      end
    )
    --computer.pullSignal(1/song.tempo)
    if current_tick == song.length then
      play_complete = true
      stop = true
    end
  end
end
if (play_complete) then
  print("Song played successfully")
else
  print("Song stopped")
end