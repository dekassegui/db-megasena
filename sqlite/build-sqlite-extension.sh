#!/bin/bash
#
# Compiles loadable extension library for sqlite3.
# 
# Linux users: Package libsqlite3-dev is required.
#
# Ubuntu users: DO NOT change compilation parameters order.
#
SRC='more-functions.c'
gcc $SRC -fPIC -shared -lm -o ${SRC%.*}.so
