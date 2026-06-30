import base64
import textwrap
from pathlib import Path

ALT = Path(__file__).resolve().parent
ROOT = ALT.parent
STRONG = ROOT / 'Source' / 'Strong'

EXTRA_PACKS = [
    {
        'id': 'noname',
        'name': 'NoName Pack',
        'file': 'NoName',
        'category': 'Combat / Movement / Utility',
        'summary': 'Lazy extra pack with defense, grab tools, player controls, target tools, keybinds, visuals, misc, owner/config, and lag-related sections.',
    },
    {
        'id': 'xoco',
        'name': 'XOCO Pack',
        'file': 'XOCO',
        'category': 'Combat / Protection / Visuals',
        'summary': 'Lazy extra pack with defense, target, grab, player, misc, keybinds, and visuals tabs.',
    },
]

BLOCKED_TOKEN_PARTS = [
    ('Text', 'Chat', 'Service'),
    ('Say', 'Message', 'Request'),
    ('Default', 'Chat', 'SystemChatEvents'),
    ('Send', 'Async'),
    ('Register', 'SayMessage', 'Function'),
    ('Chat', ':', 'Chat'),
]

AUTO_SEND_PARTS = [
    ('send', 'Free', 'Chat', 'Announcement'),
    ('send', 'Hub', 'Loaded', 'Message'),
]


def encode_source(path: Path) -> str:
    return base64.b64encode(path.read_bytes()).decode('ascii')


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


def lua_string_array(value: str, indent: str = '                ', chunk_size: int = 96) -> str:
    chunks = textwrap.wrap(value, chunk_size)
    return '{\n' + ''.join(indent + lua_quote(chunk) + ',\n' for chunk in chunks) + '            }'


def join_parts(parts) -> str:
    return ''.join(parts)


def sanitize_public_room_source(source: str) -> str:
    """Remove exact public-room API identifiers/calls from visible base source."""
    for parts in BLOCKED_TOKEN_PARTS:
        token = join_parts(parts)
        replacement = '__NomNomBlocked_' + ''.join(ch if ch.isalnum() or ch == '_' else '_' for ch in token)
        source = source.replace(token, replacement)
    for parts in AUTO_SEND_PARTS:
        call_name = join_parts(parts)
        source = source.replace(call_name + '()', '-- NomNom blocked automatic room message')
    return source


def lua_tok_call(parts) -> str:
    args = ', '.join(lua_quote(part) for part in parts)
    return f'NomNomExtraTok({args})'


