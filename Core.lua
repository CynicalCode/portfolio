Portfolio = LibStub("AceAddon-3.0"):NewAddon("Portfolio", "AceConsole-3.0", "AceEvent-3.0")

local options = {
    name = "Portfolio",
    handler = Portfolio,
    type = 'group',
    args = {
        msg = {
            type = 'input',
            name = 'My Message',
            desc = 'The message for my addon',
            set = 'SetMyMessage',
            get = 'GetMyMessage',
        },
    },
}

function Portfolio:SetMyMessage(info, input)
    self.myMessageVar = input
end

function Portfolio:GetMyMessage(info)
    return self.myMessageVar
end

local dbDefaults = {
    global = {
        inventory = {},
        info = {},
        currencies = {},
        money = {},
        lastUpdate = {},
    }
}

local realmKey = GetRealmName()
local charKey = UnitName("player") .. " - " .. realmKey

function Portfolio:OnInitialize()
    -- initialize database
    self.db = LibStub("AceDB-3.0"):New("PortfolioDB", dbDefaults)

    -- configure and register addon options
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Portfolio", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Portfolio")

    -- event registrations
    Portfolio:RegisterEvent("BANKFRAME_OPENED", "onBankFrameOpened")
    Portfolio:RegisterEvent("TIME_PLAYED_MSG", "onTimePlayedReceived")

    self:RegisterChatCommand("pf", "search")
    
    Portfolio:Print("Portfolio loaded.")
end

function Portfolio:search(query)
    resultList = {}
    for characterName,inventory in pairs(self.db.global.inventory) do
        for bagIndex, bagContents in pairs(inventory) do
            for slotIndex, itemInfo in pairs(bagContents) do
                match = string.match(itemInfo.name:lower(), query:lower())
                --Portfolio:Printf("match=%s", match)
                if match then
                    result = {
                        character = characterName,
                        name = itemInfo.name,
                        id = itemInfo.id,
                        link = itemInfo.link,
                        count = itemInfo.count,
                    }
                    table.insert(resultList, result)
                end
            end
        end
    end

    Portfolio:Printf("found %d hits:", table.getn(resultList))
    for i=1,table.getn(resultList) do
        Portfolio:Printf("(%s) %s (x %d)", resultList[i].character, resultList[i].link, resultList[i].count)
    end
end

function Portfolio:OnEnable()
    Portfolio:Print("Portfolio enabled.")
    Portfolio:Print("Parsing character data...")
    Portfolio:parsePlayerInformation()
    Portfolio:parseContainers(0, NUM_BAG_SLOTS)
    Portfolio:parseCurrencies()
    RequestTimePlayed()
    Portfolio:Print("Character data saved.")
end

function Portfolio:OnDisable()
    Portfolio:Print("Portfolio disabled.")
end

function Portfolio:onBankFrameOpened()
    Portfolio:Print("Parsing character inventory and bank data...")

    -- clear inventory as we're able to build a full map here.
    self.db.global.inventory[charKey] = {}
    -- parse bank (-1), equipped bags (0 to NUM_BAG_SLOTS) and bank bag
    -- slots (NUM_BAG_SLOTS+1 to NUM_BANKBAGSLOTS)
    Portfolio:parseContainers(-1,NUM_BAG_SLOTS+NUM_BANKBAGSLOTS)
    self.db.global.lastUpdate[charKey] = time()

    Portfolio:Print("Inventory and bank data saved.")
end

function Portfolio:parsePlayerInformation()
    local total, equipped, pvp = GetAverageItemLevel()

    playerInfo = {
        level = UnitLevel("player"),
        class = UnitClass("player"),
        race = UnitRace("player"),
        faction = UnitFactionGroup("player"),
        itemLevel = {
            total = total,
            equipped = equipped,
            pvp = pvp,
        },
    }

    self.db.global.info[charKey] = playerInfo
    self.db.global.lastUpdate[charKey] = time()
end

function Portfolio:onTimePlayedReceived(event, totalTime, levelTime)
    self.db.global.info[charKey].played = {
        total = totalTime,
        currentLevel = levelTime,
    }

    self.db.global.lastUpdate[charKey] = time()
end

function Portfolio:parseContainers(startIndex, endIndex)
    if self.db.global.inventory[charKey] == nil then
        self.db.global.inventory[charKey] = {}
    end
    
    for i=startIndex,endIndex do
        containerSize = GetContainerNumSlots(i)
        self.db.global.inventory[charKey][i] = {}
        for j=1,containerSize do
            _, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(i,j)
            if itemID ~= nil then
                name, link = GetItemInfo(itemID)
                self.db.global.inventory[charKey][i][j] = {
                    id = itemID,
                    name = name,
                    count = count,
                    link = link,
                }
            end
        end
    end
    self.db.global.lastUpdate[charKey] = time()
end

function Portfolio:parseCurrencies()
    self.db.global.currencies[charKey] = {
        money = GetMoney(),
    }
    
    numCurrencies = GetCurrencyListSize()
    currentHeader = nil
    for i=1,numCurrencies do
        name, isHeader, _, _, _, count, icon, maximum, hasWeeklyLimit, currentWeeklyAmount = GetCurrencyListInfo(i)
        if isHeader then
            currentHeader = name
            self.db.global.currencies[charKey][currentHeader] = {}
        elseif currentHeader ~= nil then
            self.db.global.currencies[charKey][currentHeader][name] = {}
            self.db.global.currencies[charKey][currentHeader][name].icon = icon
            self.db.global.currencies[charKey][currentHeader][name].count = count
            self.db.global.currencies[charKey][currentHeader][name].maximum = maximum
        end
    end
end
