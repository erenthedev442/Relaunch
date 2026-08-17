-----------------------------------
-- Attachment: Damage Gauge II
-- Prioritizes healing at 60 / 70 / 80 / 90 percent and reduces the
-- healing decision cooldown by three seconds.
-----------------------------------
---@type TAttachment
local attachmentObject = {}

local function updateAllAttachments(pet)
    local master = pet and pet:getMaster()

    if master then
        master:updateAttachments()
    end
end

attachmentObject.onEquip = function(pet, attachment)
    xi.automaton.onAttachmentEquip(pet, attachment)
    updateAllAttachments(pet)
end

attachmentObject.onUnequip = function(pet, attachment)
    xi.automaton.onAttachmentUnequip(pet, attachment)
end

attachmentObject.onManeuverGain = function(pet, attachment, maneuvers)
    xi.automaton.onManeuverGain(pet, attachment, maneuvers)
end

attachmentObject.onManeuverLose = function(pet, attachment, maneuvers)
    xi.automaton.onManeuverLose(pet, attachment, maneuvers)
end

attachmentObject.onUpdate = function(pet, attachment, maneuvers)
    xi.automaton.updateAttachmentModifier(pet, attachment, maneuvers)
end

return attachmentObject