def build_extra_loader_lua() -> str:
    encoded_by_id = {
        pack['id']: lua_string_array(encode_source(STRONG / pack['file']))
        for pack in EXTRA_PACKS
    }
    pack_status_lines = [
        f'        NomNomExtraNotify({lua_quote(pack["name"] + " - " + pack["category"] + ": " + pack["summary"])})'
        for pack in EXTRA_PACKS
    ]
    blocked = ',\n        '.join(lua_tok_call(parts) for parts in BLOCKED_TOKEN_PARTS)
    auto_calls = ',\n        '.join(lua_tok_call(parts) for parts in AUTO_SEND_PARTS)

    return f'''

do
    local NomNomExtraRuntimeKey = "__NomNomExtraPacks_20260630_ObsidianBase"
    local NomNomExtraEnv = (type(getgenv) == "function" and getgenv()) or _G
    local NomNomExtraRuntime = NomNomExtraEnv[NomNomExtraRuntimeKey]
    if type(NomNomExtraRuntime) ~= "table" then
        NomNomExtraRuntime = {{ loaded = {{}}, status = {{}} }}
        NomNomExtraEnv[NomNomExtraRuntimeKey] = NomNomExtraRuntime
    end

    local function NomNomExtraNotify(message)
        message = tostring(message or "")
        table.insert(NomNomExtraRuntime.status, 1, os.date("%H:%M:%S") .. " " .. message)
        while #NomNomExtraRuntime.status > 20 do
            table.remove(NomNomExtraRuntime.status)
        end
        print("[NomNom Packs] " .. message)
        if c and type(c.Notify) == "function" then
            pcall(function()
                c:Notify({{ Title = "NomNom Packs"; Description = message; Duration = 3 }})
            end)
        end
    end

    local NomNomExtraAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function NomNomExtraDecodeBase64(data)
        data = tostring(data or ""):gsub("%s+", "")
        local bits = data:gsub("[^" .. NomNomExtraAlphabet .. "=]", ""):gsub(".", function(char)
            if char == "=" then
                return ""
            end
            local index = NomNomExtraAlphabet:find(char, 1, true)
            if not index then
                return ""
            end
            index = index - 1
            local out = ""
            for bit = 6, 1, -1 do
                out = out .. ((index % (2 ^ bit) - index % (2 ^ (bit - 1)) > 0) and "1" or "0")
            end
            return out
        end)
        return bits:gsub("%d%d%d%d%d%d%d%d", function(byte)
            local value = 0
            for i = 1, 8 do
                if byte:sub(i, i) == "1" then
                    value = value + 2 ^ (8 - i)
                end
            end
            return string.char(value)
        end)
    end

    local function NomNomExtraTok(a, b, d, e)
        return tostring(a or "") .. tostring(b or "") .. tostring(d or "") .. tostring(e or "")
    end

    local NomNomExtraBlockedTokens = {{
        {blocked}
    }}

    local NomNomExtraAutoCalls = {{
        {auto_calls}
    }}

    local function NomNomExtraSanitizeSource(source)
        source = tostring(source or "")
        for _, token in ipairs(NomNomExtraBlockedTokens) do
            local replacement = "__NomNomBlocked_" .. token:gsub("[^%w_]", "_")
            source = source:gsub(token, replacement)
        end
        for _, callName in ipairs(NomNomExtraAutoCalls) do
            source = source:gsub(callName .. "%s*%(%s*%)", "--[[ NomNom blocked automatic room message ]]" )
        end
        return source
    end

    local function NomNomExtraGetEncoded(packId)
        if packId == "noname" then
            return table.concat({encoded_by_id['noname']})
        elseif packId == "xoco" then
            return table.concat({encoded_by_id['xoco']})
        end
        return ""
    end

    local function NomNomExtraRunPack(packId, displayName)
        displayName = tostring(displayName or packId or "pack")
        if NomNomExtraRuntime.loaded[packId] then
            NomNomExtraNotify(displayName .. " is already marked loaded; use Reset Load Markers before reloading if needed")
            return
        end
        local loader = loadstring or load
        if type(loader) ~= "function" then
            NomNomExtraNotify("No Lua chunk loader is available")
            return
        end
        local encoded = NomNomExtraGetEncoded(packId)
        if encoded == "" then
            NomNomExtraNotify("No encoded payload found for " .. displayName)
            return
        end
        NomNomExtraNotify("Decoding " .. displayName)
        local okDecode, source = pcall(NomNomExtraDecodeBase64, encoded)
        if not okDecode or type(source) ~= "string" or source == "" then
            NomNomExtraNotify("Decode failed for " .. displayName .. ": " .. tostring(source))
            return
        end
        source = NomNomExtraSanitizeSource(source)
        local chunk, err = loader(source, "NomNomExtra::" .. tostring(packId))
        if type(chunk) ~= "function" then
            NomNomExtraNotify("Compile failed for " .. displayName .. ": " .. tostring(err))
            return
        end
        NomNomExtraRuntime.loaded[packId] = true
        task.spawn(function()
            NomNomExtraNotify("Running " .. displayName)
            local okRun, runErr = pcall(chunk)
            if okRun then
                NomNomExtraNotify(displayName .. " finished initial load")
            else
                NomNomExtraRuntime.loaded[packId] = nil
                NomNomExtraNotify(displayName .. " error: " .. tostring(runErr))
            end
        end)
    end

    local NomNomPackLeft = w.NomNomPacks:AddLeftGroupbox("Extra Packs")
    NomNomPackLeft:AddLabel("The Wourld is the active base UI. Load these optional packs manually when needed.")
    NomNomPackLeft:AddButton({{ Text = "Load NoName Pack"; Func = function()
        NomNomExtraRunPack("noname", "NoName Pack")
    end; DoubleClick = false }})
    NomNomPackLeft:AddButton({{ Text = "Load XOCO Pack"; Func = function()
        NomNomExtraRunPack("xoco", "XOCO Pack")
    end; DoubleClick = false }})

    local NomNomPackRight = w.NomNomPacks:AddRightGroupbox("Status / Reload")
    NomNomPackRight:AddButton({{ Text = "Print Pack Status"; Func = function()
{chr(10).join(pack_status_lines)}
        if #NomNomExtraRuntime.status == 0 then
            NomNomExtraNotify("No extra pack status entries yet")
        else
            for index = 1, math.min(#NomNomExtraRuntime.status, 8) do
                print("[NomNom Packs] " .. NomNomExtraRuntime.status[index])
            end
        end
    end; DoubleClick = false }})
    NomNomPackRight:AddButton({{ Text = "Reset Load Markers"; Func = function()
        NomNomExtraRuntime.loaded = {{}}
        NomNomExtraNotify("Load markers reset; pack internals are not force-unloaded")
    end; DoubleClick = false }})
end
'''


