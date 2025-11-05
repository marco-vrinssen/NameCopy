-- Adds "Copy Full Name" menu option to player context menus

local finderMenuTags = {
  MENU_LFG_FRAME_SEARCH_ENTRY = true,
  MENU_LFG_FRAME_MEMBER_APPLY = true
}

local playerContextTypes = {
  PLAYER = true,
  PARTY = true,
  RAID_PLAYER = true,
  FRIEND = true,
  BN_FRIEND = true,
  SELF = true,
  OTHER_PLAYER = true,
  ENEMY_PLAYER = true,
  TARGET = true,
  FOCUS = true,
  FRIEND_OFFLINE = true,
  FRIEND_ONLINE = true
}

-- Split full name into player name and realm
local function parseNameRealm(fullName)
  if not fullName then
    return nil, nil
  end
  
  local playerName, realmName = string.match(fullName, "^([^-]+)-(.+)$")
  return playerName or fullName, realmName or GetRealmName()
end

-- Extract player info from group finder frames
local function extractFinderPlayer(frameOwner)
  if not frameOwner then
    return nil, nil
  end

  if frameOwner.resultID and C_LFGList then
    local searchResult = C_LFGList.GetSearchResultInfo(frameOwner.resultID)
    if searchResult and searchResult.leaderName then
      return parseNameRealm(searchResult.leaderName)
    end
  end

  if frameOwner.memberIdx then
    local parentFrame = frameOwner:GetParent()
    if parentFrame and parentFrame.applicantID and C_LFGList then
      local applicantName = C_LFGList.GetApplicantMemberInfo(parentFrame.applicantID, frameOwner.memberIdx)
      if applicantName then
        return parseNameRealm(applicantName)
      end
    end
  end

  return nil, nil
end

-- Extract player info from BattleNet account
local function extractBattleNetPlayer(battleNetInfo)
  if battleNetInfo and battleNetInfo.gameAccountInfo then
    local gameAccount = battleNetInfo.gameAccountInfo
    return gameAccount.characterName, gameAccount.realmName
  end
  return nil, nil
end

-- Resolve player name and realm from context
local function resolvePlayer(frameOwner, menuRoot, menuContext)
  if not menuContext then
    if menuRoot and menuRoot.tag and finderMenuTags[menuRoot.tag] then
      return extractFinderPlayer(frameOwner)
    end
    return nil, nil
  end

  if menuContext.name and menuContext.server then
    return menuContext.name, menuContext.server
  end

  if menuContext.unit and UnitExists(menuContext.unit) then
    local unitName = UnitName(menuContext.unit)
    if unitName then
      local playerName, realmName = parseNameRealm(unitName)
      return playerName, menuContext.server or realmName
    end
  end

  if menuContext.accountInfo then
    local playerName, realmName = extractBattleNetPlayer(menuContext.accountInfo)
    if playerName and realmName then
      return playerName, realmName
    end
  end

  if menuContext.name then
    return parseNameRealm(menuContext.name)
  end

  if menuContext.friendsList and C_FriendList then
    local friendInfo = C_FriendList.GetFriendInfoByIndex(menuContext.friendsList)
    if friendInfo and friendInfo.name then
      return parseNameRealm(friendInfo.name)
    end
  end

  if menuContext.chatTarget then
    return parseNameRealm(menuContext.chatTarget)
  end

  if menuContext.lineID and menuContext.chatFrame then
    local messageInfo = menuContext.chatFrame:GetMessageInfo(menuContext.lineID)
    if messageInfo and messageInfo.sender then
      return parseNameRealm(messageInfo.sender)
    end
  end

  return nil, nil
end

-- Check if menu context allows copy option
local function validateContext(menuRoot, menuContext)
  if not menuContext then
    return menuRoot and menuRoot.tag and finderMenuTags[menuRoot.tag]
  end
  return menuContext.which and playerContextTypes[menuContext.which]
end

-- Show dialog with copyable player name
local function showCopyDialog(playerName)
  local dialog = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
  dialog:SetSize(500, 150)
  dialog:SetPoint("CENTER")
  dialog:SetMovable(true)
  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", dialog.StartMoving)
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
  dialog:SetFrameStrata("DIALOG")
  dialog:SetFrameLevel(100)

  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dialog.title:SetPoint("TOP", dialog.TitleBg, "TOP", 0, -5)
  dialog.title:SetText("Copy Full Name")

  local editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
  editBox:SetSize(460, 30)
  editBox:SetPoint("CENTER", dialog, "CENTER", 0, 10)
  editBox:SetText(playerName or "")
  editBox:SetAutoFocus(true)
  editBox:HighlightText()
  editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
  editBox:SetScript("OnEnterPressed", function() dialog:Hide() end)
  editBox:SetScript("OnKeyDown", function(_, key)
    if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
      editBox:HighlightText()
      editBox:SetFocus()
      C_Timer.After(0, function()
        if dialog:IsShown() then
          dialog:Hide()
        end
      end)
    end
  end)
  editBox:EnableKeyboard(true)
  editBox:SetScript("OnShow", function(self) self:SetFocus() end)

  local helpText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  helpText:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 20)
  helpText:SetText("Press Ctrl+C (Cmd+C on macOS) to copy the name.")

  dialog:Show()
end

-- Add copy menu button to context menu
local function addCopyButton(frameOwner, menuRoot, menuContext)
  if InCombatLockdown() then
    return
  end
  
  if not validateContext(menuRoot, menuContext) then
    return
  end

  local playerName, realmName = resolvePlayer(frameOwner, menuRoot, menuContext)
  if not (playerName and realmName) then
    return
  end

  if not menuRoot or not menuRoot.CreateButton then
    return
  end
  
  if menuRoot.CreateDivider then
    menuRoot:CreateDivider()
  end
  
  menuRoot:CreateButton("Copy Full Name", function()
    if not InCombatLockdown() then
      showCopyDialog(string.format("%s-%s", playerName, realmName))
    end
  end)
end

-- Menu tags for player context menus
local menuTags = {
  "MENU_LFG_FRAME_SEARCH_ENTRY",
  "MENU_LFG_FRAME_MEMBER_APPLY",
  "MENU_UNIT_PLAYER",
  "MENU_UNIT_PARTY",
  "MENU_UNIT_RAID_PLAYER",
  "MENU_UNIT_FRIEND",
  "MENU_UNIT_BN_FRIEND",
  "MENU_UNIT_SELF",
  "MENU_UNIT_OTHER_PLAYER",
  "MENU_UNIT_ENEMY_PLAYER",
  "MENU_UNIT_TARGET",
  "MENU_UNIT_FOCUS",
  "MENU_UNIT_FRIEND_OFFLINE",
  "MENU_UNIT_FRIEND_ONLINE",
  "MENU_CHAT_LOG_LINK",
  "MENU_CHAT_LOG_FRAME"
}

-- Register menu hooks
local function registerMenus()
  if not Menu or not Menu.ModifyMenu then
    return false
  end
  
  for _, tag in ipairs(menuTags) do
    Menu.ModifyMenu(tag, addCopyButton)
  end
  
  return true
end

-- Register menus with retry if API not ready
if not registerMenus() then
  local attempts = 0
  C_Timer.NewTicker(0.5, function(ticker)
    attempts = attempts + 1
    if registerMenus() or attempts >= 10 then
      ticker:Cancel()
    end
  end)
end
