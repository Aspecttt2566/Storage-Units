CREATE TABLE IF NOT EXISTS `_storageunits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `passcode` longtext NOT NULL,
  `access` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;