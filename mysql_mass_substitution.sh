#!/bin/bash


# YOU CAN EDIT THEESE CONFIGURATION variables
user="forge"
database="forge"
host="127.0.0.1"
password=""
exregex_without_capturing_groups="[a-z-]+2023"
same_exregex_with_or_without_capturing_groups="([a-z-]+)2023"
new_string_referring_or_not_referring_to_capture_groups="\12024"

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
  echo
  echo -e $1
  echo "Current value is: $(eval "echo \$$2")"
  echo "Enter new value or [Enter] to accept existing value:"

  if [[ $2 == "password" ]]; then
    read -rs ans
  else
    read -r ans
  fi

  if [[ $ans != "" ]]; then
    eval "$2=\"$ans\""
  fi
  if [[ $2 == "password" ]]; then
    echo "Password is set."
  else
    echo "Value is set: $(eval "echo \$$2")"
  fi
}

prompts=(
  "Database user name"
  "Database name"
  "Database host ip"
  "Database user password"
  "Extended regex for what you are searching in the database (without capturing groups).\nFor example [a-z-]+2023 will match\nghjg-gg-ere2023\nhjh-ghg-2023\nhjhhjkh2023\nand so on..."
  "Exactly the same extended regex with or without capturing groups.\nFor example ([a-z-]+)2023 will allow you to use ([a-z-]+) as \\1 when defining the substitution (next step)"
  "The substitution string (using or not using capturing groups from previous step). For example \\12024 if a match was\n+++++----    (+ marks the capture group and - marks the rest of the match)\nghjg-2023\nthen the new string will be ghjg-2024"
)


vars=(
  "user"
  "database"
  "host"
  "password"
  "exregex_without_capturing_groups"
  "same_exregex_with_or_without_capturing_groups"
  "new_string_referring_or_not_referring_to_capture_groups"
)

for i in {0..6}; do
  input "${prompts[$i]}" "${vars[$i]}" 
done 

filtereddump="filtereddump.sql"

echo
echo "Searching ..."
mysqldump -u $user --password="$password" --complete-insert --skip-extended-insert --no-create-info --no-tablespaces  -h $host $database | grep -iE "$exregex_without_capturing_groups" > $filtereddump

echo
echo "Found:"
cat $filtereddump | grep -iEo $exregex_without_capturing_groups | sort | uniq

echo
echo "Analyzing ..."
declare -A table_column
while read -r line; do
  table_name=$(echo "$line" | sed -r "s/INSERT INTO \`(.*)\` \(.*/\1/")
  columns=$(echo "$line" | sed -r "s/INSERT.*\((.*)\) VALUES.*/\1/" | sed -r "s/[\`,]//g" | sed -r "s/ /\n/g")
  column_count=$(echo "$columns" | wc -l)
  values=$(echo "$line" | sed -r "s/.*VALUES \((.*)\).*/\1/" | sed -r "s/','/'\n'/g" | sed -r "s/,([0-9.NULL-]+),'/\n\1\n'/g" | sed -r "s/',([0-9.NULL-]+),/'\n\1\n/g" | sed -r "s/NULL,/NULL\n/g" | sed -r "s/,NULL/\nNULL/g" | sed -r "s/(^[0-9.-]+),/\1\n/" | sed -r "s/(^[0-9.-]+),/\1\n/" | sed -r "s/(^[0-9.-]+),/\1\n/" | sed -r "s/(^[0-9.-]+),/\1\n/" | sed -r "s/,([0-9.-]+)$/\n\1/")
  value_count=$(echo "$values" | wc -l)
  if [[ $column_count != $value_count ]]; then
    echo
    echo "$table_name"
    echo
    echo "$column_count columns"
    echo "$columns"
    echo
    echo "$value_count values"
    echo "$values"
    echo
    echo "$line"
    echo
    echo "Cannot proceed. You must improve value parsing. Please imrove this script."
    exit 1
  fi
  zerones=$(echo "$values" | awk "{IGNORE_CASE=1; print /$exregex_without_capturing_groups/ ? "1" : "0"}")
  readarray -t columns_array <<< $(echo "$columns")
  readarray -t values_array <<< $(echo "$values")
  readarray -t zerones_array <<< $(echo "$zerones")
  for ((coli=0 ; coli<$column_count ; coli++)); do
    if [[ "${zerones_array[$coli]}" == "1" ]]; then
      column_matches=$(echo "${values_array[$coli]}" | grep -ioE "$exregex_without_capturing_groups" | sort | uniq)
      current_col_name="${columns_array[$coli]}"
      new_to_put=$(echo "${table_column["$table_name:$current_col_name"]}"; echo "$column_matches")
      table_column["$table_name:$current_col_name"]=$(echo "$new_to_put" | sed -r "/^$/d" | sort | uniq)
    fi
  done
done <$filtereddump
rm "$filtereddump"

echo
echo "Creating apply.sql and revert.sql ..."
> temp.sql
for key in "${!table_column[@]}"; do
  table_name=$(echo "$key" | sed -r "s/:/\n/" | head -n 1)
  column_name=$(echo "$key" | sed -r "s/:/\n/" | tail -n 1)
  column_matches="${table_column["$key"]}"
  column_replacements=$(echo "$column_matches" | sed -r "s/$same_exregex_with_or_without_capturing_groups/$new_string_referring_or_not_referring_to_capture_groups/gi")
  readarray -t column_matches_array <<< $(echo "$column_matches")
  readarray -t column_replacements_array <<< $(echo "$column_replacements")
  count="${#column_matches_array[@]}"
  for ((i=0 ; i<$count ; i++)); do
    statement="UPDATE $table_name SET $column_name=REPLACE($column_name,'${column_matches_array[$i]}','${column_replacements_array[$i]}');"
    echo "$statement" >> temp.sql
  done
done
cat temp.sql | sort | uniq > apply.sql
rm temp.sql
cat apply.sql | sed -r "s/'(.*)','(.*)'/'\2','\1'/" > revert.sql

echo
echo "Done!"
echo
echo "Please review apply.sql using your editor, search for the changed strings to confirm that the substitutions are correct. If all is OK then you can apply changes to your database using the following command:"
echo "mysql -u $user -p -h $host $database < apply.sql"
echo "If anything wrong you can always revert to initial state using the following command:"
echo "mysql -u $user -p -h $host $database < revert.sql"
