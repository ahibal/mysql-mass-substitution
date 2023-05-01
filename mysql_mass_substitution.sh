#!/bin/bash


# YOU CAN EDIT THEESE CONFIGURATION variables
user="forge"
database="forge"
host="127.0.0.1"
password=""
exregex_without_capturing_groups="\/[a-z-]+2023"
same_exregex_with_or_without_capturing_groups="(\/[a-z-]+)2023"
new_string_referring_or_not_reffering_to_capture_groups="\12024"

proceed(){
  while true; do
    echo
    echo $1
    echo -n "Proceed? [y/n]: "
    read -r ans
    if [[ $ans == "y" || $ans == "Y" ]]; then
      break
    elif [[ $ans == "n" || $ans == "N" ]]; then
      exit 1
    fi
  done
}

input(){
  while true; do
    echo
    echo -e $1
    echo "Current value is: $(eval "echo \$$2")"
    echo "Enter new value or [Enter] to accept existing value:"
    read -r ans
    if [[ $ans != "" ]]; then
      eval "$2=$ans"
      break
    elif [[ $ans == "" ]]; then
      break
    fi
  done
}

prompts=(
  "Database user name"
  "Database name"
  "Database host ip"
  "Database user password"
  "Extended regex for what you are searching in the database (without capturing groups).\nFor example \\/[a-z-]+2023 will match\n/ghjg-gg-ere2023\n/hjh-ghg-2023\n/hjhhjkh2023\nand so on..."
  "Exactly the same extended regex with or without capturing groups.\nFor example (\\/[a-z-]+)2023 will allow you to use (\\/[a-z-]+) as \\1 when defining the substitution (next step)"
  "The substitution string (using or not using capturing groups from previous step). For example \\12024 if a match was\n++++++----    (+ marks the capture group and - marks the rest of the match)\n\\ghjg-2023\nthen the new string will be \\ghjg-2024"
)


vars=(
  "user"
  "database"
  "host"
  "password"
  "exregex_without_capturing_groups"
  "same_exregex_with_or_without_capturing_groups"
  "new_string_referring_or_not_reffering_to_capture_groups"
)

for i in {0..6}; do
  input "${prompts[$i]}" "${vars[$i]}" 
done 

backupfile_with_semicolons="$(date +%F-%T).sql"
backupfile=$(echo $backupfile_with_semicolons | sed "s/:/-/g")

echo
echo "Creating backup file $backupfile ..."
mysqldump -u $user --password="$password" --replace --no-create-info --no-tablespaces --extended-insert=FALSE -h $host $database | grep -iE "$exregex_without_capturing_groups" > $backupfile

echo
echo "Found:"
cat $backupfile | grep -iEo $exregex_without_capturing_groups | sort | uniq

proceed "I am ready to generate replace.sql file."

echo
echo "Generating replace.sql ..."
cat $backupfile | sed -r "s/$same_exregex_with_or_without_capturing_groups/$new_string_referring_or_not_reffering_to_capture_groups/gi" > replace.sql

echo "Done!"
echo
echo "Please review replace.sql using your editor, search for the changed strings to confirm that the substitutions are correct. If all is OK then you can apply changes to your database using the following command:"
echo "mysql -u $user -p -h $host $database < replace.sql"
echo "If anything wrong you can always revert to initial state using the following command:"
echo "mysql -u $user -p -h $host $database < $backupfile"
