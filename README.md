# mysql_mass_substitution.sh

Mass substitution of strings in mysql database using REPLACE statements.

## Database user name.

    Current value is: forge
    Enter new value or [Enter] to accept existing value:

    Value is set: forge

## Database name.

    Current value is: forge
    Enter new value or [Enter] to accept existing value:

    Value is set: forge

## Database host ip.

    Current value is: 127.0.0.1
    Enter new value or [Enter] to accept existing value:

    Value is set: 127.0.0.1

## Database user password.

    Current value is:
    Enter new value or [Enter] to accept existing value:

    Password is set.

## Extended regex for what you are searching in the database (without capturing groups).

    For example a value of \/[a-z-]+2023 will match
    /ghjg-gg-ere2023
    /hjh-ghg-2023
    /hjhhjkh2023
    and so on...
    Current value is: \/[a-z-]+2023
    Enter new value or [Enter] to accept existing value:

    Value is set: \/[a-z-]+2023

## Exactly the same extended regex with or without capturing groups.

    For example a value of (\/[a-z-]+)2023 will allow you to use (\/[a-z-]+) as \1
    when defining the substitution (next step).
    Current value is: (\/[a-z-]+)2023
    Enter new value or [Enter] to accept existing value:

    Value is set: (\/[a-z-]+)2023

## The substitution string (using or not using capturing groups from previous step).

    For example a value of \12024 means that if a match was

    ++++++---- (+ marks the capture group and - marks the rest of the match)
    \ghjg-2023

    then the new string will be \ghjg-2024
    Current value is: \12024
    Enter new value or [Enter] to accept existing value:

    Value is set: \12024


    Searching ...

    Found:
    /hot-sun-2023
    /hot-sun-plasma-2023
    /this-is-a-test2023
    /mother-father-2023
    /raining-chairs-2023
    /factory2023

    Analyzing ...

    Creating apply.sql and revert.sql ...

    Done!

    Please review apply.sql using your editor, search for the changed strings
    to confirm that the substitutions are correct.
    If all is OK then you can apply changes to your database using the following command:

    mysql -u forge -p -h 127.0.0.1 forge < apply.sql

    If anything wrong you can always revert to initial state using the following command:

    mysql -u forge -p -h 127.0.0.1 forge < revert.sql
