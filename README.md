# Ollama_LLM_R_Telegram
The idea is to bring a locally hosted LLM to life via a R and Telegram - with a twist.


#to make this work youll need the following:

1) A LLM (Large Language Model) from OLLAMA (my version uses LLAMA3.2 from Meta)
  Download link to OLLAMA: https://ollama.com/
  Download link to LLMA3.2: https://ollama.com/library/llama3.2
  (alternative is to download OLLAMA and run this command in the terminal "ollama run llama3.2)

2) A telegram account:
  Download the app to your phone of choice and set it up with your name, and number

3) A telegram Bot
   Follow this guide to set it up with botfather: https://core.telegram.org/bots/tutorial#introduction

4) R & Rstudio
   Link to Download: https://posit.co/download/rstudio-desktop/

5) install the R package "ollamar" from: https://github.com/hauselin/ollama-r



###########################################################################
#                          2 do                                           #
# USE SQL to database usernames, first names, lastnames, messages &       #
# responses                                                               #
#                                                                         #
# Fix beginning of script where it answers ALL messages it has ever       #
# recived (potentially something with message_id and a boolean            #
# Answered = 0, not = 1, if message < 1 = ANSWER)                         #
#          I dont know, ill figure it out later                           #
###########################################################################
