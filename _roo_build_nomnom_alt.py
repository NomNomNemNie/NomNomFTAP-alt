import base64
import textwrap
from pathlib import Path

ALT = Path(__file__).resolve().parent
ROOT = ALT.parent
STRONG = ROOT / 'Source' / 'Strong'

PACKS = [
    {
        'id': 'wourld',
        'name': 'The Wourld Base',
        'file': 'The Wourld',
        'category': 'Protection / Gucci / Combat',
        'summary': 'Base Wourld pack with Defense, Target, Visuals, Server, Misc, Keybinds, Owner, Credits, and UI settings.',
        'features': ['Defense', 'Target tools', 'Visuals', 'Server utilities', 'Misc', 'Keybinds', 'Owner', 'UI Settings'],
    },
    {
        'id': 'noname',
        'name': 'NoName Pack',
        'file': 'NoName',
        'category': 'Combat / Movement / Utility',
        'summary': 'NoName pack with defense, grab tools, player controls, target tools, keybinds, visuals, misc, owner, config, and lag-related sections.',
        'features': ['Defense', 'Grabs', 'Player controls', 'Target tools', 'Keybinds', 'Visuals', 'Misc', 'Owner', 'Config'],
    },
    {
        'id': 'xoco',
        'name': 'XOCO Pack',
        'file': 'XOCO',
        'category': 'Combat / Protection / Visuals',
        'summary': 'XOCO pack with defense, target, grab, player, misc, keybinds, and visuals tabs.',
        'features': ['Defense', 'Target', 'Grab', 'Player', 'Misc', 'Keybinds', 'Visuals'],
    },
]


def encode_source(path: Path) -> str:
    data = path.read_bytes()
    return base64.b64encode(data).decode('ascii')


def lua_quote(value: str) -> str:
    value = str(value)
    replacements = {
        '\\': '\\\\',
        '"': '\\"',
        '\n': '\\n',
        '\r': '\\r',
        '\t': '\\t',
        '\0': '\\0',
    }
    return '"' + ''.join(replacements.get(ch, ch) for ch in value) + '"'


def lua_string_array(value: str, chunk_size: int = 96) -> str:
    chunks = textwrap.wrap(value, chunk_size)
    return '{\n' + ''.join('                ' + lua_quote(chunk) + ',\n' for chunk in chunks) + '            }'

pack_entries = []
for pack in PACKS:
    source_path = STRONG / pack['file']
    b64 = encode_source(source_path)
    features = ', '.join('{ label = ' + lua_quote(f) + ' }' for f in pack['features'])
    entry = f"""
        {{
            id = {lua_quote(pack['id'])},
            name = {lua_quote(pack['name'])},
            category = {lua_quote(pack['category'])},
            summary = {lua_quote(pack['summary'])},
            features = {{ {features} }},
            encodedChunks = {lua_string_array(b64)},
        }}"""
    pack_entries.append(entry)

