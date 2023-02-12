#!/bin/bash
# Number guessing script
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Getting random number for the user to guess
SECRET_NUMBER=$(( RANDOM%1000 + 1 ))

echo -e "\nEnter your username: "
read USERNAME_INPUT

# Querying the database to see if the given username already exists in it
USERNAME=$($PSQL "SELECT username FROM users WHERE username='$USERNAME_INPUT'")

# Checking if the previous query found a matching username or not
if [[ -z $USERNAME ]]
then
  INSERT_USERNAME=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME_INPUT', 1, 0)")
  echo -e "\nWelcome, $USERNAME_INPUT! It looks like this is your first time here."

  # Selecting the user's best game to use later when they've guessed the secret number
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME_INPUT'")
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."

  # Updating the user's games played after having selected their games played value for the previous feedback
  INCREMENT_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=(games_played + 1) WHERE username='$USERNAME'")
fi

echo -e "\nGuess the secret number between 1 and 1000:"
read USER_GUESS
# Initializing variable to track the user's guesses, and compare that value against their best game later on
NUMBER_OF_GUESSES=1

while [[ $USER_GUESS != $SECRET_NUMBER ]]
do
  # Checking if the user's guess is an integer and giving feedback depending on that
  if [[ $USER_GUESS =~ ^[0-9]+$ ]]
  then
    if [[ $USER_GUESS > $SECRET_NUMBER ]]
    then
      echo -e "\nIt's lower than that, guess again:"
    else
      echo -e "\nIt's higher than that, guess again:"
    fi
  else
    echo -e "\nThat is not an integer, guess again:"
  fi
  read USER_GUESS
  (( NUMBER_OF_GUESSES+=1 ))
done

# Feedback for when the user guesses the secret number correctly
echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Updating the user's best game in the database depending on their previous best game
if [[ $BEST_GAME == 0 ]]
then
  INSERT_FIRST_GAME=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME_INPUT'")
elif [[ $NUMBER_OF_GUESSES < $BEST_GAME ]]
then
  INSERT_NEW_BEST=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'")
fi