-- Opens popup to copy all player names from scoreboard

local function parseNameRealm(fullName)
  if not fullName then
    return nil
  end
  
  local playerName, realmName = string.match(fullName, "^([^-]+)-(.+)$")
  if playerName and realmName then
    return string.format("%s-%s", playerName, realmName)
  end
  
  return fullName
end

local function getAllScoreboardNames()
  if not C_PvP or not C_PvP.GetScoreInfo then
    return {}
  end
  
  local names = {}
  local scoreInfo = C_PvP.GetScoreInfo()
  
  if not scoreInfo then
    return names
  end
  
  for i = 1, #scoreInfo do
    local info = scoreInfo[i]
    if info and info.name then
      local fullName = parseNameRealm(info.name)
      if fullName then
        table.insert(names, fullName)
      end
    end
  end
  
  return names
end

local function showScoreboardCopyDialog()
  local names = getAllScoreboardNames()
  
  if #names == 0 then
    return
  end
  
  local namesList = table.concat(names, "\n")
  
  local dialog = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
  dialog:SetSize(500, 400)
  dialog:SetPoint("CENTER")
  dialog:SetMovable(true)
  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", dialog.StartMoving)
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
  dialog:SetFrameStrata("TOOLTIP")
  dialog:SetFrameLevel(9999)

  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dialog.title:SetPoint("TOP", dialog.TitleBg, "TOP", 0, -5)
  dialog.title:SetText("Copy Scoreboard Names")

  local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 50)

  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(true)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetText(namesList)
  editBox:HighlightText()
  editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
  editBox:SetScript("OnKeyDown", function(_, key)
    if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
      editBox:HighlightText()
      editBox:SetFocus()
      C_Timer.After(0.1, function()
        if dialog:IsShown() then
          dialog:Hide()
        end
      end)
    end
  end)
  editBox:EnableKeyboard(true)
  editBox:SetScript("OnShow", function(self) self:SetFocus() end)

  scrollFrame:SetScrollChild(editBox)

  local helpText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  helpText:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
  helpText:SetText(string.format("Press Ctrl+C (Cmd+C on macOS) to copy all %d names.", #names))

  dialog:Show()
end

SLASH_COPYNAMES1 = "/copynames"
SLASH_COPYNAMES2 = "/cn"
SlashCmdList["COPYNAMES"] = function()
  showScoreboardCopyDialog()
end
