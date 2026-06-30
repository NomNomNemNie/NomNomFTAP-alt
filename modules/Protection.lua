-- modules/Protection.lua - compatibility alias for protection controls.
-- Protection UI is registered by Gucci.lua to keep Gucci/protection state in one module.

local Protection = {}
function Protection.register(ctx)
    return ctx
end
return Protection
