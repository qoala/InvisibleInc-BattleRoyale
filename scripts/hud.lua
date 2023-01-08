local cdefs = include("client_defs")
local hud = include("hud/hud")

local function findBackstabDaemonIndex(self)
    local daemons = self._game.simCore:getNPC():getAbilities()
    if daemons then
        for i, daemon in ipairs(daemons) do
            if daemon:getID() == "backstab_royaleFlush" then
                return i
            end
            if i >= 11 then
                break
            end -- Go no further than 11 (max rows in Scrolling Daemons mod)
        end
    end
    return 1
end

local function showBackstabWarning(self, txt, color, programIcon, sound)
    local warning = self._screen.binder.backstabWarning
    if warning.isnull then
        simlog("[BACKSTAB] Cannot display backstab warning without screen inserts available.")
        return
    end

    self._backstab_warningTimer = 3 * cdefs.SECONDS
    if sound then
        MOAIFmodDesigner.playSound(sound)
    end

    -- Position the warning next to the Royale Flush daemon.
    local idx = findBackstabDaemonIndex(self)
    warning:setPosition(nil, -42 - 60 * (idx - 1))
    if self._mainframe_panel.daemonHandler and self._mainframe_panel.daemonHandler.scrollItems then
        -- If Scrolling Daemons mod is present, force scroll to the beginning of the list.
        self._mainframe_panel.daemonHandler:scrollItems(0)
    end

    local warningTxt = warning.binder.warningTxtCenter
    warning:setVisible(true)
    warningTxt:spoolText(txt)

    if color then
        warning.binder.warningBG:setColor(color.r, color.g, color.b, color.a)
        warningTxt:setColor(color.r, color.g, color.b, color.a)
    else
        warning.binder.warningBG:setColor(184 / 255, 13 / 255, 13 / 255, 1)
        warningTxt:setColor(184 / 255, 13 / 255, 13 / 255, 1)
    end
    warning.binder.warningBG:setVisible(true)

    local programImg = warning.binder.programGroup.binder.program
    if programIcon then
        programImg:setVisible(true)
        programImg:setImage(programIcon)
    else
        programImg:setVisible(false)
    end

    if not warning:hasTransition() then
        warning:createTransition("backstab_activate_right")
    end
end

local function updateBackstabWarning(self)
    if self._backstab_warningTimer then
        self._backstab_warningTimer = self._backstab_warningTimer - 1
        if self._backstab_warningTimer <= 0 then
            self._backstab_warningTimer = nil

            local warning = self._screen.binder.backstabWarning
            warning:createTransition(
                    "deactivate_right", function(transition)
                        warning:setVisible(false)
                    end, {easeOut = true})
        end
    end
end

local oldCreateHud = hud.createHud
hud.createHud = function(...)
    local hudObject = oldCreateHud(...)

    hudObject.showBackstabWarning = showBackstabWarning

    local oldUpdateHud = hudObject.updateHud
    function hudObject:updateHud(...)
        oldUpdateHud(self, ...)
        updateBackstabWarning(self)
    end

    return hudObject
end