lua = f"""-- NomNom.lua - merged lazy 3-pack standalone build for NomNomFTAP-alt.
-- Generated for the alt repository only. The original NomNomFTAP tree is intentionally not touched.
-- Resonance-inspired organizer: Home, Combat, Movement, Visuals, Utility, Protection/Gucci, Teleports/Map, Settings, Search/Favorites/Status.
-- Pack sources are embedded as encoded payloads and decoded/sanitized only when the user presses a load button.
-- Automatic public-room message behavior is intentionally blocked before each pack is executed.

(function()
    local RUNTIME_KEY = "__NomNomAltMergedRuntime_v20260630"
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local previous = env[RUNTIME_KEY]
    if type(previous) == "table" and type(previous.cleanup) == "function" then
        pcall(previous.cleanup)
    end

    local runtime = {{
        connections = {{}},
        gui = nil,
        loaded = {{}},
        statuses = {{}},
        favorites = {{}},
        search = "",
    }}
    env[RUNTIME_KEY] = runtime

    local function addConnection(conn)
        if conn then
            table.insert(runtime.connections, conn)
        end
        return conn
    end

    function runtime.cleanup()
        for _, conn in ipairs(runtime.connections) do
            pcall(function()
                if conn and conn.Disconnect then
                    conn:Disconnect()
                end
            end)
        end
        runtime.connections = {{}}
        if runtime.gui then
            pcall(function() runtime.gui:Destroy() end)
            runtime.gui = nil
        end
    end

    local function nowText()
        return os.date("%H:%M:%S")
    end

    local function recordStatus(message)
        local line = "[" .. nowText() .. "] " .. tostring(message)
        table.insert(runtime.statuses, 1, line)
        while #runtime.statuses > 40 do
            table.remove(runtime.statuses)
        end
        print("[NomNom Alt] " .. tostring(message))
    end

    local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local function decodeBase64(data)
        data = tostring(data or ''):gsub('%s+', '')
        local bits = data:gsub('[^' .. alphabet .. '=]', ''):gsub('.', function(char)
            if char == '=' then
                return ''
            end
            local index = alphabet:find(char, 1, true)
            if not index then
                return ''
            end
            index = index - 1
            local out = ''
            for bit = 6, 1, -1 do
                out = out .. ((index % (2 ^ bit) - index % (2 ^ (bit - 1)) > 0) and '1' or '0')
            end
            return out
        end)
        return bits:gsub('%d%d%d%d%d%d%d%d', function(byte)
            local value = 0
            for i = 1, 8 do
                if byte:sub(i, i) == '1' then
                    value = value + 2 ^ (8 - i)
                end
            end
            return string.char(value)
        end)
    end

    local function tok(a, b, c, d)
        return tostring(a or '') .. tostring(b or '') .. tostring(c or '') .. tostring(d or '')
    end

    local blockedTokens = {{
        tok('Text', 'Chat', 'Service'),
        tok('Say', 'Message', 'Request'),
        tok('Default', 'Chat', 'SystemChatEvents'),
        tok('Send', 'Async'),
        tok('Register', 'SayMessage', 'Function'),
        tok('Chat', ':', 'Chat'),
    }}

    local autoSendCalls = {{
        tok('send', 'Free', 'Chat', 'Announcement'),
        tok('send', 'Hub', 'Loaded', 'Message'),
    }}

    local function sanitizeSource(source)
        source = tostring(source or '')
        for _, token in ipairs(blockedTokens) do
            local replacement = '__NomNomBlocked_' .. token:gsub('[^%w_]', '_')
            source = source:gsub(token, replacement)
        end
        for _, callName in ipairs(autoSendCalls) do
            source = source:gsub(callName .. '%s*%(%s*%)', '--[[ NomNom blocked automatic room message ]]')
        end
        return source
    end

    local packs = {{
{','.join(pack_entries)}
    }}

    local categories = {{
        {{ name = "Home", icon = "⌂", note = "Merged NomNom alt launcher and source catalog." }},
        {{ name = "Combat", icon = "⚔", note = "Target, grab, aura, line, packet, and server-interaction tools exposed by the lazy packs." }},
        {{ name = "Movement", icon = "➜", note = "Player, character, speed, respawn, and positioning controls found in pack tabs." }},
        {{ name = "Visuals", icon = "◉", note = "ESP, camera, display, graphics, and visual quality controls from Resonance-style grouping." }},
        {{ name = "Utility", icon = "◆", note = "Misc, toys, owners, config, keybinds, and general convenience features." }},
        {{ name = "Protection/Gucci", icon = "◇", note = "Defense, invincibility, anti-grab, anti-kick, Gucci protection, and counter-attack areas." }},
        {{ name = "Teleports/Map", icon = "⌖", note = "Teleport, player tracking, map navigation, and target-selection entry points." }},
        {{ name = "Settings", icon = "⚙", note = "Theme, status, favorites, cleanup, and reload controls." }},
    }}

    local function getLoader()
        return loadstring or load
    end

    local function getPackEncoded(pack)
        if type(pack.encoded) == "string" then
            return pack.encoded
        end
        if type(pack.encodedChunks) == "table" then
            return table.concat(pack.encodedChunks)
        end
        return ""
    end

    local function runPack(pack)
        if not pack then
            recordStatus("No pack selected")
            return
        end
        if runtime.loaded[pack.id] then
            recordStatus(pack.name .. " is already marked loaded; use rerun cleanup before reloading if needed")
            return
        end
        local loader = getLoader()
        if type(loader) ~= "function" then
            recordStatus("No Lua chunk loader is available in this executor")
            return
        end
        recordStatus("Decoding " .. pack.name)
        local encoded = getPackEncoded(pack)
        if encoded == "" then
            recordStatus("No encoded payload found for " .. pack.name)
            return
        end
        local okDecode, source = pcall(decodeBase64, encoded)
        if not okDecode or type(source) ~= "string" or source == "" then
            recordStatus("Decode failed for " .. pack.name .. ": " .. tostring(source))
            return
        end
        source = sanitizeSource(source)
        local chunk, err = loader(source, "NomNomAlt::" .. pack.id)
        if type(chunk) ~= "function" then
            recordStatus("Compile failed for " .. pack.name .. ": " .. tostring(err))
            return
        end
        runtime.loaded[pack.id] = true
        task.spawn(function()
            recordStatus("Running " .. pack.name)
            local ok, runErr = pcall(chunk)
            if ok then
                recordStatus(pack.name .. " finished initial load")
            else
                runtime.loaded[pack.id] = nil
                recordStatus(pack.name .. " error: " .. tostring(runErr))
            end
        end)
    end

    local function make(className, props, parent)
        local obj = Instance.new(className)
        for key, value in pairs(props or {{}}) do
            obj[key] = value
        end
        if parent then
            obj.Parent = parent
        end
        return obj
    end

    local function addCorner(parent, radius)
        return make("UICorner", {{ CornerRadius = UDim.new(0, radius or 8) }}, parent)
    end

    local function addStroke(parent, color, transparency)
        return make("UIStroke", {{ Color = color or Color3.fromRGB(80, 80, 95), Transparency = transparency or 0.35, Thickness = 1 }}, parent)
    end

    local function makeButton(parent, text, callback, height)
        local button = make("TextButton", {{
            Size = UDim2.new(1, 0, 0, height or 34),
            BackgroundColor3 = Color3.fromRGB(34, 36, 46),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(238, 238, 245),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = true,
        }}, parent)
        addCorner(button, 8)
        addStroke(button, Color3.fromRGB(90, 95, 125), 0.45)
        addConnection(button.MouseButton1Click:Connect(function()
            if callback then
                callback(button)
            end
        end))
        return button
    end

    local function makeLabel(parent, text, height, textSize, color)
        local label = make("TextLabel", {{
            Size = UDim2.new(1, 0, 0, height or 24),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or Color3.fromRGB(220, 222, 232),
            TextSize = textSize or 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
        }}, parent)
        return label
    end

    local playerService = game:GetService("Players")
    local inputService = game:GetService("UserInputService")
    local localPlayer = playerService.LocalPlayer
    local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui and localPlayer then
        playerGui = localPlayer:WaitForChild("PlayerGui", 5)
    end
    if not playerGui then
        recordStatus("PlayerGui was not available; launcher UI could not be mounted")
        return
    end

    local gui = make("ScreenGui", {{
        Name = "NomNomAltMergedLauncher",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }}, playerGui)
    runtime.gui = gui

    local root = make("Frame", {{
        Size = UDim2.new(0, 760, 0, 500),
        Position = UDim2.new(0.5, -380, 0.5, -250),
        BackgroundColor3 = Color3.fromRGB(13, 14, 18),
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    }}, gui)
    addCorner(root, 14)
    addStroke(root, Color3.fromRGB(120, 122, 155), 0.25)

    local title = make("TextLabel", {{
        Size = UDim2.new(1, -56, 0, 46),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = "NomNom Alt :: Resonance-Inspired 3-Pack Launcher",
        TextColor3 = Color3.fromRGB(245, 245, 248),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }}, root)

    makeButton(root, "×", function()
        runtime.cleanup()
    end, 30).Position = UDim2.new(1, -42, 0, 8)

    local tabBar = make("Frame", {{
        Size = UDim2.new(0, 190, 1, -62),
        Position = UDim2.new(0, 14, 0, 50),
        BackgroundColor3 = Color3.fromRGB(18, 19, 26),
        BorderSizePixel = 0,
    }}, root)
    addCorner(tabBar, 12)
    addStroke(tabBar, Color3.fromRGB(76, 78, 105), 0.45)

    local tabLayout = make("UIListLayout", {{
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }}, tabBar)
    make("UIPadding", {{ PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }}, tabBar)

    local content = make("Frame", {{
        Size = UDim2.new(1, -228, 1, -62),
        Position = UDim2.new(0, 214, 0, 50),
        BackgroundColor3 = Color3.fromRGB(18, 19, 26),
        BorderSizePixel = 0,
    }}, root)
    addCorner(content, 12)
    addStroke(content, Color3.fromRGB(76, 78, 105), 0.45)

    local contentTitle = makeLabel(content, "", 32, 15, Color3.fromRGB(245, 245, 248))
    contentTitle.Position = UDim2.new(0, 14, 0, 10)
    contentTitle.Size = UDim2.new(1, -28, 0, 30)
    contentTitle.Font = Enum.Font.GothamBold

    local scroll = make("ScrollingFrame", {{
        Size = UDim2.new(1, -28, 1, -58),
        Position = UDim2.new(0, 14, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
    }}, content)
    local scrollLayout = make("UIListLayout", {{ Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }}, scroll)

    local function clearScroll()
        for _, child in ipairs(scroll:GetChildren()) do
            if child ~= scrollLayout then
                child:Destroy()
            end
        end
    end

    local function card(parent, titleText, bodyText)
        local frame = make("Frame", {{
            Size = UDim2.new(1, -4, 0, 88),
            BackgroundColor3 = Color3.fromRGB(24, 26, 35),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
        }}, parent)
        addCorner(frame, 10)
        addStroke(frame, Color3.fromRGB(82, 86, 118), 0.55)
        make("UIPadding", {{ PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10) }}, frame)
        local layout = make("UIListLayout", {{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }}, frame)
        makeLabel(frame, titleText, 22, 14, Color3.fromRGB(245, 245, 248)).Font = Enum.Font.GothamBold
        makeLabel(frame, bodyText, 44, 12, Color3.fromRGB(205, 208, 222))
        return frame, layout
    end

    local render
    local currentTab = "Home"

    local function matchesSearch(pack)
        local needle = tostring(runtime.search or ''):lower()
        if needle == '' then
            return true
        end
        local hay = (pack.name .. ' ' .. pack.category .. ' ' .. pack.summary):lower()
        if hay:find(needle, 1, true) then
            return true
        end
        for _, feature in ipairs(pack.features or {{}}) do
            if tostring(feature.label):lower():find(needle, 1, true) then
                return true
            end
        end
        return false
    end

    local function packCard(pack)
        local frame = card(scroll, pack.name .. "  •  " .. pack.category, pack.summary)
        makeLabel(frame, "Feature map: " .. table.concat((function()
            local list = {{}}
            for _, feature in ipairs(pack.features or {{}}) do
                table.insert(list, feature.label)
            end
            return list
        end)(), ", "), 34, 12, Color3.fromRGB(192, 196, 215))
        local loaded = runtime.loaded[pack.id]
        makeButton(frame, loaded and "Loaded" or ("Load " .. pack.name), function()
            runPack(pack)
            task.delay(0.25, function()
                if render then render(currentTab) end
            end)
        end, 32)
        makeButton(frame, runtime.favorites[pack.id] and "★ Favorited" or "☆ Add Favorite", function()
            runtime.favorites[pack.id] = not runtime.favorites[pack.id]
            recordStatus((runtime.favorites[pack.id] and "Favorited " or "Unfavorited ") .. pack.name)
            if render then render(currentTab) end
        end, 30)
    end

    local function renderHome()
        card(scroll, "Resonance reference", "Reference layout observed: Home, Combat, Visual, Misc, Invincibility, Toys, Player, Target, Keybinds, Lists, Auto-Clicker, and Settings; groupboxes emphasize Auras, Grabs, Antis, Counter-attack, ESP, Game Tweaks, Teleporting, Players, Themes, Configuration, and Notifications.")
        card(scroll, "Lazy merge strategy", "The three Strong packs are embedded as encoded payloads. Nothing runs at startup except this catalog UI. A selected pack is decoded, safety-sanitized, compiled, and run only when its Load button is pressed.")
        for _, pack in ipairs(packs) do
            packCard(pack)
        end
    end

    local function renderCategory(tab)
        for _, category in ipairs(categories) do
            if category.name == tab then
                card(scroll, category.icon .. " " .. category.name, category.note)
                break
            end
        end
        if tab == "Combat" then
            card(scroll, "Mapped pack areas", "Wourld: Target/Server/Defense. NoName: Grabs, Line-Lags, Packets-Lags, Target. XOCO: Target, Grab, Defense.")
        elseif tab == "Movement" then
            card(scroll, "Mapped pack areas", "NoName and XOCO both expose Player/Character controls; Wourld includes respawn/runtime toggles and target tracking support.")
        elseif tab == "Visuals" then
            card(scroll, "Mapped pack areas", "Wourld, NoName, and XOCO each expose Visuals tabs; the Resonance reference separates ESP, Camera, Sky, Graphics, and Game Tweaks.")
        elseif tab == "Utility" then
            card(scroll, "Mapped pack areas", "Misc, Owner, Config, Keybinds, Toys, and general convenience controls are retained inside the lazy packs.")
        elseif tab == "Protection/Gucci" then
            card(scroll, "Mapped pack areas", "Defense, anti-grab, anti-kick, invincibility/counter-attack style tools, Gucci protection, and cleanup/remediation controls are cataloged here.")
        elseif tab == "Teleports/Map" then
            card(scroll, "Mapped pack areas", "Target tracking, teleporting/player selection, and map/player navigation features are available from the pack UIs after loading.")
        elseif tab == "Settings" then
            card(scroll, "Runtime controls", "Use rerun cleanup to remove this launcher UI before re-pasting. Loaded pack internals remain governed by their own UIs and unload behavior.")
            makeButton(scroll, "Rerun Cleanup: close launcher", function()
                recordStatus("Manual launcher cleanup requested")
                runtime.cleanup()
            end, 34)
            makeButton(scroll, "Reset loaded markers", function()
                runtime.loaded = {{}}
                recordStatus("Loaded markers reset; pack internals are not force-unloaded")
                if render then render(currentTab) end
            end, 34)
        end
        for _, pack in ipairs(packs) do
            if matchesSearch(pack) then
                packCard(pack)
            end
        end
    end

    local function renderSearch()
        card(scroll, "Search / Favorites / Status", "Search filters the pack catalog by name, category, summary, and mapped feature labels. Favorites are local to this launcher session.")
        local box = make("TextBox", {{
            Size = UDim2.new(1, -4, 0, 36),
            BackgroundColor3 = Color3.fromRGB(24, 26, 35),
            BorderSizePixel = 0,
            Text = runtime.search,
            PlaceholderText = "Search packs/features...",
            TextColor3 = Color3.fromRGB(245, 245, 248),
            PlaceholderColor3 = Color3.fromRGB(130, 134, 150),
            TextSize = 13,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
        }}, scroll)
        addCorner(box, 8)
        addStroke(box, Color3.fromRGB(82, 86, 118), 0.5)
        addConnection(box:GetPropertyChangedSignal("Text"):Connect(function()
            runtime.search = box.Text
        end))
        makeButton(scroll, "Apply Search", function()
            if render then render(currentTab) end
        end, 32)
        local anyFavorite = false
        for _, pack in ipairs(packs) do
            if runtime.favorites[pack.id] and matchesSearch(pack) then
                anyFavorite = true
                packCard(pack)
            end
        end
        if not anyFavorite then
            makeLabel(scroll, "No favorites match the current search.", 28, 12, Color3.fromRGB(180, 184, 202))
        end
        card(scroll, "Status log", (#runtime.statuses > 0 and table.concat(runtime.statuses, "\\n")) or "No status messages yet.")
    end

    function render(tab)
        currentTab = tab or currentTab
        clearScroll()
        contentTitle.Text = currentTab
        if currentTab == "Search/Favorites/Status" then
            renderSearch()
        elseif currentTab == "Home" then
            renderHome()
        else
            renderCategory(currentTab)
        end
    end

    for _, category in ipairs(categories) do
        makeButton(tabBar, category.icon .. "  " .. category.name, function()
            render(category.name)
        end, 36)
    end
    makeButton(tabBar, "★  Search/Favorites/Status", function()
        render("Search/Favorites/Status")
    end, 36)

    addConnection(inputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            root.Visible = not root.Visible
        end
    end))

    recordStatus("Launcher ready; no pack has been auto-loaded")
    render("Home")
end)()
"""

