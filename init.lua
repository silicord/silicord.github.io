local socket = require("socket")
local ssl = require("ssl")
local copas = require("copas")
local json = require("dkjson")
local ltn12 = require("ltn12")

math.randomseed(os.time())

local silicord = {}
silicord._clients = {}

-- 1. Internal Helpers
local function log_info(message)
    print(string.format("\27[1;35mINFO    %s silicord: %s\27[0m", os.date("%H:%M:%S"), message))
end

local function log_error(message)
    print(string.format("\27[1;31mERROR   %s silicord: %s\27[0m", os.date("%H:%M:%S"), message))
end

local function hex_to_int(hex)
    hex = hex:gsub("^#", ""):gsub("^0x", "")
    return tonumber(hex, 16)
end

local function url_encode(str)
    return str:gsub("(.)", function(c)
        local b = string.byte(c)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
           (b >= 48 and b <= 57) or c == "-" or c == "_" or c == "." or c == "~" then
            return c
        end
        return string.format("%%%02X", b)
    end)
end

local function send_frame(conn, payload)
    local len = #payload
    local mask = {
        math.random(0, 255), math.random(0, 255),
        math.random(0, 255), math.random(0, 255)
    }
    local masked = {}
    for i = 1, len do
        masked[i] = string.char(string.byte(payload, i) ~ mask[(i - 1) % 4 + 1])
    end
    local header
    if len <= 125 then
        header = string.char(0x81, 0x80 + len)
    elseif len <= 65535 then
        header = string.char(0x81, 0xFE, math.floor(len / 256), len % 256)
    end
    conn:send(header .. string.char(mask[1], mask[2], mask[3], mask[4]) .. table.concat(masked))
end

local function send_close_frame(conn)
    local mask = { math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255) }
    local code = { 0x03, 0xE8 }
    local masked_code = {
        string.char(code[1] ~ mask[1]),
        string.char(code[2] ~ mask[2])
    }
    conn:send(
        string.char(0x88, 0x82) ..
        string.char(mask[1], mask[2], mask[3], mask[4]) ..
        table.concat(masked_code)
    )
end

-- 2. Task Scheduler
silicord.task = {
    wait = function(n)
        copas.pause(n or 0)
        return n
    end,
    spawn = function(f, ...)
        return copas.addthread(f, ...)
    end
}

-- 3. Signal System
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

-- 4. Embed Builder
function silicord.Embed(data)
    local embed = {}
    if data.color then
        embed.color = type(data.color) == "string" and hex_to_int(data.color) or data.color
    end
    if data.title       then embed.title       = data.title       end
    if data.description then embed.description = data.description end
    if data.url         then embed.url         = data.url         end
    if data.timestamp   then embed.timestamp   = data.timestamp   end
    if data.author then
        embed.author = { name = data.author, icon_url = data.author_icon, url = data.author_url }
    end
    if data.footer then
        embed.footer = { text = data.footer, icon_url = data.footer_icon }
    end
    if data.image     then embed.image     = { url = data.image }     end
    if data.thumbnail then embed.thumbnail = { url = data.thumbnail } end
    if data.fields then
        embed.fields = {}
        for _, field in ipairs(data.fields) do
            table.insert(embed.fields, {
                name   = field.name,
                value  = field.value,
                inline = field.inline or false
            })
        end
    end
    return embed
end

-- 5. HTTP Helpers
local function make_request_sync(token, url, method, body)
    local https = require("ssl.https")
    local result = {}
    local _, code = https.request({
        url    = url,
        method = method,
        headers = {
            ["Authorization"] = "Bot " .. token,
            ["Content-Type"]   = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink   = ltn12.sink.table(result),
        verify = "none"
    })
    local body_str = table.concat(result)
    if code ~= 200 and code ~= 201 and code ~= 204 then
        log_error("Request failed. Code: " .. tostring(code) .. " | " .. url)
        return nil, code
    end
    return json.decode(body_str), code
end

local function make_request(token, url, method, body)
    silicord.task.spawn(function()
        make_request_sync(token, url, method, body)
    end)
end

-- 6. Slash Command Option Type Map
local OPTION_TYPES = {
    string  = 3,
    integer = 4,
    bool    = 5,
    boolean = 5,
    user    = 6,
    channel = 7,
    role    = 8,
    number  = 10,
    any     = 3  -- fallback to string
}

-- 7. Guild Object
local Guild = {}
Guild.__index = Guild

function Guild.new(data, token)
    return setmetatable({
        id     = data.id,
        name   = data.name,
        _token = token,
        _data  = data
    }, Guild)
end

function Guild:CreateChannel(name, kind)
    local channel_type = (kind == "voice") and 2 or 0
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/channels", self.id),
        "POST",
        json.encode({ name = name, type = channel_type })
    )
    if data then log_info("Created channel #" .. name) end
    return data
