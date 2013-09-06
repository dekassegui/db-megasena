#!/bin/bash
#
# máximas latências de cada número da megasena ao longo do tempo
#
sqlite3 megasena.sqlite 'SELECT "-- " || MAX(concurso) FROM concursos'
for (( n=1; n<=60; n++ ))
do
  sql="SELECT GROUP_CONCAT((dezenas >> ($n-1)) & 1, '') FROM dezenas_juntadas"
  r=$(sqlite3 megasena.sqlite "$sql" | sed 's/11*/\n/g' | wc -L)
  printf "%02d %d\n" $n $r
done
