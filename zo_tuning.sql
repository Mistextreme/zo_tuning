-- zo_tuning.sql
-- Run this once on your ESX database before starting the resource.
-- Creates the table used to persist vehicle tuning data,
-- replacing the original vRP SData (key-value) storage.

CREATE TABLE IF NOT EXISTS `zo_tuning_data` (
    `id`          INT          NOT NULL AUTO_INCREMENT,
    `data_key`    VARCHAR(255) NOT NULL,
    `data_value`  LONGTEXT     NOT NULL,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_data_key` (`data_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;