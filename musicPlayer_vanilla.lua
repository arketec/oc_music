--[[
   nbs music player
   Простая программка для проигрывания музыки формата nbs, использующая музыкальные блоки из Computronics.
   Музыку и редактор для нее можно найти, загуглив Minecraft Note Block Studio.

   Для использования подключите к компьютеру кабелем железные музыкальные блоки. Рекомендуемое количество - 8, можно больше или меньше.

   TxN, 2016   
]]

local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local computer = require("computer")

local players_list = {}

local song = {}

function get_players()
  local i = 1
  for k,v in pairs(component.list("note_block")) do
    local pl = {}
	pl.index = i
	pl.instrument = 0
	pl.note = 0
	pl.interface = 	component.proxy(k)
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
	  if v.busy == false then
	      return v
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
        for j,s in pairs(v) do print(j,s) end
        if (v.note > 0 and v.note <= 25) then  
	         v.interface.trigger(v.note)
        end
	    end
	  end
	end   
end

function song:loadSong(path)
	--Кинуть ошибку, если такого файла не существует
	if not fs.exists(path) then error("File \""..path.."\" does not exist.\n") end
	local file = io.open(path, "rb")
	self.length = get_int_16(getByte(file),getByte(file))
	
	self.height = get_int_16(getByte(file),getByte(file))
	self.name = readString(file)
	self.author = readString(file)
	self.org_author = readString(file)
	self.description = readString(file)
	
	self.tempo =  get_int_16(getByte(file),getByte(file))
	self.tempo = self.tempo * 0.02
	local tmp = file:read(23) -- тут ненужная информация, ну совсем ненужная
	tmp = readString(file) -- тут тоже, но это строка вдобавок
	
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
		self.song_ticks[counter].note = getByte(file) - 33 
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
-- Тут собственно точка входа программы
--------

local args = shell.parse(...)
if #args == 0 then
  io.write("Usage: musicPlayer <path_to_song_file>\n")
  return 1
end

local path = args[1]
-- находим подключенные к компьютеру музыкальные блоки
get_players()
-- Загружаем песню из файла
song:loadSong(path)

-- Задаем начальные параметры
local play_complete = false
current_tick = 0
block_position = 1

--Играем песню пока не кончится
while not play_complete do
  -- Достаем информацию о нотах из текущего тика, настраиваем музыкальные блоки
  block_position = song:set_tick(players_list, current_tick, block_position)
  
  -- Играем аккорд
  players_list:play_chord()
  players_list:clear_players()
  -- Инкрементим тик
  current_tick = current_tick + 1
  -- Ждем заданное время до следующего тика
  os.sleep(1/song.tempo)
  --computer.pullSignal(1/song.tempo)
  if current_tick == song.length then
    play_complete = true
  end
end

print("Song played successfully")