# Compiles loadable extension library for sqlite3.
#
# Linux users: Package libsqlite3-dev is required.
#
# Ubuntu users: DO NOT change compilation parameters order.
#
CC = gcc
FILE = more-functions.c
OUTPUT = $(FILE:.c=.so)

build: $(FILE)
	$(CC) $^ -Wall -fPIC -shared -lm -o $(OUTPUT)

check:
	sudo ldconfig -p | grep "libsqlite"

