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
SRC='more-functions.c'
#
gcc $SRC -D PCRE -fPIC -shared -lm -lpcre -o ${SRC%.*}.so
