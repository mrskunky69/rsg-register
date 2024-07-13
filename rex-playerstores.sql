CREATE TABLE `player_stores` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `owner` varchar(50) DEFAULT NULL,
    `properties` text NOT NULL,
    `marketid` int(11) NOT NULL,
    `item` varchar(50) DEFAULT NULL,
    `quality` int(3) NOT NULL DEFAULT 100,
    `money` double(11,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `player_market_store` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `marketid` varchar(50) DEFAULT NULL,
    `item` varchar(50) DEFAULT NULL,
    `stock` int(11) NOT NULL DEFAULT 0,
    `price` double(11,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
