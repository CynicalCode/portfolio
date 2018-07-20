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

function Portfolio:OnInitialize()
    -- initialize database
    self.db = LibStub("AceDB-3.0"):New("PortfolioDB")

    -- configure and register addon options
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Portfolio", options, {"myslash", "myslashtwo"})
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Portfolio")

    -- event registrations
    Portfolio:RegisterEvent("BANKFRAME_OPENED", "onBankFrameOpened")
    
    self.myMessageVar = 'wooteng'
    
    Portfolio:Print("Portfolio loaded.")
end

function Portfolio:OnEnable()
    Portfolio:Print("Portfolio enabled.")
end

function Portfolio:OnDisable()
    Portfolio:Print("Portfolio disabled.")
end

function Portfolio:GetMyMessage(info)
    return self.myMessageVar
end

function Portfolio:onBankFrameOpened()
    Portfolio:Print("Parsing character inventory and bank data...")
    self.db.char.inventory = {}
    for i=-1,NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
        containerSize = GetContainerNumSlots(i)
        self.db.char.inventory[i] = {}
        for j=1,containerSize do
            itemID = GetContainerItemID(i,j)
            self.db.char.money = GetMoney()
            self.db.char.inventory[i][j] = itemID
        end
    end

    Portfolio:Print("Inventory and bank data saved.")
end

function Portfolio:SetMyMessage(info, input)
    self.myMessageVar = input
end