Config = {}
Config.PlayerProps = {}
PropsLoaded = false

---------------------------------------------
-- blip settings
---------------------------------------------
Config.Blip = {
    blipName = 'store',
    blipSprite = 'blip_shop_market_stall',
    blipScale = 0.2,
    blipColour = 'BLIP_MODIFIER_MP_COLOR_6'
}

---------------------------------------------
-- deploy prop settings
---------------------------------------------
Config.ForwardDistance   = 1.0
Config.PromptGroupName   = 'Place store'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Set'
Config.PromptRotateLeft  = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'
Config.PromptMoveBackward = 'back'
Config.PromptMoveForward = 'forward'
Config.PromptMoveDown = 'down'
Config.PromptMoveUp = 'up'

---------------------------------------------
-- settings
---------------------------------------------
Config.UseProp = `p_register06x`
Config.MaxStalls  = 10
Config.PlaceMinDistance = 2
Config.Img = "rsg-inventory/html/images/"
Config.Money = 'cash' -- 'cash' or 'bloodmoney'
Config.PackupTime = 5000
Config.RepairCost = 1
Config.EnableServerNotify = true
Config.SpawnDistance = 150.0

---------------------------------------------
-- cronjob settings
---------------------------------------------
Config.UpkeepCronJob = '0 0 * * *'  -- Runs at midnight every day
Config.StockCronJob = '*/1 * * * *' -- cronjob time 5 mins