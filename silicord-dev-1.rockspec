package = "silicord"
version = "dev-1"
source = {
   url = "***" -- We'll update this once you have a GitHub repo
}
description = {
   summary = "A Discord API wrapper for Lua with Luau-inspired syntax.",
   detailed = [[
      Silicord allows Roblox developers to create Discord bots using 
      familiar syntax while bridging the gap between Luau and standard Lua.
   ]],
   homepage = "https://github.com/yourusername/silicord",
   license = "MIT" 
}
dependencies = {
   "lua >= 5.1",
   "dkjson >= 2.5",
   "luasec",
   "luasocket",
   "copas" -- This is a powerful scheduler that works great on 5.4
}
build = {
   type = "builtin",
   modules = {
      silicord = "init.lua" -- This will be your main entry point
   }
}