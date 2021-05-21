#!/bin/bash

# formata indiferentemente ao separador de campos, data no formato
# yyyy.mm.dd ou dd.mm.yyyy como data no formato yyyy-mm-dd
full_date() {
  # padroniza os separadores de campos
  local d=${1//[^0-9]/-}
  # se a data é dd-mm-yyyy então modifica para yyyy-mm-dd
  [[ ${d:2:1} == '-' ]] && echo ${d:6:4}-${d:3:2}-${d:0:2} || echo $d
}

# formata indiferentemente ao separador de campos, data no formato
# yyyy.mm.dd ou dd.mm.yyyy como data no formato "data por extenso"
long_date() {
  date -d $(full_date $1) '+%A, %d de %B de %Y'
}

# Pesquisa a data presumida do sorteio mais recente dado que são
# realizados normalmente às quartas-feiras e sábados às 20:00
read u F s <<< $(date '+%u %F %s')
if (( $u % 3 != 0 )) || (( $s < $(date -d "$F 20:00" '+%s') )); then
  (( $u % 7 < 4 )) && weekday='saturday' || weekday='wednesday'
  read F s <<< $(date -d "last $weekday" '+%F %s')
fi

echo -e '\nData presumida do sorteio mais recente: '$(long_date $F)'.'

# nome do arquivo local container da série de concursos, baixado a cada execução
# e preservado até a seguinte como backup
html="resultados.html"

# preserva – se existir – o doc html da série de concursos baixado anteriormente
[[ -e $html ]] && mv $html $html~

printf '\n-- Baixando arquivo remoto.\n'

# download do doc html da série de concursos mais recente, armazenado em "$html"
# Nota: Não é possível usar "time stamping" e "cache".
wget --default-page=$html -o wget.log --remote-encoding=utf8 http://loterias.caixa.gov.br/wps/portal/loterias/landing/megasena/\!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNDH0MPAzcDbwMPI0sDBxNXAOMwrzCjA0sjIEKIoEKnN0dPUzMfQwMDEwsjAw8XZw8XMwtfQ0MPM2I02-AAzgaENIfrh-FqsQ9wNnUwNHfxcnSwBgIDUyhCvA5EawAjxsKckMjDDI9FQE-F4ca/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_HGK818G0K8DBC0QPVN93KQ10G1/res/id=historicoHTML/c=cacheLevelPage/=/

# restaura o arquivo e aborta execução se o download foi mal sucedido
if [[ ! -e $html ]]; then
  printf '\nAviso: Não foi possível baixar o arquivo remoto.\n\n'
  [[ -e $html~ ]] && mv $html~ $html
  exit 1
fi

printf '\n-- Ajustando o doc html.\n'

# ajusta o conteúdo do doc html recém baixado que é armazenado num novo doc html
tidy -config tidy.cfg $html | sed -ru -f scripts/clean.sed > concursos.html

if [[ ! -e megasena.sqlite ]]; then
  printf '\n-- Criando o db.\n'
  sqlite3 megasena.sqlite <<EOT
.read sql/monta.sql
.read sql/bitmasks.sql
.read sql/param.sql
EOT
fi

n=$(xmllint --html --xpath "count(//tbody/tr[count(td)>2])" concursos.html)
m=$(sqlite3 megasena.sqlite "select count(1) from concursos")

if (( $n > $m )); then

  printf '\n-- Extraindo dados dos concursos.\n'

  # extrai os dados dos concursos – exceto detalhes sobre acertadores –
  # transformando o doc html ajustado em arquivo text/plain conveniente para
  # importação de dados no sqlite
  xsltproc -o concursos.dat --html --stringparam SEPARATOR "|" --param OFFSET $((m+1)) xsl/concursos.xsl concursos.html

  printf '\n-- Extraindo dados dos acertadores.\n'

  # repete o passo anterior extraindo somente os dados sobre os acertadores
  xsltproc -o ganhadores.dat --html --stringparam SEPARATOR "|" --param OFFSET $((m+1)) xsl/acertadores.xsl concursos.html

  printf '\n-- Preenchendo o db.\n'

  # preenchendo as tabelas dos concursos e dos acertadores com os respectivos
  # dados recém extraídos
  sqlite3 megasena.sqlite <<EOT
.import concursos.dat concursos
.import ganhadores.dat ganhadores
EOT

fi

# notifica usuário sobre o concurso mais recente armazenado no db
sqlite3 megasena.sqlite "select x'0a' || printf('Concurso registrado mais recente: %s em %s', concurso, strftime('%d-%m-%Y', data_sorteio)) || x'0a' from concursos order by concurso desc limit 1"
