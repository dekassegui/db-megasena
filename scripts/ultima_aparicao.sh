#!/bin/bash
#
# Pesquisa número e data do concurso mais recente no qual uma determinada
# dezena foi sorteada.
#
dezena=$1
#
sqlite3 -init ./sqlite/onload megasena.sqlite "SELECT concurso, data_sorteio, '{ ' || GROUP_CONCAT(ZEROPAD(dezena,2),' ') || ' }'
FROM concursos natural JOIN dezenas_sorteadas
WHERE concurso IS (SELECT MAX(concurso) FROM dezenas_juntadas WHERE bitstatus(dezenas, $dezena-1))"
