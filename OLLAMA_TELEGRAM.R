library(httr)
library(jsonlite)
library(ollamar)

# Telegram bot token
telegram_token <- "YOUR_TELEGRAM_BOT_TOKEN"

# Initialize last_update_id
last_update_id <- NULL

# Path to the CSV file for logging
log_file <- "telegram_bot_logs.csv"

# Function to generate response from Ollama
generate_ollama_response <- function(message) {
  tryCatch({
    # Send message to Ollama model
    resp <- generate("llama3.2", message)  # Ensure the model name is correct
    ans <- rbind(resp_process(resp, "df"))
    
    # Return the processed response
    return(ans$response[1])  # Assuming 'response' column contains the response
  }, error = function(e) {
    cat("Error generating response from Ollama:", e$message, "\n")
    return("Der skete en fejl, mens jeg prøvede at svare. Prøv igen senere.")
  })
}

# Function to log messages to a CSV file
log_message_to_csv <- function(first_name, last_name, username, user_id, user_message, ollama_response) {
  # Create a new row of data
  new_row <- data.frame(
    first_name = first_name,
    last_name = last_name,
    username = username,
    user_id = user_id,
    message = user_message,
    response = ollama_response,
    timestamp = Sys.time(),
    stringsAsFactors = FALSE
  )
  
  # Check if the CSV file exists
  if (!file.exists(log_file)) {
    # If the file doesn't exist, create it and write the headers
    write.csv(new_row, log_file, row.names = FALSE)
  } else {
    # Append the new row to the existing file
    write.table(new_row, log_file, append = TRUE, sep = ",", col.names = FALSE, row.names = FALSE)
  }
}

# Main loop
while (TRUE) {
  # Fetch updates from Telegram bot
  response <- GET(paste0("https://api.telegram.org/bot", telegram_token, "/getUpdates"))
  
  # Check if request was successful
  if (status_code(response) != 200) {
    cat("Kunne ikke hente opdateringer. Tjek bot-token og internetforbindelse.\n")
    Sys.sleep(5)
    next
  }
  
  # Parse response
  updates <- fromJSON(content(response, "text", encoding = "UTF-8"))
  
  # Check if there are updates
  if (!is.null(updates$result) && nrow(updates$result$message) > 0) {
    # Loop through updates
    for (i in seq_len(nrow(updates$result))) {
      update <- updates$result[i, ]
      
      # Skip already processed updates
      if (!is.null(last_update_id) && update$update_id <= last_update_id) {
        next
      }
      
      # Update last_update_id
      last_update_id <- update$update_id
      
      # Extract message details
      chat <- update$message$chat
      user_message <- update$message$text
      first_name <- chat$first_name
      last_name <- chat$last_name
      username <- chat$username
      user_id <- chat$id
      
      # Debugging: Print received message
      cat("Modtaget besked fra:", username, "(", first_name, last_name, "):", user_message, "\n")
      
      # Generate response using Ollama
      ollama_response <- generate_ollama_response(user_message)
      
      # Log message to CSV
      log_message_to_csv(first_name, last_name, username, user_id, user_message, ollama_response)
      
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
