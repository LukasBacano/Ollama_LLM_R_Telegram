CREATE DATABASE telegram_messages;

CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for each log entry
    first_name VARCHAR(255),           -- User's first name
    last_name VARCHAR(255),            -- User's last name
    username VARCHAR(255),             -- Telegram username
    user_id BIGINT,                    -- Telegram user ID
    message TEXT,                      -- User's message to the bot
    response TEXT,                     -- Bot's response to the user
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp of the interaction
);

ALTER TABLE logs ADD COLUMN country_code VARCHAR(20);  -- Add a column for phone numbers



SELECT * FROM logs;	