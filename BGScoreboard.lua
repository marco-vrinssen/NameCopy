-- Adds "Player Names" button to PVP scoreboard for copying all player names

local namesDialog = nil

-- Show or toggle player names dialog
local function showPlayerNamesDialog(playerNames)
  if namesDialog and namesDialog:IsShown() then
    namesDialog:Hide()
    return
  end

  if namesDialog then
    local namesText = table.concat(playerNames, "\n")
    namesDialog.input:SetText(namesText)
    namesDialog.input:SetCursorPosition(0)
    namesDialog:Show()
    return
  end

  local dialog = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
  dialog:SetSize(500, 400)
  dialog:SetPoint("CENTER")
  dialog:SetMovable(true)
  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", dialog.StartMoving)
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(1000)

  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dialog.title:SetPoint("TOP", dialog.TitleBg, "TOP", 0, -5)
  dialog.title:SetText("Player Names")

  local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 50)

  local input = CreateFrame("EditBox", nil, scrollFrame)
  input:SetMultiLine(true)
  input:SetMaxLetters(0)
  input:SetFontObject(GameFontHighlight)
  input:SetWidth(scrollFrame:GetWidth() - 20)
  input:SetHeight(5000)
  input:SetAutoFocus(false)
  input:SetScript("OnEscapePressed", function() dialog:Hide() end)

  scrollFrame:SetScrollChild(input)
  
  local namesText = table.concat(playerNames, "\n")
  input:SetText(namesText)
  input:SetCursorPosition(0)

  local helpText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  helpText:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
  helpText:SetText("Press Ctrl+C (Cmd+C on macOS) to copy the names.")

  dialog.input = input
  namesDialog = dialog
  dialog:Show()
end

-- Extract player names from scoreboard content
local function extractPlayerNames(contentFrame, callback)
  if not contentFrame then
    callback({})
    return
  end

  local playerNames = {}
  local foundNames = {}
  local ignoreTexts = {
    ["Name"] = true,
    ["Deaths"] = true,
    ["All"] = true,
    ["Progress"] = true
  }

  -- Get ScrollBox.ScrollTarget path
  local scrollBox = contentFrame.scrollBox or contentFrame.ScrollBox
  if not scrollBox then
    callback({})
    return
  end

  local scrollTarget = scrollBox.ScrollTarget
  if not scrollTarget then
    callback({})
    return
  end

  -- Search children of ScrollTarget
  local children = {scrollTarget:GetChildren()}
  
  for _, child in ipairs(children) do
    if child then
      local grandchildren = {child:GetChildren()}
      for _, grandchild in ipairs(grandchildren) do
        if grandchild and grandchild.text then
          local textObj = grandchild.text
          if textObj and type(textObj) == "table" and textObj.GetText then
            local text = textObj:GetText()
            
            if text and text ~= "" and not ignoreTexts[text] and not foundNames[text] then
              -- Reject text that contains any numbers
              local hasNumber = text:match("%d")
              
              if not hasNumber then
                foundNames[text] = true
                table.insert(playerNames, text)
              end
            end
          end
        end
      end
    end
  end

  callback(playerNames)
end

-- Create player names button
local function createPlayerNamesButton(parentFrame)
  if not parentFrame or parentFrame.bentoNamesButton then
    return
  end

  local contentFrame = parentFrame.Content or parentFrame.content
  if not contentFrame then
    return
  end

  local button = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
  button:SetSize(120, 25)
  button:SetText("Player Names")
  button:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -10, 10)
  
  button:SetScript("OnClick", function()
    if InCombatLockdown() then
      return
    end

    C_Timer.After(0.2, function()
      extractPlayerNames(contentFrame, function(playerNames)
        if #playerNames > 0 then
          showPlayerNamesDialog(playerNames)
        end
      end)
    end)
  end)

  parentFrame.bentoNamesButton = button
end

-- Setup buttons on scoreboard frames
local function setupButtons()
  if PVPMatchScoreboard then
    createPlayerNamesButton(PVPMatchScoreboard)
  end
  
  if PVPMatchResults then
    createPlayerNamesButton(PVPMatchResults)
  end
end

-- Initialize on PVPUI load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, addonName)
  if addonName == "Blizzard_PVPUI" then
    setupButtons()
    
    if PVPMatchScoreboard then
      PVPMatchScoreboard:HookScript("OnShow", function()
        if not PVPMatchScoreboard.bentoNamesButton then
          createPlayerNamesButton(PVPMatchScoreboard)
        end
      end)
    end
    
    if PVPMatchResults then
      PVPMatchResults:HookScript("OnShow", function()
        if not PVPMatchResults.bentoNamesButton then
          createPlayerNamesButton(PVPMatchResults)
        end
      end)
    end
    
    eventFrame:UnregisterEvent("ADDON_LOADED")
  end
end)

setupButtons()
