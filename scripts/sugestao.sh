#!/bin/bash
for d in $(sqlite3 -init ./sqlite/onload megasena.sqlite ".read sql/rarely.sql" | cut -d " " -f 1)
do
  echo -n " $d"
done
echo