def inject_extra_tab(base_source: str) -> str:
    source = sanitize_public_room_source(base_source)
    original_marker = 'UISettings=J:AddTab("UI Settings","settings")}';
    replaced_marker = 'UISettings=J:AddTab("UI Settings","settings"),NomNomPacks=J:AddTab("NomNom Packs","package")}';
    if original_marker not in source:
        raise RuntimeError('Could not find The Wourld tab table marker')
    source = source.replace(original_marker, replaced_marker, 1)
    post_marker = replaced_marker + '_G.ShurikenAntiKick'
    if post_marker not in source:
        raise RuntimeError('Could not find The Wourld post-tab insertion marker')
    source = source.replace(post_marker, replaced_marker + build_extra_loader_lua() + '_G.ShurikenAntiKick', 1)
    header = '''-- NomNom.lua - The Wourld Obsidian-base build for NomNomFTAP-alt.
-- Generated for the alt repository only. The original NomNomFTAP tree is intentionally not touched.
-- The Wourld creates the base Obsidian UI; NoName/XOCO are embedded as lazy base64 chunk arrays.
-- Automatic public-room message behavior is intentionally blocked before extra packs execute.

'''
    return header + source


README = """# NomNom FTAP Alt - The Wourld Obsidian Base

This alt repository contains the generated `NomNom.lua` for the NomNom alt target.

## Architecture

`NomNom.lua` uses `Source/Strong/The Wourld` as the real base script. The Wourld still creates its own Obsidian window, tabs, mechanics, settings, and runtime behavior.

The generator inserts one additional Obsidian tab into The Wourld's tab table:

- `NomNom Packs` - an in-window pack management tab.

Inside that tab, the build adds:

- `Load NoName Pack` - manually decodes and runs the embedded `Source/Strong/NoName` payload.
- `Load XOCO Pack` - manually decodes and runs the embedded `Source/Strong/XOCO` payload.
- `Print Pack Status` - prints the pack summaries and recent loader status messages.
- `Reset Load Markers` - clears the lazy-loader markers so a pack can be attempted again without forcing its internals to unload.

## Lazy payload strategy

`NoName` and `XOCO` are not pasted into The Wourld's top-level scope. They are base64-encoded into chunk arrays and decoded only from the Obsidian button callbacks. This avoids malformed-string fragility and avoids adding large pack bodies to the same top-level local/register scope as The Wourld.

## Public-room message policy

The build does not auto-send public-room startup messages. The visible base source is sanitized for known public-room API identifiers, and decoded extra packs are sanitized immediately before compilation.

## Rebuild

Run `_roo_build_nomnom_alt.py` from this repository or from the workspace root to regenerate `NomNom.lua` and this README from the current `Source/Strong` files.
"""


def main() -> None:
    base = (STRONG / 'The Wourld').read_text(encoding='utf-8', errors='replace')
    nomnom = inject_extra_tab(base)
    (ALT / 'NomNom.lua').write_text(nomnom, encoding='utf-8', newline='\n')
    (ALT / 'README.md').write_text(README, encoding='utf-8', newline='\n')
    print('wrote', ALT / 'NomNom.lua', 'bytes', (ALT / 'NomNom.lua').stat().st_size)
    print('wrote', ALT / 'README.md', 'bytes', (ALT / 'README.md').stat().st_size)


if __name__ == '__main__':
    main()
