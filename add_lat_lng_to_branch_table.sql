-- SQL script to add latitude and longitude columns to branch table
-- Run this SQL script in your database management tool (e.g., phpMyAdmin)

ALTER TABLE `branch` ADD `latitude` DECIMAL(10,8) NULL DEFAULT NULL AFTER `address`;
ALTER TABLE `branch` ADD `longitude` DECIMAL(11,8) NULL DEFAULT NULL AFTER `latitude`;

-- Verify the columns were added
DESCRIBE `branch`;