end

function Guild:CreateRole(name, color, permissions)
    local body = { name = name }
    if color then
        body.color = type(color) == "string" and hex_to_int(color) or color
    end
    if permissions then body.permissions = tostring(permissions) end
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/roles", self.id),
        "POST",
        json.encode(body)
    )
    if data then log_info("Created role @" .. name) end
    return data
end

function Guild:GetMembers(limit)
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/members?limit=%d", self.id, limit or 100),
        "GET", ""
    )
    return data or {}
end

function Guild:GetRandomMember()
    local members = self:GetMembers(100)
    if not members or #members == 0 then return nil end
    local pick = members[math.random(1, #members)]
    return pick and pick.user or nil
end

function Guild:GetChannels()
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/channels", self.id),
        "GET", ""
    )
    return data or {}
end

function Guild:GetRoles()
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/roles", self.id),
        "GET", ""
    )
    return data or {}
end

function Guild:KickMember(user_id, reason)
    make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/members/%s", self.id, user_id),
        "DELETE",
        reason and json.encode({ reason = reason }) or ""
    )
    log_info("Kicked user " .. user_id)
end

function Guild:BanMember(user_id, reason)
    make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s/bans/%s", self.id, user_id),
        "PUT",
        reason and json.encode({ reason = reason }) or "{}"
    )
    log_info("Banned user " .. user_id)
end

-- 8. Interaction Object (for slash commands)
local Interaction = {}
Interaction.__index = Interaction

function Interaction.new(data, token)
    local self = setmetatable({}, Interaction)
    self._token      = token
    self.id          = data.id
    self.token       = data.token
    self.guild_id    = data.guild_id
    self.channel_id  = data.channel_id
    self.author      = data.member and data.member.user or data.user
    -- Parse options into a clean args table keyed by name
    self.args        = {}
    if data.data and data.data.options then
        for _, opt in ipairs(data.data.options) do
            self.args[opt.name] = opt.value
        end
    end
    return self
end

function Interaction:Reply(text, embed)
    local payload = { type = 4, data = {} }
    if type(text) == "table" then
        payload.data.embeds = { text }
    else
        payload.data.content = text
        if embed then payload.data.embeds = { embed } end
    end
    make_request(
        self._token,
        string.format("https://discord.com/api/v10/interactions/%s/%s/callback", self.id, self.token),
        "POST",
        json.encode(payload)
    )
end

function Interaction:GetGuild()
    if not self.guild_id then return nil end
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s", self.guild_id),
        "GET", ""
    )
    if not data then return nil end
    return Guild.new(data, self._token)
end

function Interaction:SendPrivateMessage(text, embed)
    silicord.task.spawn(function()
        local dm_data = make_request_sync(
            self._token,
            "https://discord.com/api/v10/users/@me/channels",
            "POST",
            json.encode({ recipient_id = self.author.id })
        )
        if not dm_data or not dm_data.id then
            log_error("Failed to open DM with user " .. self.author.id)
            return
        end
        local payload = {}
        if type(text) == "table" then
            payload.embeds = { text }
        else
            payload.content = text
            if embed then payload.embeds = { embed } end
        end
        make_request_sync(
            self._token,
            string.format("https://discord.com/api/v10/channels/%s/messages", dm_data.id),
            "POST",
            json.encode(payload)
        )
    end)
end

-- 9. Message Object
local Message = {}
Message.__index = Message

function Message.new(data, token)
    local self = setmetatable(data, Message)
    self._token     = token
    self.id         = data.id
    self.channel_id = data.channel_id
    self.guild_id   = data.guild_id
    self.content    = data.content or ""
    self.author     = data.author
    return self
end

