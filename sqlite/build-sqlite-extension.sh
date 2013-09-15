#!/bin/bash
#
# Compiles loadable extension library for sqlite3.
#
# Linux users: Package libsqlite3-dev is required
#              and libpcre3-dev is also required
#              only if PCRE support is wanted
#
# Ubuntu users: DO NOT change compilation parameters order.
#
# Run with argument GNU-REGEX to alternate support to GNU Regex.
#
SRC='more-functions.c'
#
shopt -s nocasematch
if [[ $1 =~ ^GNU-REGEX$ ]];
then
  echo 'Compiling to support GNU Regular Expressions aka GNU Regex.'
  gcc $SRC -fPIC -shared -lm -o ${SRC%.*}.so
else
  echo 'Compiling to support Perl Compatible Regular Expressions aka PCRE.'
  gcc $SRC -D PCRE -fPIC -shared -lm -lpcre -o ${SRC%.*}.so
fi
