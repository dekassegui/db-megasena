# Compilação das extensões carregáveis do SQLite.
#
# Pacotes necessários (dependências):
#
#   libsqlite3-dev  para compilação de qualquer extensão
#
#   libpcre3-dev    para compilação da extensão "regexp" com suporte opcional
#                   a PCRE senão usa GNU REGEX
#
#   libssl-dev      para compilação da extensão "crypt"
#
CC = gcc

build: basic calendar regexp-pcre

basic: more-functions.c
	#
	$(CC) $^ -Wall -fPIC -shared -lm -o more-functions.so

calendar: calendar.c
	#
	$(CC) $^ -Wall -fPIC -shared -lm -o calendar.so

regexp: regexp.c
	#
	# Compiling to support GNU Regular Expressions aka GNU Regex.
	#
	$(CC) $^ -Wall -fPIC -shared -lm -o regexp.so

regexp-pcre: regexp.c
	#
	# Compiling to support Perl Compatible Regular Expressions aka PCRE.
	#
	$(CC) $^ -Wall -fPIC -shared -lm -lpcre -D PCRE -o regexp.so

crypt: crypt.c
	#
	$(CC) $^ -Wall -fPIC -shared -lm -lcrypto -o crypt.so

check:
  #
  # verifica disponibilidade das libs
  #
	sudo ldconfig -p | grep --color=auto -E "lib(pcre|sqlite|crypto)"

