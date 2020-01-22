#!/bin/sh
DATABASE=hdb
if [[ -z `psql -Atqc '\list ${DATABASE}' postgres` ]] 
then
    echo "Database does not exist, creating" 
    createdb ${DATABASE}; 
else
    echo "Database already exists, taking no action"
fi