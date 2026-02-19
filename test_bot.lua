local silicord = require("silicord")

local client = silicord.Connect("YOUR_TOKEN_HERE")

-- This looks exactly like a Roblox script!
client.OnMessage:Connect(function(message)
    print("Received: " .. message.Content)
    
    -- This is very Roblox-y!
    message:Reply("Dipankar is goat and so is ronaldo. If you choose Messi, " .. message.Author .. ", you are kicked off skyjet goat!")
end)

print("Bot is listening for events...")

silicord.Run()