#/bin/bash
#
# Cria, reconstrói parcialmente ou sincroniza db SQLite com dados extraídos de
# arquivo html contendo tabela da série temporal dos concursos da mega-sena.

# checa disponibilidade dos comandos utilizados neste script
for comando in sqlite3 unzip wget xmllint xsltproc tidy
do
  if ! 1>/dev/null which ${comando}; then
    [[ $comando == xmllint ]] && pacote='libxml2-utils' || pacote=$comando
    lista=( ${lista[*]} $pacote )
  fi
done
if [[ $lista ]]; then
  printf '\nOps! Este script usa '
  if (( ${#lista[*]} == 1 )); then
    printf '1 aplicativo que não está disponível'
  else
    printf '%d aplicativos que não estão disponíveis' ${#lista[*]}
  fi
  printf '.\n\nDisponibilize-o(s) instalando o(s) seguinte(s) pacote(s):\n\n\t'
  printf '   %s' ${lista[*]}
  printf '\n\n'
  exit
fi

# inabilita "distinção entre letras maiúsculas e minusculas"
shopt -s nocasematch
# extração de argumentos
while [[ $1 ]]; do
  case $1 in
    --force-update | -u)
      force_update=true
    ;;
    --rebuild-db | -r)
      rebuild_db=true
    ;;
    --help | -h)
      echo -e "
  Cria, reconstrói parcialmente ou sincroniza db SQLite com dados extraídos de
  arquivo html contendo tabela da série temporal dos concursos da mega-sena.\n
  O download do arquivo html disponível no website da Caixa Econômica Federal
  ocorrerá sempre que:\n
   (1) o arquivo não existir localmente\n
   (2) ou o arquivo existir localmente e sua data de criação/modificação
       for anterior à data de criação/modificação do arquivo remoto, tal
       que a data do último concurso listado no arquivo html é anterior
       à data presumida do sorteio mais recentemente realizado\n
   (3) ou se esse script for executado com o parâmetro --force-update\n
  sobrescrevendo o arquivo previamente baixado nos dois últimos casos.\n
  Uso: $(basename $0) [--force-update|-u] [--rebuild-db|-r] [--help|-h]\n
  --force-update, -u Força download do arquivo html remoto atualizado.
  --rebuild-db, -r   Força a reconstrução parcial do db SQLite.
  --help, -h         Apresenta este help e finaliza execução do script.\n"
      exit
    ;;
  esac
  shift
done
# atribui valores default das opções
force_update=${force_update:-false}
rebuild_db=${rebuild_db:-false}
# reabilita "distinção entre letras maiúsculas e minusculas"
shopt -u nocasematch

# formata indiferentemente ao separador de campos, data no formato
# yyyy.mm.dd ou dd.mm.yyyy como data no formato yyyy-mm-dd
full_date() {
  # padroniza os separadores de campos
  local d=${1//[^0-9]/-}
  # se a data é dd-mm-yyyy então modifica para yyyy-mm-dd
  [[ ${d:2:1} == '-' ]] && echo ${d:6:4}-${d:3:2}-${d:0:2} || echo $d
}

# Workaround evitando mal funcionamento do comando "date" ao formatar data
# arbitrária entre as zero horas e primeira hora do primeiro dia do horário
# de verão brasileiro, intervalo esse no qual a variável de ambiente TZ aka
# timezone, é indefinida e.g.: date --date='2012-10-21 00:59:59.999'.
declare -r tz=$(date +%Z)

# formata indiferentemente ao separador de campos, data no formato
# yyyy.mm.dd ou dd.mm.yyyy como data no formato "data por extenso"
long_date() {
  TZ=$tz date -d $(full_date $1) '+%A, %d de %B de %Y'
}

unixtime() {
  TZ=$tz date -d $(full_date $1) '+%s'
}

# data da última modificação de arquivo em segundos da era unix
timestamp() {
  stat -c %Y "$1"
}

xpath() {
  xmllint --xpath "$1" $xml
}

declare -r html='D_MEGA.HTM'              # html baixado do website
declare -r xml='MEGA.XML'                 # xml baseado no html
declare -r db_file='megasena.sqlite'      # container do db SQLite
declare -r db_renew='sql/db-renew.sql'    # script para criar/regenerar o db
declare -r data_load='sql/data-load.sql'  # script de importação de dados do db
declare -r xsl='xsl/list-builder.xsl'     # xsl gerador dos dados do db

# endereço do zipfile remoto contendo o arquivo html
declare -r url='http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_megase.zip'

# expressão XPath p/obter a quantidade de registros no xml
declare -r count_n_xml='count(//table/tr)'

declare -r data_ultimo_concurso='//table/tr[last()]/td[2]/text()'

declare -r numero_ultimo_concurso='//table/tr[last()]/td[1]/text()'

# sql p/obter a quantidade de registros na tabela 'concursos'
declare -r count_n_db='SELECT COUNT(concurso) FROM concursos'

monta_xml() {
  # remove entity mal declarada, atributos e espaços desnecessários
  sed -r 's/&nbsp([^;])/\1/g; s/<(td|tr)[^>]+>/<\1>/g; s/\s*(\S+(\s\S+)*)\s*/\1/g; s/\r//g' $html > /tmp/mega.html
  printf '<?xml version="1.0"? encoding="ISO-8859-1">\n<table>' > $xml
  # extrai da tabela as linhas que contém registros de concursos
  # com normalização de formatos numéricos e tipo boolean
  xmllint --html --xpath '//table/tr[count(td)=21]' /tmp/mega.html | sed -r 's/\.//g; y/,/./; s/SIM/1/; t; s/N&Atilde;O/0/' >> $xml
  printf '\n</table>\n' >> $xml
  # transforma entities literais em numéricas evitando erros no xsltproc
  tidy -xml -numeric -modify -quiet $xml
  # ambos arquivos sempre terão o mesmo timestamp de última modificação
  touch -r $html $xml
}

if [[ -e $html ]]; then
  if ! [[ -e $xml ]] || (( $(timestamp $xml) != $(timestamp $html) )); then
    monta_xml
  fi
else
  [[ -e $xml ]] && rm -f $xml   # somente existirá xml se existir html
fi

# HABILITAÇÃO DO DOWNLOAD DO ARQUIVO HTML

if [[ $force_update == false ]] && [[ -e $html ]]; then

  # Pesquisa a data presumida do sorteio mais recente dado que são
  # realizados normalmente às quartas-feiras e sábados às 20:30
  read u F H M <<< $(date '+%u %F %H %M')
  if (( $u % 3 != 0 )) || (( $H < 20 )) || ((( $H == 20 )) && (( $M < 30 )))
  then
    (( $u % 7 < 4 )) && weekday='saturday' || weekday='wednesday'
    F=$(TZ=$tz date -d "last $weekday" '+%F')
  fi

  echo -e '\nData presumida do sorteio mais recente: '$(long_date $F)'.'

  # extrai a data do último registro no xml
  data=$(xpath $data_ultimo_concurso)

  # se a data presumida do concurso mais recente for posterior à data do
  # último registro no xml então tentará obter o html remoto atualizado
  if (( $(unixtime $F) > $(unixtime $data) )); then
    force_update=true
  fi

fi

# DOWNLOAD DO ARQUIVO HTML

if [[ $force_update == true ]] || [[ ! -e $html ]]; then

  printf '\nRequisitando "%s" ' $html
  # se existe html então preserva seu timestamp
  if [[ -e $html ]]; then
    printf 'mais recente '
    declare -i tm=$(timestamp $html)
  fi
  printf 'ao website.\n'

  # realiza o download do zipfile remoto se mais recente que o localmente
  # disponível ou se ainda não existir localmente e então extrai o html
  # se mais recente que o previamente existente ou se ainda não existir,
  # tal que ambos procedimentos sobrescrevem arquivos
  wget -a wget.log -N $url && unzip -q -o -u $(basename $url) $html

  # checa se não "existia" e o download foi mal sucedido
  if ! [[ -e $html ]]; then
    printf '\nErro: Arquivo "%s" não está disponível e o download foi mal sucedido.\n\n' $html
    exit 1
  fi

  # checa se "existia" o xml e se o html não foi atualizado
  if [[ -e $xml ]] && (( $tm >= $(timestamp $html) )); then
    printf '\nOBSERVAÇÃO: Arquivo "%s" não foi atualizado!\n' $html
  else
    monta_xml # cria ou atualiza xml
    # se o db existe e não foi requisitada sua reconstrução
    if [[ -e $db_file ]] && [[ $rebuild_db == false ]]; then
      k=$(xpath $count_n_xml)
      # se a quantidade de registros no db é igual a quantidade de
      # registros no xml recém criado ou atualizado
      if (( $(sqlite3 $db_file "$count_n_db") == $k )); then
        # extrai o caractére separador de campos declarado no script
        SEP=$(sed -nr '/^\.separator/ s/.+("|\d39)(.)\1.*/\2/p' $data_load)
        # obtêm o último registro no db
        dbrec=$(sqlite3 -separator "$SEP" $db_file 'SELECT * FROM concursos WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')
        # extrai o último registro do xml e formata como se obtido via SQLite
        xmlrec=$(xsltproc --param OFFSET $k --stringparam SEPARATOR "$SEP" $xsl $xml | sed -r 's/([^0-9.-])0+([1-9])/\1\2/g; s/(\.[0-9])0+/\1/g; s/NULL//g')
        # se o último registro do db não for igual ao último registro do xml
        # então força a sincronização do db eliminando seu último registro
        if [[ $dbrec != $xmlrec ]]; then
          sqlite3 $db_file 'DELETE FROM concursos WHERE concurso IS (SELECT MAX(concurso) FROM concursos)'
        fi
      fi
    fi
  fi
fi

data=$(date -r $html '+%Y-%m-%d')
printf '\nArquivo "%s" gerado em: %s.\n\n' $html "$(long_date $data)"
n=$(xpath $count_n_xml)  # quantidade de registros no xml
k=$(xpath $numero_ultimo_concurso)
data=$(xpath $data_ultimo_concurso)
LANG='pt_BR' printf "            #registros: %'d\n\n" $n
printf '    Concurso mais recente\n\n'
LANG='pt_BR' printf "                número: %'d\n" $k
printf '       data do sorteio: %s\n' "$(long_date $data)"

# MANUTENÇÃO DO DB

monta_buffer() {
  printf '\n\n\tXML ---( XSLT )--> Text'
  # extrai o filename do buffer declarado no script
  local buffer=$(sed -nr '/^\.import/ s/.+("|\d39)(.+)\1.*/\2/p' $data_load)
  # extrai o caractére separador de campos declarado no script
  local SEP=$(sed -nr '/^\.separator/ s/.+("|\d39)(.)\1.*/\2/p' $data_load)
  # monta o buffer transformando o conteúdo do xml
  xsltproc --param OFFSET $1 --stringparam SEPARATOR "$SEP" $xsl $xml > $buffer
}

processa_buffer() {
  printf ' ---( SQLite )---> DB'
  # preenche o db com os dados no buffer
  sqlite3 $db_file ".read $data_load"
  # compara as quantidades de registros do html e do db
  m=$(sqlite3 $db_file "$count_n_db")
  (( $n == $m )) && local status='bem' || local status='mal'
  printf '\n\n%s do db "%s" foi %s sucedida.\n' $1 $db_file $status
}

if [[ $rebuild_db == true ]] || [[ ! -e $db_file ]]; then

  # CRIAÇÃO OU RECONSTRUÇÃO PARCIAL DO DB

  [[ -e $db_file ]] && operation='Reconstrução' || operation='Criação'

  sqlite3 $db_file ".read $db_renew"

  monta_buffer 1  # todos os dados do xml

  processa_buffer $operation

else  # ATUALIZAÇÃO DO DB

  m=$(sqlite3 $db_file "$count_n_db")   # quantidade de registros no db

  # atualiza o db somente se a quantidade de registros no db
  # é estritamente menor que a quantidade de registros no xml
  if (( $m < $n )); then

    monta_buffer $(( m + 1 ))  # dados complementares do xml

    processa_buffer 'Sincronização'

  else
    printf '\nNão foi necessário sincronizar o db "%s".\n' $db_file
    if (( $m > $n )); then
      printf '\nOBSERVAÇÃO: A quantidade de registros no db é > quantidade de registros no html!\n'
    fi
  fi

fi

currency() {
  LANG='pt_BR' printf "R$ %'d" ${1%.*}
  f=${1#*.}
  if [[ $1 == $f ]] || (( ${#f} == 0 )); then
    printf ',00'
  else
    (( ${#f} == 1 )) && printf ',%s0' $f || printf ',%s' ${f:0:2}
  fi
}

LANG='pt_BR' printf "\n            #registros: %'d\n\n" $m

read n data acumulado dezenas <<< $(sqlite3 -separator ' ' $db_file 'SELECT concurso, data_sorteio, acumulado, GROUP_CONCAT(dezena, " ") FROM concursos NATURAL JOIN dezenas_sorteadas WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')

printf '    Concurso mais recente\n\n'
LANG='pt_BR' printf "                número: %'d\n" $n
printf '       data do sorteio: %s\n\n' "$(long_date $data)"
printf '     dezenas sorteadas:'
printf ' %02d' $dezenas
printf '\n\n'

if (( $acumulado == 1 )); then
  valor=$(sqlite3 $db_file "SELECT valor_acumulado FROM concursos WHERE concurso IS $n")
  [[ $valor ]] && valor=$(currency $valor) || valor='NOT FOUND'
  printf '       valor acumulado: %s\n' "$valor"
else
  read m valor <<< $(sqlite3 -separator ' ' $db_file "SELECT ganhadores_sena, rateio_sena FROM concursos WHERE concurso IS $n")
  printf '   #ganhadores da sena: %d\n' $m
  printf '        rateio da sena: %s\n' "$(currency $valor)"
fi
echo
