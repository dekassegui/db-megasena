# Compiles loadable extension library for sqlite3.
#
# Linux users: Packages libsqlite3-dev is required
#              and libpcre3-dev is required only if PCRE
#              support is wanted
#
# Ubuntu users: DO NOT change compilation parameters order.
#
CC = gcc
FILE = more-functions.c
OUTPUT = $(FILE:.c=.so)

# remove below to alternate support from PCRE to GNU Regular Expressions
DEFINE = -D PCRE

build: $(FILE)
	$(CC) $^ $(DEFINE) -Wall -fPIC -shared -lm -lpcre -o $(OUTPUT)

check:
	sudo ldconfig -p | grep -E "lib(pcre|sqlite)"

