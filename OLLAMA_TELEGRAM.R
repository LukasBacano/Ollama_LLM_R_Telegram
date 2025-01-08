library(httr)
library(jsonlite)
library(ollamar)
library(DBI)
library(RMariaDB)  # For MySQL/MariaDB database connection

# Telegram bot token
telegram_token <- "YOUR_TOKEN"

# Database connection settings
db <- dbConnect(
  MariaDB(),
  user = "YOUR_USERNAME",         # Your database username
  password = "YOUR_PASSWORD",     # Your database password
  dbname = "DB_NAME",       # The name of your database
  host = "YOUR_HOST_ADDRESS"              # Database host (local or server IP)
)

# Initialize last_update_id
last_update_id <- NULL

# Function to generate response from Ollama
generate_ollama_response <- function(message) {
  tryCatch({
    # Send message to Ollama model
    resp <- generate("llama3.2", message)  # Ensure the model name is correct  (dolphin-llama3  - for uncensured version)
    ans <- rbind(resp_process(resp, "df"))
    
    # Return the processed response
    return(ans$response[1])  # Assuming 'response' column contains the response
  }, error = function(e) {
    cat("Error generating response from Ollama:", e$message, "\n")
    return("Der skete en fejl, mens jeg prøvede at svare. Prøv igen senere.")
  })
}

# Function to log messages to SQL database
log_message_to_db <- function(first_name, last_name, username, user_id, user_message, ollama_response) {
  # SQL INSERT query
  query <- "INSERT INTO logs (first_name, last_name, username, user_id, message, response, timestamp) 
            VALUES (?, ?, ?, ?, ?, ?, ?)"
  
  tryCatch({
    # Execute the query with parameters
    dbExecute(db, query, params = list(
      first_name, last_name, username, user_id, user_message, ollama_response, Sys.time()
    ))
    cat("Message logged to database successfully.\n")
  }, error = function(e) {
    cat("Error logging message to database:", e$message, "\n")
  })
}

# Main loop
while (TRUE) {
  # Fetch updates from Telegram bot using the last_update_id as offset
  response <- GET(paste0(
    "https://api.telegram.org/bot", telegram_token, "/getUpdates",
    if (!is.null(last_update_id)) paste0("?offset=", last_update_id + 1) else ""
  ))
  
  # Check if request was successful
  if (status_code(response) != 200) {
    cat("Kunne ikke hente opdateringer. Tjek bot-token og internetforbindelse.\n")
    Sys.sleep(5)
    next
  }
  
  # Parse response
  updates <- fromJSON(content(response, "text", encoding = "UTF-8"))
  
  # Check if there are updates
  if (!is.null(updates$result) && length(updates$result) > 0) {  # Use length() to check if result exists and is not empty
    # Iterate through rows of the data frame
    for (i in seq_len(nrow(updates$result))) {
      # Extract update data
      update_id <- updates$result$update_id[i]
      message_data <- updates$result$message[i, ]
      
      # Skip if already processed
      if (!is.null(last_update_id) && update_id <= last_update_id) {
        next
      }
      
      # Update last_update_id
      last_update_id <- update_id
      
      # Extract message details
      user_message <- message_data$text
      chat <- message_data$chat
      first_name <- chat$first_name
      last_name <- ifelse("last_name" %in% names(chat), chat$last_name, "")
      username <- ifelse("username" %in% names(chat), chat$username, "")
      user_id <- chat$id
      
      # Debugging: Print received message
      cat("Modtaget besked fra:", username, "(", first_name, last_name, "):", user_message, "\n")
      
      # Generate response using Ollama
      ollama_response <- generate_ollama_response(user_message)
      
      # Log message to SQL database
      log_message_to_db(first_name, last_name, username, user_id, user_message, ollama_response)
      
      # Send response back to user
      send_response <- POST(
        url = paste0("https://api.telegram.org/bot", telegram_token, "/sendMessage"),
        body = list(
          chat_id = user_id,
          text = ollama_response
        ),
        encode = "form"
      )
      
      # Check if message was sent successfully
      if (status_code(send_response) == 200) {
        cat("Beskeden er sendt!\n")
      } else {
        cat("Kunne ikke sende beskeden.\n")
      }
    }
  } else {
    cat("Ingen nye opdateringer fundet.\n")
  }
  
  # Pause before the next iteration to avoid spamming the server
  Sys.sleep(2)
}

