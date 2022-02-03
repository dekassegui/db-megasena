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

declare -r html=resultados.html       # arquivo da série temporal de concursos
                                      # baixado a cada execução e preservado até
                                      # a seguinte como backup
declare -r dbname=megasena.sqlite     # arquivo do db SQLite, opcionalmente
                                      # (re)criado, preenchido a cada execução
declare -r concursos=concursos.dat    # arquivo plain/text dos dados de
                                      # concursos para preenchimento do db
declare -r ganhadores=ganhadores.dat  # arquivo plain/text dos dados de
                                      # acertadores para preenchimento do db

# link para o arquivo html remoto que contém a série histórica dos concursos
declare -r url=http://loterias.caixa.gov.br/wps/portal/loterias/landing/megasena/\!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNDH0MPAzcDbwMPI0sDBxNXAOMwrzCjA0sjIEKIoEKnN0dPUzMfQwMDEwsjAw8XZw8XMwtfQ0MPM2I02-AAzgaENIfrh-FqsQ9wNnUwNHfxcnSwBgIDUyhCvA5EawAjxsKckMjDDI9FQE-F4ca/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_HGK818G0K8DBC0QPVN93KQ10G1/res/id=historicoHTML/c=cacheLevelPage/=/

# preserva, se existir, o arquivo da série de concursos baixado anteriormente
[[ -e $html ]] && mv $html $html~

printf '\n-- Baixando arquivo remoto.\n'

# Download do arquivo html da série histórica dos concursos, com imediata
# contagem da quantidade de concursos e extração do número serial do concurso
# mais recente – certamente o último.
# Nota: Não é possível usar time_stamping & cache e HTTP errors eventuais serão
#       notificados apenas no dispositivo de saída padrão.
read m n <<< $(xidel $url --download=$html --output-encoding=UTF-8 -se 'concat(count(html/body/table/tbody/tr[td]), " ", html/body/table/tbody/tr[last()]/td[1])')

# restaura o arquivo e aborta execução do script se o download foi mal sucedido
if [[ ! -e $html ]]; then
  printf '\nAviso: Não foi possível baixar o arquivo remoto.\n\n'
  [[ -e $html~ ]] && mv $html~ $html
  exit 1
fi

xpath() {
  xidel $html -s --xpath "$1"
}

# checa a sequência dos números dos concursos no html
if (( n > m )); then
  # monta o array dos números dos concursos
  read -d' ' -a z <<< $(xpath 'html/body/table/tbody/tr/td[1]')
  r=$(( n-m ))
  printf '\nAviso: %d registros ausentes no html:\n\n' $r
  # pesquisa componentes ausentes na frente do array
  for (( j=1; j<${z[0]}; j++, r-- )); do printf ' %04d' $j; done
  # pesquisa componentes ausentes dentro do array
  for (( i=0; r>0 && i<m-1; i++ )); do
    for (( j=${z[i]}+1; j<${z[i+1]}; j++, r-- )); do printf ' %04d' $j; done
  done
  printf '\n'
  unset z     # elimina o array dos números
fi

# cria o db se inexistente
if [[ ! -e $dbname ]]; then
  printf '\n-- Criando o db.\n'
  sqlite3 $dbname <<EOT
.read sql/monta.sql
.read sql/bitmasks.sql
.read sql/param.sql
EOT
fi

# requisita o número do concurso mais recente registrado ou "zero" se db vazio
m=$(sqlite3 $dbname 'select case when count(1) then concurso else 0 end from ( select concurso from concursos order by data_sorteio desc limit 1 )')

if (( n > m )); then

  printf '\n-- Extraindo dados dos concursos.\n'

  # extrai do html os dados dos concursos – exceto dos acertadores – que são
  # armazenados num CSV adequado para importação no db SQLite
  xpath "html/body/table/tbody/tr[td[1]>$m] / string-join((td[1], string-join((substring(td[3],7), substring(td[3],4,2), substring(td[3],1,2)), '-'), td[position()>3 and 13>position()], translate(string-join(td[(position()>12 and 16>position()) or (position()>16 and 20>position())], '|'), ',.', '.'), if (td[20]='SIM') then 1 else 0), '|')" > $concursos

  # contabiliza o número de acertadores a partir do concurso mais antigo não
  # registrado, dado que o db pode estar desatualizado a mais de um concurso
  n=$(xpath "sum(html/body/table/tbody/tr[td[1]>$m]/td[10])")

  if (( n > 0 )); then
    printf '\n-- Extraindo dados dos acertadores.\n'
    # extrai do html somente dados dos acertadores, que são armazenados
    # num CSV adequado para importação no db SQLite
    xpath "html/body/table/tbody/tr[td[1]>$m and td[10]>0]/td[16]/table/tbody/tr / concat(ancestor::tr[td]/td[1], '|', upper-case(concat(if (string-length(td[1])=0) then 'NULL' else td[1], '|', if (string-length(td[2])=0) then 'NULL' else td[2])))" > $ganhadores
  else
    > $ganhadores   # cria arquivo vazio para evitar erro na importação
  fi

  printf '\n-- Preenchendo o db.\n'

  # preenche as tabelas dos concursos e dos acertadores com os dados extraídos
  sqlite3 $dbname <<EOT
.import $concursos concursos
.import $ganhadores ganhadores
EOT

fi

# notifica o número serial e data do concurso mais recente no db
read n s <<< $(sqlite3 -separator ' ' $dbname 'select concurso, data_sorteio from concursos order by concurso desc limit 1')
printf '\nConcurso mais recente no DB: %04d (%s).\n\n' $n "$(long_date $s)"

# pesquisa e notifica reincidência da combinação das dezenas sorteadas mais
# recente da série histórica dos concursos
m=$(sqlite3 $dbname "with cte(N) as (select dezenas from dezenas_juntadas where concurso == $n) select count(1) from dezenas_juntadas, cte where dezenas == N")
(( m > 1 )) && printf 'Nota: A combinação dos números sorteados %s\n\n' "ocorreu $m vezes!"
