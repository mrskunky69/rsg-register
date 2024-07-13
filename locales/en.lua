local Translations = {

    client = {
        lang_1 = 'Reached Maximum Allowed!',
        lang_2 = 'Can\'t place that here!',
        lang_3 = 'You are currently busy!',
        lang_4 = ' Market Stall',
        lang_5 = 'View Store Items',
        lang_6 = 'Add/Update Stock Item',
        lang_7 = 'Remove Stock Item',
        lang_8 = 'Withdraw Money',
        lang_9 = 'Store Maintenance',
        lang_10 = 'Packup Store',
        lang_11 = 'Store Customer Menu',
        lang_12 = 'View Shop Items',
        lang_13 = 'Store Stock',
        lang_14 = 'Nothing For Sale!',
        lang_15 = 'stock amount : ',
        lang_16 = 'Store Stock',
        lang_17 = 'Buy ',
        lang_18 = 'Amount',
        lang_19 = 'Not enough items in stock!',
        lang_20 = 'Add/Update Stock',
        lang_21 = 'Sell',
        lang_22 = 'Amount',
        lang_23 = 'Sale Price',
        lang_24 = 'You don\'t have that much!',
        lang_25 = 'Market Stock',
        lang_26 = 'No Stock!',
        lang_27 = 'stock amount : ',
        lang_28 = 'Store Stock',
        lang_29 = 'Withdraw Money',
        lang_30 = 'Current Funds: $',
        lang_31 = 'Not enough funds!',
        lang_32 = 'store Maintenance',
        lang_33 = 'Condition (',
        lang_34 = '%)',
        lang_35 = 'Repair store ($',
        lang_36 = ')',
        lang_37 = 'Confirm Action',
        lang_38 = 'Do you want to continue?',
        lang_39 = '⛔️ have you removed all stock and cash!',
        lang_40 = 'Yes',
        lang_41 = 'No',
        lang_42 = 'Packing up Store',
        lang_43 = 'repair costs will be $',
        lang_44 = 'Repairing Store',
		lang_45 = 'closeshop',
		['server.not_shopkeeper'] = 'You need to be a shopkeeper to use this item.',
		['client.not_shopkeeper'] = 'You need to be a shopkeeper to place a register.',
    },

    server = {
        lang_1 = 'loading ',
        lang_2 = ' prop with ID: ',
        lang_3 = 'Not enough ',
        lang_4 = 'Store Lost',
        lang_5 = 'Store with ID:',
        lang_6 = 'belonging to ',
        lang_7 = 'was lost due to non maintanance!',
        lang_8 = 'update complete',
        lang_9 = 'stock update complete',
    },

    config = {
        lang_1 = 'add here',
    },

}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

-- Lang:t('client.lang_1')
-- Lang:t('server.lang_1')
-- Lang:t('config.lang_1')
