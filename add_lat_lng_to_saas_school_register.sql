-- SQL script to add latitude and longitude columns to saas_school_register table
-- Run this SQL script in your database management tool (e.g., phpMyAdmin)

ALTER TABLE `saas_school_register` ADD `latitude` DECIMAL(10,8) NULL DEFAULT NULL AFTER `address`;
ALTER TABLE `saas_school_register` ADD `longitude` DECIMAL(11,8) NULL DEFAULT NULL AFTER `latitude`;

-- Verify the columns were added
DESCRIBE `saas_school_register`;