function Message:Reply(text, embed)
    local payload = { message_reference = { message_id = self.id } }
    if type(text) == "table" then
        payload.embeds = { text }
    else
        payload.content = text
        if embed then payload.embeds = { embed } end
    end
    make_request(
        self._token,
        string.format("https://discord.com/api/v10/channels/%s/messages", self.channel_id),
        "POST",
        json.encode(payload)
    )
end

function Message:React(emoji)
    make_request(
        self._token,
        string.format("https://discord.com/api/v10/channels/%s/messages/%s/reactions/%s/@me",
            self.channel_id, self.id, url_encode(emoji)),
        "PUT", "{}"
    )
end

function Message:Delete()
    make_request(
        self._token,
        string.format("https://discord.com/api/v10/channels/%s/messages/%s", self.channel_id, self.id),
        "DELETE", ""
    )
end

function Message:GetGuild()
    if not self.guild_id then return nil end
    local data = make_request_sync(
        self._token,
        string.format("https://discord.com/api/v10/guilds/%s", self.guild_id),
        "GET", ""
    )
    if not data then return nil end
    return Guild.new(data, self._token)
end

function Message:SendPrivateMessage(text, embed)
    silicord.task.spawn(function()
        local dm_data = make_request_sync(
            self._token,
            "https://discord.com/api/v10/users/@me/channels",
            "POST",
            json.encode({ recipient_id = self.author.id })
        )
        if not dm_data or not dm_data.id then
            log_error("Failed to open DM with user " .. self.author.id)
            return
        end
        local payload = {}
        if type(text) == "table" then
            payload.embeds = { text }
        else
            payload.content = text
            if embed then payload.embeds = { embed } end
        end
        make_request_sync(
            self._token,
            string.format("https://discord.com/api/v10/channels/%s/messages", dm_data.id),
            "POST",
            json.encode(payload)
        )
    end)
end

