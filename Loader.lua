-- Loader.lua - single entrypoint for NomNomFTAP-alt modular build.
-- Executor-compatible strategy: loads module source from GitHub raw URLs with loadstring/HttpGet.
-- Keep NomNom.lua as a convenience wrapper pointing here.

(function()
    local BASE_URL = "https://raw.githubusercontent.com/NomNomNemNie/NomNomFTAP-alt/main/"
    local ORDER = {
        "modules/Core.lua",
        "modules/UI.lua",
        "modules/Gucci.lua",
        "modules/Combat.lua",
        "modules/Protection.lua",
        "modules/Movement.lua",
        "modules/Visuals.lua",
        "modules/Toys.lua",
        "modules/Teleports.lua",
        "modules/Settings.lua",
    }

    local loaded = {}

    local function fetch(path)
        local url = BASE_URL .. path
        local ok, source = pcall(function()
            return game:HttpGet(url, true)
        end)
        if not ok or type(source) ~= "string" or source == "" then
            error("NomNom loader failed to fetch " .. path, 2)
        end
        local chunk, compileError = loadstring(source, "NomNomFTAP-alt/" .. path)
        if not chunk then
            error("NomNom loader failed to compile " .. path .. ": " .. tostring(compileError), 2)
        end
        local okRun, moduleOrError = pcall(chunk)
        if not okRun then
            error("NomNom loader failed to run " .. path .. ": " .. tostring(moduleOrError), 2)
        end
        return moduleOrError
    end

    for _, path in ipairs(ORDER) do
        loaded[path] = fetch(path)
    end

    local ctx = loaded["modules/Core.lua"].init()
    if not ctx then
        return
    end

    loaded["modules/UI.lua"].init(ctx)

    for _, path in ipairs({
        "modules/Gucci.lua",
        "modules/Combat.lua",
        "modules/Protection.lua",
        "modules/Movement.lua",
        "modules/Visuals.lua",
        "modules/Toys.lua",
        "modules/Teleports.lua",
        "modules/Settings.lua",
    }) do
        local module = loaded[path]
        if type(module) == "table" and type(module.register) == "function" then
            module.register(ctx)
        end
    end
end)()
