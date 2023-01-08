local function showBackstabWarning(ev, eventType, eventData, boardRig, hud, thread)
    hud:showBackstabWarning(eventData.txt, eventData.color, eventData.icon, eventData.sound)
end

return showBackstabWarning
