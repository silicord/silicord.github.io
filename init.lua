local socket = require("socket")
local copas = require("copas")
local http = require("copas.http")
local json = require("dkjson")
local ltn12 = require("ltn12") -- Necessary for sending the message body

local silicord = {}

-- 1. Internal Logging Helper
local function log_info(message)
    local purple = "\27[35m"
    local reset = "\27[0m"
    print(string.format("%sINFO    %s silicord: %s%s", purple, os.date("%H:%M:%S"), message, reset))
end

local function log_error(message)
    local bold_red = "\27[1;31m"
    local reset = "\27[0m"
    print(string.format("%sERROR   %s silicord: %s%s", bold_red, os.date("%H:%M:%S"), message, reset))
end

-- 2. Message Class
local Message = {}
Message.__index = Message

function Message.new(data, token)
    local self = setmetatable(data, Message)
    self._token = token
    return self
end

function Message:Reply(text)
    -- Explicitly require inside the function to avoid scope issues
    local socket = require("socket")
    local ssl = require("ssl")
    local https = require("ssl.https") -- Use ssl.https directly
    local ltn12 = require("ltn12")

    local body = json.encode({
        content = text,
        message_reference = { message_id = self.id }
    })

    log_info("Sending reply to Discord...")

    local response_body = {}
    local _, code, headers, status = https.request({
        url = string.format("https://discord.com/api/v10/channels/%s/messages", self.channel_id),
        method = "POST",
        headers = {
            ["Authorization"] = "Bot " .. self._token,
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body),
            ["User-Agent"] = "Silicord (https://github.com/qwertydev/silicord, v1.0)",
            ["Host"] = "discord.com"
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body),
        verify = "none",
        protocol = "tlsv1_2"
    })

    if code == 200 or code == 201 then
        log_info("Message sent successfully!")
    else
        -- This is where your red error lives
        log_error("Failed to send message. Code: " .. tostring(code))
    end
end

-- 3. Task Library
silicord.task = {
    wait = function(n)
        copas.pause(n or 0)
        return n
    end,
    spawn = function(f, ...)
        return copas.addthread(f, ...)
    end
}

-- 4. Signal Class
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ _listeners = {} }, Signal) end
function Signal:Connect(callback)
    table.insert(self._listeners, callback)
    return { Disconnect = function() end }
end
function Signal:Fire(...)
    for _, callback in ipairs(self._listeners) do
        silicord.task.spawn(callback, ...)
    end
end

-- 5. Connect Function
function silicord.Connect(token)
    log_info("Initializing gateway connection...")
    
    local client = {
        OnMessage = Signal.new(),
        Token = token
    }
    
    -- Now the simulation is INSIDE here, so it can see 'client'
    silicord.task.spawn(function()
        silicord.task.wait(3)
        log_info("Simulating received Discord message...")
        
        local msgObject = Message.new({
            id = "12345", 
            channel_id = "67890",
            Content = "Hello from Silicord!",
            Author = "System"
        }, client.Token)
        
        client.OnMessage:Fire(msgObject)
    end)
    
    return client
end

function silicord.Run()
    log_info("Engine started. Listening for events...")
    copas.loop()
end

return silicord