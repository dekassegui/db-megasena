#!/bin/bash
#
# Script para atualizar e (re)criar, se necessário, o db da Mega-Sena com dados
# baixados do website da Caixa Econômica Federal Loterias, conforme mudança na
# oferta pública de dados da série temporal dos concursos em 06 de maio de 2021.

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

declare -r dirty=resultados.html      # arquivo da série temporal de concursos
                                      # baixada a cada execução e preservada até
                                      # a seguinte como backup
declare -r clean=concursos.html       # versão de $dirty válida no padrão HTML5
                                      # da W3C
declare -r dbname=megasena.sqlite     # arquivo do db SQLite, opcionalmente
                                      # (re)criado, preenchido a cada execução
declare -r concursos=concursos.dat    # arquivo plain/text dos dados de
                                      # concursos para preenchimento do db
declare -r ganhadores=ganhadores.dat  # arquivo plain/text dos dados de
                                      # acertadores para preenchimento do db

# preserva, se existir, o arquivo da série de concursos baixado anteriormente
[[ -e $dirty ]] && mv $dirty $dirty~

printf '\n-- Baixando arquivo remoto.\n'

# download da série temporal dos concursos que é armazenada em $dirty
# Nota: Não é possível usar time_stamping e cache.
wget --default-page=$dirty -o wget.log --remote-encoding=utf8 http://loterias.caixa.gov.br/wps/portal/loterias/landing/megasena/\!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNDH0MPAzcDbwMPI0sDBxNXAOMwrzCjA0sjIEKIoEKnN0dPUzMfQwMDEwsjAw8XZw8XMwtfQ0MPM2I02-AAzgaENIfrh-FqsQ9wNnUwNHfxcnSwBgIDUyhCvA5EawAjxsKckMjDDI9FQE-F4ca/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_HGK818G0K8DBC0QPVN93KQ10G1/res/id=historicoHTML/c=cacheLevelPage/=/

# restaura o arquivo e aborta execução do script se o download foi mal sucedido
if [[ ! -e $dirty ]]; then
  printf '\nAviso: Não foi possível baixar o arquivo remoto.\n\n'
  [[ -e $dirty~ ]] && mv $dirty~ $dirty
  exit 1
fi

printf '\n-- Ajustando o doc html.\n'

# ajusta o html armazenado em $dirty que torna-se válido no padrão HTML5 da W3C
# possibilitando consultas via XPath e extração de dados via XSLT
tidy -config tidy.cfg $dirty | sed -ru -f scripts/clean.sed > $clean

if [[ ! -e $dbname ]]; then
  printf '\n-- Criando o db.\n'
  sqlite3 $dbname <<EOT
.read sql/monta.sql
.read sql/bitmasks.sql
.read sql/param.sql
EOT
fi

xpath() {
  xmllint --html --xpath "$1" $clean
}

# extrai o número do último concurso registrado no html
n=$(xpath "string(//tbody/tr[last()]/td[1])")

# contabiliza a quantidade de concursos registrados no html
m=$(xpath "count(//tbody/tr[td[22]])")

# checa integridade da sequência de registros de concursos no html baixado
if (( $n > $m )); then
  j=$(( n-m ))
  printf '\nAviso: Falta(m) %d registro(s) no HTML baixado:\n\n' $j
  z=$(xpath '//tbody/tr[td[22]]/td[1]' | sed -ru 's/[^0-9]+/ /g')
  for (( k=1; j>0 && k<=n; k++ )); do
    [[ $z =~ " $k " ]] && continue
    printf ' %04d' $k
    (( --j ))
  done
  printf '\n'
fi

# contabiliza a quantidade de registros de concursos no db
# m=$(sqlite3 $dbname "select count(1) from concursos")

# requisita o número do último concurso registrado no db
m=$(sqlite3 $dbname "select concurso from concursos order by concurso desc limit 1")

if (( $n > $m )); then

  printf '\n-- Extraindo dados dos concursos.\n'

  xslt() {
    xsltproc -o "$1" --html --stringparam SEPARATOR "|" --param OFFSET $((m+1)) "$2" $clean
  }

  # extrai os dados dos concursos – exceto dos acertadores – transformando o doc
  # html ajustado em arquivo text/plain conveniente para importação no SQLite
  xslt $concursos xsl/concursos.xsl

  # contabiliza o número de acertadores a partir do concurso mais antigo não
  # registrado, dado que o db pode estar desatualizado a mais de um concurso
  n=$(xpath "sum(//tr[td[1]>$m]/td[10])")

  if (( $n > 0 )); then
    printf '\n-- Extraindo dados dos acertadores.\n'
    # extrai somente dados dos acertadores, transformando o doc html ajustado
    # em arquivo text/plain conveniente para importação no db SQLite
    xslt $ganhadores xsl/acertadores.xsl
  else
    > $ganhadores   # cria arquivo vazio que evita erro ao importar dados
  fi

  printf '\n-- Preenchendo o db.\n'

  # preenche as tabelas dos concursos e dos acertadores com os dados extraídos
  sqlite3 $dbname <<EOT
.import $concursos concursos
.import $ganhadores ganhadores
EOT

fi

# notifica o número serial e data do concurso mais recente no db
sqlite3 $dbname "select x'0a' || printf('Concurso registrado mais recente: %s em %s', concurso, strftime('%d-%m-%Y', data_sorteio)) || x'0a' from concursos order by concurso desc limit 1"
