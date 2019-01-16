local colors = { blue = 0x4286F4, purple = 0xB673d6, red = 0xC14141, green = 0xDA841,
  black = 0x000000, white = 0xFFFFFF, grey = 0x47494C, lightGrey = 0xBBBBBB}

local button = require("button")
local event = require("event")
local gpu = require("component").gpu


--for k,v in pairs(button) do print(k,v) end

function tester()
  print("hhhakjsd")
end

button.setTable("test", tester, 20, 50, 10, 20, "Yeah", {on = colors.green, off = colors.green})

--button.toggleButton("test")
button.screen()
event.listen("touch", function(_,_,x,y) print(x,y) end)
while event.pull(0.05,"interrupted") == nil do
  local e = event.pull(1)
  print(e)
end