# Compiles loadable extension library for sqlite3.
#
# Linux users: Packages libsqlite3-dev is required
#              and libpcre3-dev is required only if PCRE
#              support is wanted
#
# Ubuntu users: DO NOT change compilation parameters order.
#
# Run with argument "gnu-regex" to alternate support to GNU Regex.
#
CC = gcc
FILE = more-functions.c
OUTPUT = $(FILE:.c=.so)

build: $(FILE)
	#
	# Compiling to support Perl Compatible Regular Expressions aka PCRE.
	#
	$(CC) $^ -D PCRE -Wall -fPIC -shared -lm -lpcre -o $(OUTPUT)

gnu-regex: $(FILE)
	#
	# Compiling to support GNU Regular Expressions aka GNU Regex.
	#
	$(CC) $^ -Wall -fPIC -shared -lm -o $(OUTPUT)

check:
	sudo ldconfig -p | grep -E "lib(pcre|sqlite)"

