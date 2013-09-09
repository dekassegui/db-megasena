# Compiles loadable extension library for sqlite3.
#
# Linux users: Packages libsqlite3-dev and libpcre3-dev are required.
#
# Ubuntu users: DO NOT change compilation parameters order.
#
CC = gcc
FILE = more-functions.c
OUTPUT = $(FILE:.c=.so)

build: $(FILE)
	$(CC) $^ -Wall -fPIC -shared -lm -lpcre -o $(OUTPUT)

check:
	sudo ldconfig -p | grep -E "lib(pcre|sqlite)"

