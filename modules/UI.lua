-- modules/UI.lua - Obsidian window, tabs, and group helper.

local UI = {}

function UI.init(ctx)
    local Library = ctx.Library
    local runtime = ctx.runtime
    local Window = Library:CreateWindow({
        Title = "NomNom FTAP Alt • Wourld Unified",
        Footer = "The Wourld UI + NoName/XOCO features • no packs",
        ToggleKeybind = Enum.KeyCode.RightControl,
        Center = true,
        AutoShow = true,
    })
    runtime.Window = Window

    local Tabs = {
        Home = Window:AddTab("Home", "house"),
        Protection = Window:AddTab("Protection / Gucci", "shield"),
        Combat = Window:AddTab("Combat / Grab", "swords"),
        Player = Window:AddTab("Player", "user"),
        Visuals = Window:AddTab("Visuals", "eye"),
        Toys = Window:AddTab("Toys / Utility", "package"),
        Teleports = Window:AddTab("Teleports / Map", "map"),
        Settings = Window:AddTab("Settings", "settings"),
    }

    local function group(tab, name, side)
        if side == "left" and type(tab.AddLeftGroupbox) == "function" then
            return tab:AddLeftGroupbox(name)
        end
        if side ~= "left" and type(tab.AddRightGroupbox) == "function" then
            return tab:AddRightGroupbox(name)
        end
        return tab:AddGroupbox(name)
    end
    ctx.Window = Window
    ctx.Tabs = Tabs
    ctx.group = group
    ctx.runtime.Window = Window
    return Window, Tabs
end

return UI

