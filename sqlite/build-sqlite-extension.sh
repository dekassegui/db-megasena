#!/bin/bash
#
# Compilação das extensões carregáveis do SQLite.
#
# Pacotes (dependências):
#
#   libsqlite3-dev  para compilação de qualquer extensão
#
#   libpcre3-dev    para compilação da extensão "regexp" com suporte opcional
#                   a PCRE senão usa GNU REGEX
#
#   libssl-dev      para compilação da extensão "crypt"
#
#   libglib2.0-dev  para compilação da extensão "regexp" visando strings UTF-8
#
check() {
  sudo ldconfig -p | grep -q "$1"
}

if check 'sqlite3'
then
  for arquivo in 'more-functions.c' 'calendar.c'; do
    echo "compilando \"$arquivo\""
    gcc $arquivo -fPIC -shared -lm -o ${arquivo%.*}.so
  done
  #
  GLIB2='-I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -lglib-2.0'
  if check 'pcre'; then
    echo 'compilando "regexp.c" com suporte a Perl Compatible Regular Expressions aka PCRE'
    gcc regexp.c -fPIC -shared $GLIB2 -lpcre -D PCRE -o regexp.so
  else
    echo 'compilando "regexp.c" com suporte a GNU Regular Expressions aka GNU REGEX'
    gcc regexp.c -fPIC -shared $GLIB2 -o regexp.so
  fi
  #
  if check 'crypto'
  then
    echo 'compilando "crypt.c"'
    gcc crypt.c -fPIC -shared -lm -lcrypto -o crypt.so
  fi
else
  echo '"libsqlite3-dev" não está disponível.'
fi