readme = """# NomNom FTAP Alt - Merged 3-Pack Build

This alt repository contains the standalone merged `NomNom.lua` launcher for the NomNom alt target.

## What is merged

`NomNom.lua` embeds all three `Source/Strong` packs as lazy base64 chunk arrays:

- `The Wourld Base` - base pack with Defense, Target, Visuals, Server, Misc, Keybinds, Owner, Credits, and UI settings.
- `NoName Pack` - defense, grab tools, player controls, target tools, keybinds, visuals, misc, owner/config, and lag-related sections.
- `XOCO Pack` - defense, target, grab, player, misc, keybinds, and visuals.

The launcher itself is the only code that runs on paste. Each pack is decoded, sanitized, compiled, and executed only when its load button is pressed.

## Resonance-inspired organization

The reference page at `https://marshelx.github.io/resonance-features/` uses an Obsidian-style layout with tabs such as Home, Combat, Visual, Misc, Invincibility, Toys, Player, Target, Keybinds, Lists, Auto-Clicker, and Settings. Its group boxes include areas such as Auras, Grabs, Antis, Counter-attack, ESP, Game Tweaks, Teleporting, Players, Themes, Configuration, and Notifications.

This build adapts that structure into these launcher categories:

- Home
- Combat
- Movement
- Visuals
- Utility
- Protection/Gucci
- Teleports/Map
- Settings
- Search/Favorites/Status

## Safety and rerun behavior

Automatic public-room message behavior is blocked by the launcher sanitizer before any selected pack runs. The launcher does not send startup public-room messages.

The build includes rerun cleanup for the launcher UI. Re-pasting the script removes the previous launcher instance before creating a new one. Pack internals still use their own runtime/UI behavior after being manually loaded.

## Usage

Paste-run `NomNom.lua`, then choose a pack from the launcher. Right Control toggles the launcher visibility.
"""

(ALT / 'NomNom.lua').write_text(lua, encoding='utf-8', newline='\n')
(ALT / 'README.md').write_text(readme, encoding='utf-8', newline='\n')
print('wrote', ALT / 'NomNom.lua', 'bytes', (ALT / 'NomNom.lua').stat().st_size)
print('wrote', ALT / 'README.md', 'bytes', (ALT / 'README.md').stat().st_size)
