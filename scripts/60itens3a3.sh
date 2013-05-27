#!/bin/bash
#
# gera todas as possíveis combinações das 60 dezenas da Mega-Sena três a três
#
base2 () {
  dc -e "$1 2op"
}

pad () {
  printf "%60s" $1 | tr ' ' 0
}

for (( i=1; i<=58; i++ ))
do
  for (( j=i+1; j<=59; j++ ))
  do
    for (( k=j+1; k<=60; k++ ))
    do
      terno=$(( (1 << ($i-1)) | (1 << ($j-1)) | (1 << ($k-1)) ))
      #printf '%02d %02d %02d %s\n' $i $j $k $( pad $( base2 $terno ) )
      printf '%02d %02d %02d %d\n' $i $j $k $terno
    done
  done
done
