# To be added in silicord v1.2.x

### v1.2.0 Additions

- Addition of new `message` actions like `:Unreact()`.
- Addition of new SilicordServices and `silicord:GetService("service")`:
    - `AIService`: Use a paid/free API key to connect an external AI to your bot.
    - `HttpService`: Make requests to external HTTP links.
    - `PresenceService`: Set the presence and status
    They must define the service FIRST before they will be able to use it (saving RAM)
    ```lua
    local silicord = require("silicord")
    local Presence = silicord:GetService("PresenceService")

    -- define client
    local client = silicord.Connect({
        token = "..."
        prefix = ">"
        app_id = "1234567890" -- also required for presence
    })

    Presence:SetPresence(client, { -- note that instead of client:SetPresence, we use Presence:SetPresence(client, {})
        presence = Enum.Presence.Online -- uses the Enum feature
        status = "I'm up and running!" -- the text displayed below the bots name.
    })
    
- Allow `:Reply()` and `:Send()` to return the message object. For example
    ```lua
    local response = message:Reply("Here is my message!")
    silicord.task.wait(2)
    response:Edit("This message has been edited now!")
    ```

- Introduction of `Enum` types, for example:
    - `Enum.Permissions`(every permission ranging from `ReadMessages` to `Administrator`)
    - `Enum.Presence` (online, dnd, idle, or invisible)
    - `Enum.ChannelType` (text, gdm, dm, voice, category, forum, thread, media, stage, or announcement)
    - `Enum.PunishmentLength` (ranges from 1Minute to 1Week or Permanent)
    - `Enum.UserStatusInGuild` (Banned? Kicked? Timed out? None?)