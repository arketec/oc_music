local c = require("component")
local s = require("shell")

for k,v in pairs(c.proxy(s.parse(...)[1])) do print(k,v) end