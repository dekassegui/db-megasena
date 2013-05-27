#!/bin/bash
#
# gera todas as possíveis combinações das 60 dezenas da Mega-Sena duas a duas
#
base2 () {
  dc -e "$1 2op"
}

pad () {
  printf "%60s" $1 | tr ' ' 0
}

for (( i=1; i<=59; i++ ))
do
  for (( j=i+1; j<=60; j++ ))
  do
    dupla=$(( (1 << ($i-1)) | (1 << ($j-1)) ))
    #printf '%02d %02d %s\n' $i $j $( pad $( base2 $dupla ) )
    printf '%02d %02d %d\n' $i $j $dupla
  done
done
