#!/bin/bash

# Define PSQL variable for database queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate the Secret Random Number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if the user exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user, insert into database
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  
  # Insert user into the database & ensure correct retrieval
  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)"
  
  # Fetch the user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=0
else
  # Extract user data properly
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"

  # Trim whitespace from BEST_GAME (handles NULL values too)
  BEST_GAME=$(echo "$BEST_GAME" | xargs)

  # Ensure BEST_GAME always has a valid value
  if [[ -z $BEST_GAME || $BEST_GAME == "NULL" ]]; then
    BEST_GAME="N/A"
  else
    BEST_GAME=$(echo "$BEST_GAME" | xargs)  # Trim any unwanted spaces
  fi
  # Print the exact required format
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Prompt for the first guess
echo "Guess the secret number between 1 and 1000:"
read GUESS
NUMBER_OF_GUESSES=1  # Start at 1 to match test expectations

# Validate that the input is an integer and count invalid attempts
while [[ ! $GUESS =~ ^[0-9]+$ ]]; do
  (( NUMBER_OF_GUESSES++ ))  # Count invalid guesses
  echo "That is not an integer, guess again:"
  read GUESS
done

# Main guessing loop
while [[ $GUESS -ne $SECRET_NUMBER ]]; do
  (( NUMBER_OF_GUESSES++ ))  # Count every valid guess attempt

  if [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi

  read GUESS

  while [[ ! $GUESS =~ ^[0-9]+$ ]]; do
    (( NUMBER_OF_GUESSES++ ))  # Count invalid guesses
    echo "That is not an integer, guess again:"
    read GUESS
  done
done

# User guessed correctly
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Update games played
USER_WIN=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID")

# Ensure BEST_GAME is a number, or set it to a high number if NULL/N/A
if [[ -z $BEST_GAME || $BEST_GAME == "NULL" || $BEST_GAME == "N/A" ]]; then
  BEST_GAME=9999  # A high number to ensure the first real game always updates best_game
fi

if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
  $PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE user_id = $USER_ID"
fi
