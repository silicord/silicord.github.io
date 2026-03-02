# Disclaimer: This project was a test to see how good AI can get at coding. This library is not meant for profit. Instead, it was made for my own personal use, but I decided to share the open-source code if you want to manually make a PR and contribute. This project will not be mantained as much as my other projects as I work on projects that I actually code myself, but I will check PRs once a week if you want to contribute. Thanks.

# [silicord](https://silicord.github.io) v1.2.0

A Discord bot framework for Lua with **Luau-inspired syntax**. Built for Roblox developers who want to write Discord bots using familiar syntax like `task.wait()`, Signals, `Enum`, and method chaining.

## For a more detailed and user-friendly coding experience, visit the official website at https://silicord.github.io/.

Install silicord via LuaRocks:

```bash
luarocks install silicord
```

---

## Requirements

- Lua 5.1+
- [luasocket](https://luarocks.org/modules/luasocket/luasocket)
- [luasec](https://luarocks.org/modules/brunoos/luasec)
- [copas](https://luarocks.org/modules/tieske/copas)
- [dkjson](https://luarocks.org/modules/dhkolf/dkjson)

These are installed automatically when you install silicord via LuaRocks.

---

## Quick Start

```lua
local silicord = require("silicord")

local client = silicord.Connect({
    token  = "your bot token here",
    prefix = "!"
})

client:CreateCommand("ping", function(message, args)
    message:Reply("Pong!")
end)

silicord.Run()
```

---

## silicord.Connect(config)

| Field    | Type   | Required | Description                                      |
|----------|--------|----------|--------------------------------------------------|
| `token`  | string | yes      | Your Discord bot token                           |
| `prefix` | string | no       | Command prefix (default: `"!"`)                  |
| `app_id` | string | no       | Your Discord application ID (required for slash commands and PresenceService) |

```lua
local client = silicord.Connect({
    token  = "your token",
    prefix = "!",
    app_id = "your application id"
})
```

---

## GetService (v1.2.0+)

silicord uses a service system inspired by Roblox's `game:GetService()`. Services are **lazy-loaded** — only created the first time you call `GetService`, saving memory.

```lua
local DS       = silicord:GetService("DataStoreService")
local Http     = silicord:GetService("HttpService")
local Presence = silicord:GetService("PresenceService")
local AI       = silicord:GetService("AIService")
```

| Service name | Description |
|---|---|
| `"DataStoreService"` | JSON file-based key-value persistence |
| `"HttpService"` | Make outbound HTTP/HTTPS requests |
| `"PresenceService"` | Set the bot's presence, status text, and activity |
| `"AIService"` | Connect an external OpenAI-compatible AI API |

---

## Commands

### Prefix Commands

```lua
-- Basic prefix command
client:CreateCommand("ping", function(message, args)
    message:Reply("Pong!")
end)

-- Command with arguments
-- User types: !say hello world
client:CreateCommand("say", function(message, args)
    -- args[1] = "hello", args[2] = "world"
    -- args.raw = "hello world" (everything after the command)
    message:Reply(args.raw)
end)

-- Command with task.wait
client:CreateCommand("countdown", function(message, args)
    message:Reply("3...")
    silicord.task.wait(1)
    message:Reply("2...")
    silicord.task.wait(1)
    message:Reply("1... Go!")
end)
```

### Slash Commands

Slash commands require `app_id` in your Connect config.

```lua
client:CreateSlashCommand("ban", {
    description = "Ban a user from the server",
    options = {
        { name = "user",   description = "The user to ban",    type = "user",   required = true  },
        { name = "reason", description = "Reason for the ban", type = "string", required = false }
    }
}, function(interaction, args)
    interaction:Reply("Banned " .. args.user .. ". Reason: " .. (args.reason or "none"))
end)
```

**Supported argument types:** `string`, `integer`, `number`, `bool`, `user`, `channel`, `role`, `any`

---

## Message Object

| Method | Description |
|--------|-------------|
| `message:Reply(text)` | Reply to the message. **Returns a Message object.** |
| `message:Reply(text, embed)` | Reply with text and an embed. **Returns a Message object.** |
| `message:Reply(text, embed, components)` | Reply with text, embed, and components. **Returns a Message object.** |
| `message:Send(text)` | Send a message with no ping. **Returns a Message object.** |
| `message:Send(text, embed)` | Send with embed, no ping. **Returns a Message object.** |
| `message:Send(text, embed, components)` | Send with text, embed, and components. **Returns a Message object.** |
| `message:Edit(text)` | Edit the bot's own message |
| `message:React("👍")` | Add a reaction to the message |
| `message:Unreact("👍")` | Remove a reaction the bot placed |
| `message:Delete()` | Delete the message |
| `message:Pin()` | Pin the message in the channel |
| `message:Unpin()` | Unpin the message |
| `message:GetGuild()` | Returns a Guild object (uses cache automatically) |
| `message:GetMember()` | Returns a Member object for the message author |
| `message:SendPrivateMessage(text)` | DM the message author |
| `message:SendPrivateMessage(text, embed)` | DM the message author with an embed |

### Reply and Send return a Message (v1.2.0+)

`message:Reply()` and `message:Send()` now return the sent Message object, letting you chain further actions on the response:

```lua
client:CreateCommand("temp", function(message, args)
    local response = message:Reply("Processing...")
    silicord.task.wait(3)
    response:Edit("Done! ✅")
end)

client:CreateCommand("autodelete", function(message, args)
    local response = message:Send("This disappears in 5 seconds.")
    silicord.task.delay(5, function()
        response:Delete()
    end)
end)
```

```lua
client:CreateCommand("info", function(message, args)
    message:React("👀")
    local embed = silicord.Instance.new("Embed")
    embed.Title       = "Hello!"
    embed.Description = "This is an embed."
    embed.Color       = "#5865F2"
    embed.Footer      = "silicord"
    message:Reply(embed:Build())
end)

-- Send without pinging
client:CreateCommand("announce", function(message, args)
    message:Send("Announcement: " .. args.raw)
end)
```

### message.author

```lua
message.author.id        -- user ID
message.author.username  -- username
message.author.bot       -- true if the author is a bot
```

---

## Member Object

Get a member from a message, interaction, or guild:

```lua
local member = message:GetMember()
local member = interaction:GetMember()
local member = guild:GetMember(user_id)
```

| Method | Description |
|--------|-------------|
| `member:Kick(reason)` | Kick the member |
| `member:Ban(reason, delete_days)` | Ban the member |
| `member:Timeout(seconds, reason)` | Apply a timeout. Accepts a raw number or `Enum.PunishmentLength` value |
| `member:RemoveTimeout()` | Remove an active timeout |
| `member:GiveRole(role_id)` | Give the member a role |
| `member:RemoveRole(role_id)` | Remove a role from the member |
| `member:SetNickname(nick)` | Set the member's nickname |
| `member:ResetNickname()` | Reset the member's nickname |
| `member:SendDM(text)` | Send the member a DM |
| `member:SendDM(text, embed)` | Send the member a DM with an embed |
| `member:GetStatus()` | Returns an `Enum.UserStatusInGuild` value (v1.2.0+) |

```lua
client:CreateCommand("timeout", function(message, args)
    local member = message:GetMember()
    member:Timeout(300, "Spamming")   -- 5 minute timeout
    message:Reply("Member timed out for 5 minutes.")
end)

client:CreateCommand("giverole", function(message, args)
    local guild  = message:GetGuild()
    local member = guild:GetMember(args[1])
    member:GiveRole(args[2])
    message:Reply("Role given!")
end)
```

```lua
-- Enum.PunishmentLength with :Timeout() (v1.2.0+)
member:Timeout(silicord.Enum.PunishmentLength["1Hour"])
member:Timeout(silicord.Enum.PunishmentLength.Permanent)  -- no end date

-- Check member status (v1.2.0+)
local status = member:GetStatus()
if status == silicord.Enum.UserStatusInGuild.Banned then
    ctx:Reply("That user is already banned.")
end
```

### member properties

```lua
member.id        -- user ID
member.username  -- username
member.nickname  -- server nickname (nil if not set)
member.roles     -- table of role IDs the member has
member.user      -- raw Discord user object
```

---

## Interaction Object (Slash Commands & Components)

```lua
interaction:Reply("Hello!")
interaction:Reply(text, embed)
interaction:Reply(text, embed, components)
interaction:Update("Updated content")       -- update the original message (for buttons)
interaction:Update(text, embed, components)
interaction:GetGuild()
interaction:GetMember()
interaction:SendPrivateMessage(text)
interaction:SendPrivateMessage(text, embed)

interaction.args       -- slash command arguments keyed by name
interaction.values     -- selected values from a select menu
interaction.author     -- the user who triggered the interaction
interaction.custom_id  -- the custom_id of the triggering component
interaction.guild_id   -- the guild ID
interaction.channel_id -- the channel ID
```

---

## Enum (v1.2.0+)

Roblox-style enums for type-safe values throughout your bot.

### Enum.Presence

```lua
silicord.Enum.Presence.Online        -- "online"
silicord.Enum.Presence.Idle          -- "idle"
silicord.Enum.Presence.DoNotDisturb  -- "dnd"
silicord.Enum.Presence.Invisible     -- "invisible"
```

### Enum.ChannelType

```lua
silicord.Enum.ChannelType.Text         -- 0
silicord.Enum.ChannelType.DM           -- 1
silicord.Enum.ChannelType.Voice        -- 2
silicord.Enum.ChannelType.GDM          -- 3
silicord.Enum.ChannelType.Category     -- 4
silicord.Enum.ChannelType.Announcement -- 5
silicord.Enum.ChannelType.Thread       -- 11
silicord.Enum.ChannelType.Stage        -- 13
silicord.Enum.ChannelType.Forum        -- 15
silicord.Enum.ChannelType.Media        -- 16

-- Pass directly to guild:CreateChannel()
guild:CreateChannel("general", silicord.Enum.ChannelType.Text)
guild:CreateChannel("Music",   silicord.Enum.ChannelType.Voice)
```

### Enum.Permissions

Permission bit values for role creation and checks:

```lua
silicord.Enum.Permissions.Administrator   -- 0x8
silicord.Enum.Permissions.KickMembers     -- 0x2
silicord.Enum.Permissions.BanMembers      -- 0x4
silicord.Enum.Permissions.ManageMessages  -- 0x2000
silicord.Enum.Permissions.SendMessages    -- 0x800
silicord.Enum.Permissions.ReadMessages    -- 0x400
-- (26 permissions total — see full list in init.lua)

-- Create a role with a specific permission
guild:CreateRole("Admin", silicord.Color3.fromRGB(255, 0, 0), silicord.Enum.Permissions.Administrator)
```

### Enum.PunishmentLength

Pre-defined timeout durations in seconds. Pass directly to `member:Timeout()`:

```lua
silicord.Enum.PunishmentLength["1Minute"]   -- 60
silicord.Enum.PunishmentLength["5Minutes"]  -- 300
silicord.Enum.PunishmentLength["10Minutes"] -- 600
silicord.Enum.PunishmentLength["30Minutes"] -- 1800
silicord.Enum.PunishmentLength["1Hour"]     -- 3600
silicord.Enum.PunishmentLength["6Hours"]    -- 21600
silicord.Enum.PunishmentLength["12Hours"]   -- 43200
silicord.Enum.PunishmentLength["1Day"]      -- 86400
silicord.Enum.PunishmentLength["3Days"]     -- 259200
silicord.Enum.PunishmentLength["1Week"]     -- 604800
silicord.Enum.PunishmentLength.Permanent    -- nil (no end date)

member:Timeout(silicord.Enum.PunishmentLength["30Minutes"], "Spamming")
member:Timeout(silicord.Enum.PunishmentLength.Permanent,    "Repeated violations")
```

### Enum.UserStatusInGuild

Returned by `member:GetStatus()`:

```lua
silicord.Enum.UserStatusInGuild.None     -- "none"
silicord.Enum.UserStatusInGuild.TimedOut -- "timed_out"
silicord.Enum.UserStatusInGuild.Kicked   -- "kicked"
silicord.Enum.UserStatusInGuild.Banned   -- "banned"
```

---

## Embeds

### ✅ OOP API: recommended (v1.0.0+)

```lua
local embed = silicord.Instance.new("Embed")
embed.Title       = "My Embed"
embed.Description = "This is the description."
embed.Color       = silicord.Color3.fromRGB(88, 101, 242)
embed.Url         = "https://example.com"
embed.Timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
embed.Author      = "Author Name"
embed.AuthorIcon  = "https://example.com/icon.png"
embed.AuthorUrl   = "https://example.com"
embed.Footer      = "Footer text"
embed.FooterIcon  = "https://example.com/icon.png"
embed.Image       = "https://example.com/image.png"
embed.Thumbnail   = "https://example.com/thumb.png"
embed:AddField("Field 1", "Value 1", true)
embed:AddField("Field 2", "Value 2", false)

message:Reply("Here's some info:", embed:Build())
```

| Property / Method | Description |
|---|---|
| `embed.Title` | Title string |
| `embed.Description` | Body text |
| `embed.Color` | Hex string, integer, or `Color3` object |
| `embed.Url` | URL for the title link |
| `embed.Timestamp` | ISO 8601 timestamp string |
| `embed.Author / .AuthorIcon / .AuthorUrl` | Author section |
| `embed.Footer / .FooterIcon` | Footer section |
| `embed.Image / .Thumbnail` | Image URLs |
| `embed:AddField(name, value, inline)` | Add a field; returns the embed for chaining |
| `embed:Build()` | Returns the final table to pass to `:Reply()` etc. |

### ⚠️ Table syntax: deprecated (pre-v0.4.3)

> **Deprecated since v1.0.0.** Still works but prints a runtime warning. Will be removed in a future version.

```lua
-- ⚠ DEPRECATED
local embed = silicord.Embed({ title = "My Embed", color = "#5865F2" })
```

---

## Color3

```lua
local c = silicord.Color3.fromRGB(88, 101, 242)
local c = silicord.Color3.fromHex("#5865F2")

-- Pass directly to any color field — no :ToInt() needed
embed.Color = silicord.Color3.fromHex("#57F287")
guild:CreateRole("Mod", silicord.Color3.fromRGB(255, 165, 0))
```

| Method / Property | Description |
|---|---|
| `Color3.fromRGB(r, g, b)` | Construct from 0–255 RGB values |
| `Color3.fromHex(hex)` | Construct from a hex string (`"#RRGGBB"` or `"RRGGBB"`) |
| `color.r / .g / .b` | Individual channel values (0–255) |
| `color:ToInt()` | Returns the packed integer (rarely needed) |

---

## Components (Buttons & Select Menus)

### ✅ OOP API: recommended (v1.0.0+)

```lua
client:CreateCommand("vote", function(message, args)
    local yes = silicord.Instance.new("Button")
    yes.Label    = "Yes"
    yes.Style    = "success"
    yes.CustomId = "vote_yes"

    local no = silicord.Instance.new("Button")
    no.Label    = "No"
    no.Style    = "danger"
    no.CustomId = "vote_no"

    local row = silicord.Instance.new("ActionRow")
    row:Add(yes)
    row:Add(no)

    message:Reply("Cast your vote!", nil, { row:Build() })
end)

client:CreateComponent("vote_yes", function(interaction)
    interaction:Update("You voted **Yes**! ✅")
end)
```

**Button properties:**

| Property | Description |
|---|---|
| `button.Label` | Button text (default: `"Button"`) |
| `button.Style` | `"primary"`, `"secondary"`, `"success"`, `"danger"`, `"link"` |
| `button.CustomId` | ID matched by `client:CreateComponent()` |
| `button.Url` | URL for `"link"`-style buttons |
| `button.Emoji` | Emoji string (e.g. `"👍"`) |
| `button.Disabled` | `true` to disable (default: `false`) |
| `button:Build()` | Returns the raw component table |

**SelectMenu:**

```lua
local menu = silicord.Instance.new("SelectMenu")
menu.CustomId    = "color_pick"
menu.Placeholder = "Pick a color"
menu:AddOption("Red",   "red",   "A warm color")
menu:AddOption("Blue",  "blue",  "A cool color")
menu:AddOption("Green", "green", "A natural color")

local row = silicord.Instance.new("ActionRow")
row:Add(menu)
message:Reply("Choose a color:", nil, { row:Build() })

client:CreateComponent("color_pick", function(interaction)
    interaction:Update("You picked: **" .. interaction.values[1] .. "**")
end)
```

| Property / Method | Description |
|---|---|
| `menu.CustomId` | ID matched by `client:CreateComponent()` |
| `menu.Placeholder` | Placeholder text (default: `"Select an option..."`) |
| `menu.MinValues / .MaxValues` | Selection limits (default: 1) |
| `menu:AddOption(label, value, desc, emoji, default)` | Add an option; returns the menu for chaining |
| `menu:Build()` | Returns the raw component table |

### ⚠️ Deprecated helpers

| Deprecated | Replacement |
|---|---|
| `silicord.Embed({ ... })` | `silicord.Instance.new("Embed")` |
| `silicord.Button({ ... })` | `silicord.Instance.new("Button")` |
| `silicord.SelectMenu({ ... })` | `silicord.Instance.new("SelectMenu")` |
| `silicord.ActionRow(...)` | `silicord.Instance.new("ActionRow")` |
| `silicord.DataStore("name")` | `silicord:GetService("DataStoreService"):GetDataStore("name")` |

---

## DataStoreService (v1.2.0+)

> **v1.2.0:** `silicord.DataStore()` is now deprecated. Use `DataStoreService` instead.

```lua
local DS = silicord:GetService("DataStoreService")
local db = DS:GetDataStore("PlayerData")

db:SetAsync("score_user123", 500)

local score = db:GetAsync("score_user123")

local new_score = db:IncrementAsync("score_user123", 10)

db:RemoveAsync("score_user123")

local keys = db:GetKeys()
for _, k in ipairs(keys) do
    print(k, db:GetAsync(k))
end
```

Each store saves to a `<name>.datastore.json` file. Calling `GetDataStore("name")` twice returns the same cached instance.

**Safety features:**
- Empty or missing files start as a fresh store instead of crashing
- Corrupt JSON is automatically backed up to `name.datastore.json.corrupted_<timestamp>` and the store resets
- All writes use an atomic temp-file swap — a crash mid-write cannot corrupt your data
- `IncrementAsync` resets non-numeric values to `0` with a warning instead of throwing

| Method | Description |
|---|---|
| `store:SetAsync(key, value)` | Write any JSON-serializable value |
| `store:GetAsync(key)` | Read a value; returns `nil` if missing |
| `store:RemoveAsync(key)` | Delete a key |
| `store:IncrementAsync(key, delta)` | Add `delta` to a numeric key (default `+1`) |
| `store:GetKeys()` | Returns a table of all keys in the store |

---

## HttpService (v1.2.0+)

Make outbound HTTP/HTTPS requests from your bot.

```lua
local Http = silicord:GetService("HttpService")

-- GET request
local body, code = Http:Get("https://api.example.com/data")

-- POST request
local body, code = Http:Post("https://api.example.com/submit", '{"key":"value"}')

-- Full control
local body, code = Http:Request("https://api.example.com", "PATCH", '{"x":1}', {
    ["X-Custom-Header"] = "abc"
})
```

| Method | Description |
|---|---|
| `Http:Get(url, headers?)` | GET request; returns `body, status_code` |
| `Http:Post(url, body, headers?)` | POST request; returns `body, status_code` |
| `Http:Request(url, method, body?, headers?)` | Full request with any HTTP method |

---

## PresenceService (v1.2.0+)

Set the bot's presence and activity text. Requires `app_id` in your Connect config.

```lua
local Presence = silicord:GetService("PresenceService")

Presence:SetPresence(client, {
    presence = silicord.Enum.Presence.Online,  -- Enum.Presence value
    status   = "Watching over the server!",     -- text shown under the bot's name
    type     = 3                                -- 0=Playing, 1=Streaming, 2=Listening, 3=Watching, 5=Competing
})
```

| Option | Type | Description |
|---|---|---|
| `presence` | `Enum.Presence` | Status indicator (default: `Online`) |
| `status` | string | Activity text displayed under the bot's name |
| `type` | number | Activity type (default: `0` = Playing) |

---

## AIService (v1.2.0+)

Connect an OpenAI-compatible AI to your bot. Works with OpenAI, Groq, and any provider using the `/v1/chat/completions` endpoint.

```lua
local AI = silicord:GetService("AIService")

AI:Configure("sk-your-api-key-here", {
    model    = "gpt-4o",                    -- default: "gpt-3.5-turbo"
    base_url = "https://api.openai.com/v1"  -- change for other providers
})

client:CreateSlashCommand("ask", {
    description = "Ask the AI a question",
    options = {
        { name = "question", description = "Your question", type = "string", required = true }
    }
}, function(interaction, args)
    local reply = AI:Prompt(args.question, "You are a helpful Discord bot assistant.")
    interaction:Reply(reply or "Sorry, I couldn't get a response.")
end)
```

| Method | Description |
|---|---|
| `AI:Configure(api_key, options?)` | Set your API key; optionally override `model` and `base_url` |
| `AI:Prompt(prompt, system?)` | Send a prompt; returns the response string (or `nil, error` on failure) |

---

## Error Handling

```lua
client.OnError:Connect(function(error_type, ctx, name, detail)
    if error_type == "CommandNotFound" then
        ctx:Reply("❌ Unknown command `!" .. name .. "`.")
    elseif error_type == "MissingArgument" then
        ctx:Reply("❌ Missing argument for `!" .. name .. "`.")
    elseif error_type == "CommandError" then
        ctx:Reply("❌ Something went wrong running `!" .. name .. "`.")
        print("CommandError in !" .. name .. ": " .. detail)
    elseif error_type == "SlashCommandError" then
        ctx:Reply("❌ Something went wrong running `/" .. name .. "`.")
    elseif error_type == "ComponentError" then
        print("ComponentError in " .. name .. ": " .. detail)
    elseif error_type == "UnknownInteraction" then
        ctx:Reply("❌ Unknown slash command.")
    end
end)
```

### Error types

| Error type | When it fires | `ctx` type | `name` | `detail` |
|---|---|---|---|---|
| `CommandNotFound` | User typed an unregistered prefix command | Message | command name | nil |
| `MissingArgument` | Command errored and args were empty | Message | command name | Lua error string |
| `CommandError` | Command callback threw a runtime error | Message | command name | Lua error string |
| `SlashCommandError` | Slash command callback threw a runtime error | Interaction | command name | Lua error string |
| `ComponentError` | Component callback threw a runtime error | Interaction | custom_id | Lua error string |
| `UnknownInteraction` | Slash command triggered with no registered handler | Interaction | command name | nil |

---

## Guild Object

```lua
local guild = message:GetGuild()
-- guild.id, guild.name
```

| Method | Description |
|--------|-------------|
| `guild:CreateChannel(name, kind, options)` | Create a channel. `kind` accepts a string or `Enum.ChannelType` value |
| `guild:EditChannel(channel_id, options)` | Edit an existing channel |
| `guild:DeleteChannel(channel_id)` | Delete a channel |
| `guild:CreateRole(name, color, permissions)` | Create a role. `color` accepts hex, integer, or `Color3`. `permissions` accepts `Enum.Permissions` values |
| `guild:EditRole(role_id, options)` | Edit a role |
| `guild:DeleteRole(role_id)` | Delete a role |
| `guild:GetMembers(limit)` | Returns a list of Member objects |
| `guild:GetMember(user_id)` | Returns a single Member object |
| `guild:GetRandomMember()` | Returns a random Member (from first 100) |
| `guild:GetChannels()` | Returns all channels |
| `guild:GetRoles()` | Returns all roles |
| `guild:KickMember(user_id, reason)` | Kick a member by ID |
| `guild:BanMember(user_id, reason)` | Ban a member by ID |
| `guild:CreateEvent(options)` | Create a scheduled event |
| `guild:EditEvent(event_id, options)` | Edit a scheduled event |
| `guild:DeleteEvent(event_id)` | Delete a scheduled event |
| `guild:GetEvents()` | Returns all scheduled events |
| `guild:Edit(options)` | Edit the server |

### Channel types

```lua
-- String names still work
guild:CreateChannel("general", "text")
guild:CreateChannel("Music",   "voice")

-- Enum.ChannelType values also work (v1.2.0+)
guild:CreateChannel("general", silicord.Enum.ChannelType.Text)
guild:CreateChannel("Music",   silicord.Enum.ChannelType.Voice)

-- With options
guild:CreateChannel("general", "text", {
    topic     = "General chat",
    parent_id = "category_channel_id",
    nsfw      = false,
    slowmode  = 5
})
guild:CreateChannel("Music", "voice", {
    bitrate    = 64000,
    user_limit = 10
})
```

### Scheduled Events

```lua
guild:CreateEvent({
    name       = "Game Night",
    type       = "external",
    location   = "Discord Stage",
    start_time = "2025-09-01T20:00:00Z",
    end_time   = "2025-09-01T23:00:00Z"
})

guild:CreateEvent({
    name       = "Community Call",
    type       = "stage",
    channel_id = "stage_channel_id",
    start_time = "2025-09-01T20:00:00Z",
    end_time   = "2025-09-01T21:00:00Z"
})

guild:EditEvent(event_id, { name = "Updated Name" })
guild:DeleteEvent(event_id)
local events = guild:GetEvents()
```

---

## Signal

```lua
local mySignal = silicord.Signal.new()

local conn = mySignal:Connect(function(a, b)
    print("Signal fired!", a, b)
end)

mySignal:Fire("hello", 42)
conn.Disconnect()

-- Yield until the signal fires (must be inside a coroutine)
silicord.task.spawn(function()
    local a, b = mySignal:Wait()
    print("Resumed with:", a, b)
end)

-- Built-in: listen to all non-command, non-bot messages
client.OnMessage:Connect(function(message)
    print(message.author.username .. ": " .. message.content)
end)
```

| Method | Description |
|---|---|
| `Signal.new()` | Create a new signal |
| `signal:Connect(callback)` | Add a listener; returns a connection with `.Disconnect()` |
| `signal:Fire(...)` | Fire the signal; all listeners run in spawned threads |
| `signal:Wait()` | Yield the current coroutine until the signal fires |

---

## Standard Libraries

### silicord.math

| Function | Description |
|---|---|
| `silicord.math.clamp(n, min, max)` | Clamp `n` between `min` and `max` |
| `silicord.math.round(n)` | Round to the nearest integer |
| `silicord.math.lerp(a, b, t)` | Linear interpolation |
| `silicord.math.sign(n)` | Returns `1`, `-1`, or `0` |

### silicord.table

| Function | Description |
|---|---|
| `silicord.table.find(t, value)` | Returns the index of `value`, or `nil` |
| `silicord.table.contains(t, value)` | Returns `true` if `value` is in the table |
| `silicord.table.keys(t)` | Returns all keys as a sequential table |
| `silicord.table.values(t)` | Returns all values as a sequential table |
| `silicord.table.copy(t)` | Shallow copy of a table |

### silicord.string

| Function | Description |
|---|---|
| `silicord.string.split(str, sep)` | Split by separator pattern (default: whitespace) |
| `silicord.string.trim(str)` | Remove leading and trailing whitespace |
| `silicord.string.startsWith(str, prefix)` | Returns `true` if `str` starts with `prefix` |
| `silicord.string.endsWith(str, suffix)` | Returns `true` if `str` ends with `suffix` |
| `silicord.string.pad(str, length, char)` | Right-pad to `length` with `char` (default: space) |

```lua
local clamped = silicord.math.clamp(150, 0, 100)    -- 100
local lerped  = silicord.math.lerp(0, 10, 0.5)      -- 5.0

local parts = silicord.string.split("a,b,c", ",")   -- {"a","b","c"}
local clean = silicord.string.trim("  hello  ")     -- "hello"

local idx  = silicord.table.find({"a","b","c"}, "b") -- 2
local copy = silicord.table.copy(someTable)
```

---

## CollectionService

```lua
local cs = silicord.CollectionService

cs:AddTag(message.author.id, "admin")
cs:AddTag(message.author.id, "vip")

print(cs:HasTag(message.author.id, "admin"))  -- true

local admins = cs:GetTagged("admin")
local tags   = cs:GetTags(message.author.id)  -- { "admin", "vip" }

cs:RemoveTag(message.author.id, "vip")
```

| Method | Description |
|---|---|
| `cs:AddTag(object, tag)` | Attach a tag to any value |
| `cs:RemoveTag(object, tag)` | Remove a specific tag |
| `cs:HasTag(object, tag)` | Returns `true` if the object has the tag |
| `cs:GetTagged(tag)` | Returns all objects with this tag |
| `cs:GetTags(object)` | Returns all tags on this object |

---

## Middleware

Return `false` from any middleware function to block the command. Multiple middleware functions run in registration order.

```lua
-- Cooldown (3 seconds per user per command)
local cooldowns = {}
client:AddMiddleware(function(ctx, cmd, args)
    local key = ctx.author.id .. ":" .. cmd
    if os.time() - (cooldowns[key] or 0) < 3 then
        ctx:Reply("Slow down! Wait 3 seconds between commands.")
        return false
    end
    cooldowns[key] = os.time()
end)

-- Admin-only guard using CollectionService tags
silicord.CollectionService:AddTag(nil, "ban",  "AdminOnly")
silicord.CollectionService:AddTag(nil, "kick", "AdminOnly")

local ADMIN_ID = "123456789012345678"
client:AddMiddleware(function(ctx, cmd, args)
    if silicord.CollectionService:HasTag(nil, cmd, "AdminOnly") then
        if ctx.author.id ~= ADMIN_ID then
            ctx:Reply("You don't have permission to use this command.")
            return false
        end
    end
end)
```

---

## task (Roblox-style Scheduler)

| Function | Description |
|---|---|
| `silicord.task.wait(n)` | Yield for `n` seconds; returns `n` |
| `silicord.task.spawn(f, ...)` | Run `f` in a new coroutine immediately |
| `silicord.task.defer(f, ...)` | Run `f` on the next scheduler cycle |
| `silicord.task.delay(n, f, ...)` | Call `f(...)` after `n` seconds without blocking |

```lua
-- Pause inside any coroutine
silicord.task.wait(2)

-- Fire and forget a background thread
silicord.task.spawn(function()
    silicord.task.wait(5)
    print("5 seconds later")
end)

-- defer: runs after the current frame completes
silicord.task.defer(function()
    print("deferred to next cycle")
end)

-- delay: clean one-shot timer
silicord.task.delay(10, function()
    print("10 seconds have passed!")
end)

-- Practical: send a temp message that auto-deletes
client:CreateCommand("temp", function(message, args)
    local response = message:Reply("This disappears in 5 seconds!")
    silicord.task.delay(5, function()
        response:Delete()
    end)
end)
```

---

## Caching

```lua
client.cache.guilds   -- raw guild data keyed by guild ID
client.cache.users    -- raw user data keyed by user ID
client.cache.bot_user -- the bot's own user object (set after READY)
```

---

## Sharding

Fully automatic. silicord fetches the recommended shard count on startup and spawns connections with the required 5-second delay. No configuration needed.

---

## Full Example

```lua
local silicord = require("silicord")

-- Services (lazy-loaded, not work until used)
local DS       = silicord:GetService("DataStoreService")
local Presence = silicord:GetService("PresenceService")
local AI       = silicord:GetService("AIService")

AI:Configure("sk-your-key-here", { model = "gpt-4o" })

local db = DS:GetDataStore("Scores")

local client = silicord.Connect({
    token  = "your token here",
    prefix = "!",
    app_id = "your app id here"
})

-- Set presence after gateway connects
silicord.task.spawn(function()
    silicord.task.wait(3)
    Presence:SetPresence(client, {
        presence = silicord.Enum.Presence.Online,
        status   = "Watching the server!",
        type     = 3
    })
end)

-- Cooldown middleware
local cooldowns = {}
client:AddMiddleware(function(ctx, cmd, args)
    local key = ctx.author.id .. ":" .. cmd
    if os.time() - (cooldowns[key] or 0) < 3 then
        ctx:Reply("Wait 3 seconds between commands.")
        return false
    end
    cooldowns[key] = os.time()
end)

-- Error handling
client.OnError:Connect(function(error_type, ctx, name, detail)
    if error_type == "CommandNotFound" then
        ctx:Reply("❌ Unknown command `!" .. name .. "`.")
    elseif error_type == "MissingArgument" then
        ctx:Reply("❌ Missing argument for `!" .. name .. "`.")
    elseif error_type == "CommandError" or error_type == "SlashCommandError" then
        ctx:Reply("❌ Something went wrong. Please try again.")
        print("[Error] " .. name .. ": " .. detail)
    end
end)

-- !ping
client:CreateCommand("ping", function(message, args)
    message:Reply("Pong!")
end)

-- !score — DataStoreService
client:CreateCommand("score", function(message, args)
    local new = db:IncrementAsync(message.author.id, 1)
    message:Reply("Your score: **" .. new .. "**")
end)

-- !timeout — Enum.PunishmentLength
client:CreateCommand("timeout", function(message, args)
    local member = message:GetMember()
    member:Timeout(silicord.Enum.PunishmentLength["5Minutes"], "Spamming")
    message:Reply("Timed out for 5 minutes.")
end)

-- !temp — chain edit on returned Message (v1.2.0)
client:CreateCommand("temp", function(message, args)
    local response = message:Reply("Processing...")
    silicord.task.wait(3)
    response:Edit("Done! ✅")
end)

-- !vote — buttons
client:CreateCommand("vote", function(message, args)
    local yes = silicord.Instance.new("Button")
    yes.Label = "Yes"; yes.Style = "success"; yes.CustomId = "vote_yes"

    local no = silicord.Instance.new("Button")
    no.Label = "No"; no.Style = "danger"; no.CustomId = "vote_no"

    local row = silicord.Instance.new("ActionRow")
    row:Add(yes); row:Add(no)
    message:Reply("Cast your vote!", nil, { row:Build() })
end)

client:CreateComponent("vote_yes", function(interaction) interaction:Update("You voted **Yes**! ✅") end)
client:CreateComponent("vote_no",  function(interaction) interaction:Update("You voted **No**! ❌")  end)

-- /ask — AI slash command
client:CreateSlashCommand("ask", {
    description = "Ask the AI a question",
    options = {
        { name = "question", description = "Your question", type = "string", required = true }
    }
}, function(interaction, args)
    local reply = AI:Prompt(args.question, "You are a helpful Discord bot assistant.")
    interaction:Reply(reply or "Sorry, I couldn't get a response.")
end)

silicord.Run()
```

---

## License

MIT: see [LICENSE](LICENSE)

---

## Links

- [LuaRocks page](https://luarocks.org/modules/mrpandolaofficial-art/silicord)
- [GitHub](https://github.com/mrpandolaofficial/silicord)
- [Discord Developer Portal](https://discord.com/developers/applications)

---

## Version History

- **v1.2.0**: `silicord:GetService()` system with `DataStoreService`, `HttpService`, `PresenceService`, and `AIService`; `Enum` types (`Enum.Presence`, `Enum.ChannelType`, `Enum.Permissions`, `Enum.PunishmentLength`, `Enum.UserStatusInGuild`); `message:Reply()` and `message:Send()` now return a Message object for chaining; `message:Unreact(emoji)` added; `member:GetStatus()` added; `member:Timeout()` now accepts `Enum.PunishmentLength` values including `Permanent`; `guild:CreateChannel()` now accepts `Enum.ChannelType` values; `silicord.DataStore()` deprecated in favour of `DataStoreService`
- **v1.1.0**: 18 bug fixes — `OnMessage` fires correctly for plain messages, nil author guard for webhook messages, Signal fire snapshot safety, Signal:Wait coroutine guard, WebSocket large frame fix, GET request body fix, rate limit retry cap, embed detection overhaul, ActionRow empty component guard, Lua 5.1 `unpack` compat, DataStore variable shadowing fix, Guild:CreateRole color fix, Message:Edit nil id guard, Run error type safety
- **v1.0.0**: DataStore safety (atomic writes, corrupt JSON backup, safe `IncrementAsync`); `Color3` accepted directly in all color fields; `task.defer()` and `task.delay()`; `Instance.new("SelectMenu")` and `Instance.new("ActionRow")`; `silicord.Embed()`, `silicord.Button()`, `silicord.SelectMenu()`, `silicord.ActionRow()` deprecated with runtime warnings
- **v0.4.3**: Added nice favicon
- **v0.4.2**: Fixed typo in `README.md`
- **v0.4.1**: Added new website: https://silicord.github.io/
- **v0.4.0**: Added custom error handling via `client.OnError`
- **v0.3.3**: Minor bug fixes and improvements
- **v0.3.2**: Introduced token validation before startup
- **v0.3.1**: Improved error messages for easier debugging
- **v0.3.0**: Member object with full moderation actions; expanded channel types; channel/role editing and deletion; scheduled events; `message:Send()`, `message:Edit()`, `message:Pin()`, `message:Unpin()`; `message:GetMember()` and `interaction:GetMember()`; `guild:Edit()`
- **v0.2.2**: Automatic sharding, buttons & select menus, rate limit controller, state caching, middleware system
- **v0.2.0**: Guild object, reactions, embeds, DMs, prefix command arguments, slash commands, `task.wait()` support
- **v0.1.0**: silicord prototype — basic `:Reply()`, WebSocket gateway connection
- **v0.0.2**: Fixed WebSocket frame masking