-- 10. Gateway Connection
function silicord.Connect(config)
    local token       = config.token
    local prefix      = config.prefix or "!"
    local app_id      = config.app_id  -- needed to register slash commands
    log_info("Connecting to Discord Gateway...")

    local client = {
        OnMessage  = Signal.new(),
        Token      = token,
        _conn      = nil,
        _commands  = {},   -- prefix commands: { name -> { callback } }
        _slash     = {},   -- slash commands:  { name -> { options, callback } }
        _app_id    = app_id
    }

    -- Register a prefix command
    -- Usage: client:CreateCommand("ping", function(message, args) end)
    function client:CreateCommand(name, callback)
        self._commands[name] = { callback = callback }
        log_info("Registered command: " .. prefix .. name)
    end

    -- Register a slash command
    -- Usage:
    --   client:CreateSlashCommand("ban", {
    --       description = "Ban a user",
    --       options = {
    --           { name = "user",   description = "User to ban",   type = "user",   required = true },
    --           { name = "reason", description = "Ban reason",    type = "string", required = false }
    --       }
    --   }, function(interaction, args) end)
    function client:CreateSlashCommand(name, config_slash, callback)
        self._slash[name] = { options = config_slash.options or {}, callback = callback }

        if not self._app_id then
            log_error("app_id is required in silicord.Connect config to register slash commands.")
            return
        end

        -- Build the options array for Discord's API
        local api_options = {}
        for _, opt in ipairs(config_slash.options or {}) do
            table.insert(api_options, {
                name        = opt.name,
                description = opt.description or opt.name,
                type        = OPTION_TYPES[opt.type] or 3,
                required    = opt.required or false
            })
        end

        -- Register with Discord
        silicord.task.spawn(function()
            local data, code = make_request_sync(
                token,
                string.format("https://discord.com/api/v10/applications/%s/commands", self._app_id),
                "POST",
                json.encode({
                    name        = name,
                    description = config_slash.description or name,
                    options     = api_options
                })
            )
            if data then
                log_info("Registered slash command: /" .. name)
            end
        end)
    end

    table.insert(silicord._clients, client)

    silicord.task.spawn(function()
        local tcp = socket.tcp()
        tcp:settimeout(5)

        local ok, err = tcp:connect("gateway.discord.gg", 443)
        if not ok then log_error("TCP failed: " .. tostring(err)) return end

        local conn = ssl.wrap(tcp, { mode = "client", protocol = "tlsv1_2", verify = "none" })
        conn:dohandshake()
        conn = copas.wrap(conn)
        client._conn = conn

        conn:send(
            "GET /?v=10&encoding=json HTTP/1.1\r\n" ..
            "Host: gateway.discord.gg\r\n" ..
            "Upgrade: websocket\r\n" ..
            "Connection: Upgrade\r\n" ..
            "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n" ..
            "Sec-WebSocket-Version: 13\r\n\r\n"
        )

        while true do
            local line = conn:receive("*l")
            if line == "" or not line then break end
        end

        log_info("WebSocket Ready. Listening for events...")

        while true do
            local head = conn:receive(2)
            if not head then
                log_error("Connection lost.")
                break
            end

            local b1, b2      = string.byte(head, 1, 2)
            local opcode      = b1 % 16
            local payload_len = b2 % 128

            if opcode == 8 then
                log_error("Discord sent a Close Frame. Check your token and intents.")
                os.exit(1)
            end

            if payload_len == 126 then
                local ext = conn:receive(2)
                payload_len = string.byte(ext, 1) * 256 + string.byte(ext, 2)
            end

            local payload = conn:receive(payload_len)
            if payload then
                local data = json.decode(payload)
                if not data then
                    log_error("Received malformed JSON.")
                else
                    -- Opcode 10: Hello
                    if data.op == 10 then
                        log_info("Received Hello. Identifying...")
                        silicord.task.spawn(function()
                            local interval = data.d.heartbeat_interval / 1000
                            silicord.task.wait(interval * math.random())
                            while true do
                                send_frame(conn, json.encode({ op = 1, d = json.null }))
                                silicord.task.wait(interval)
                            end
                        end)
                        -- Intents: 33280 = GUILD_MESSAGES + MESSAGE_CONTENT
                        -- We also add intent 1 (GUILDS) for slash command interactions
                        send_frame(conn, json.encode({
                            op = 2,
                            d  = {
                                token      = token,
                                intents    = 33281,
                                properties = { os = "linux", browser = "silicord", device = "silicord" }
                            }
                        }))
                    end

                    -- Ready
                    if data.op == 0 and data.t == "READY" then
                        log_info("Bot online! Logged in as " .. data.d.user.username .. ". Press Ctrl+C to stop.")
                    end

                    -- Invalid session
                    if data.op == 9 then
                        log_error("IDENTIFY FAILED: Invalid Token or missing Message Content Intent.")
                        os.exit(1)
                    end

                    -- Prefix command dispatch
                    if data.t == "MESSAGE_CREATE" then
                        local msg = Message.new(data.d, token)
                        if not msg.author.bot and msg.content:sub(1, #prefix) == prefix then
                            local body = msg.content:sub(#prefix + 1)
                            -- Split into command name + args
                            local parts = {}
                            for word in body:gmatch("%S+") do
                                table.insert(parts, word)
                            end
                            local cmd_name = parts[1]
                            local args = {}
                            for i = 2, #parts do
                                args[i - 1] = parts[i]
                            end
                            -- Also expose raw args string
                            args.raw = body:match("^%S+%s+(.+)$") or ""

                            if cmd_name and client._commands[cmd_name] then
                                silicord.task.spawn(client._commands[cmd_name].callback, msg, args)
                            else
                                -- Fall back to OnMessage for unregistered commands
                                msg.content = body
                                client.OnMessage:Fire(msg)
                            end
                        end
                    end

                    -- Slash command dispatch (INTERACTION_CREATE)
                    if data.t == "INTERACTION_CREATE" and data.d.type == 2 then
                        local cmd_name = data.d.data and data.d.data.name
                        if cmd_name and client._slash[cmd_name] then
                            local interaction = Interaction.new(data.d, token)
                            silicord.task.spawn(client._slash[cmd_name].callback, interaction, interaction.args)
                        end
                    end
                end
            end

            silicord.task.wait(0.01)
        end
    end)

    return client
end

function silicord.Run()
    log_info("Engine running...")
    local ok, err = pcall(copas.loop)
    if not ok and not err:match("interrupted") then
        log_error("Engine error: " .. tostring(err))
    end
    for _, c in ipairs(silicord._clients) do
        if c._conn then pcall(send_close_frame, c._conn) end
    end
    log_info("Bot disconnected.")
    os.exit(0)
end

return silicord