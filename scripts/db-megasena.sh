#/bin/bash
#
# Cria, reconstrói parcialmente ou sincroniza db SQLite com dados extraídos de
# arquivo html contendo tabela da série temporal dos concursos da mega-sena.

<<'VOID_CHECKUP_REQUISITOS'
# checa disponibilidade dos comandos utilizados neste script
for comando in sqlite3 unzip wget xmllint xsltproc
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
    printf '.\n\nDisponibilize-o instalando o pacote:\n\n\t'
  else
    printf '%d aplicativos que não estão disponíveis' ${#lista[*]}
    printf '.\n\nDisponibilize-os instalando os pacotes:\n\n\t'
  fi
  printf '   %s' ${lista[*]}
  printf '\n\n'
  exit 1
fi
VOID_CHECKUP_REQUISITOS

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
  documento html contendo tabela da série temporal dos concursos da megasena.\n
  O download do arquivo em compressão que contém o documento html, disponível
  no web site da Caixa Econômica Federal, ocorrerá sempre que:\n
   (1) o arquivo não existir localmente, ou\n
   (2) o arquivo existir localmente e sua data de criação/modificação é
       anterior à data de criação/modificação do arquivo remoto tal que
       a data do último concurso listado no documento html é anterior à
       data presumida do sorteio mais recentemente realizado.\n
  Uso:
        $(basename $0) [--force-update|-u] [--rebuild-db|-r] [--help|-h]\n
  --force-update, -u   Força o download desconsiderando conteúdo do documento
                       preexistente e data presumida de sorteio mais recente.
  --rebuild-db, -r     Reconstrói parcialmente o db SQLite, regenerando tabelas,
                       views, índices, triggers e preenche seu conteúdo.
  --help, -h           Apresenta este resumo e finaliza a execução do script.\n"
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

shopt -s expand_aliases  # habilita expansão de alias
alias Printf="LANG='pt_BR' printf"

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

sqlite() {
  if [[ $1 == '-separator' ]]; then
    local sep="$2"
    shift 2
    sqlite3 -separator "$sep" $db_file "$*"
  else
    sqlite3 $db_file "$*"
  fi
}

# extrai parâmetro de meta-command do SQLite de script arbitrário
value_of() {
  sed -nr "/^\.$1/ { s/.+(\d34|\d39)(.+)\1.*/\2/p; q }" $2
}

declare -r html='d_mega.htm'              # html baixado do website
declare -r xml='MEGA.XML'                 # xml baseado no html
declare -r db_file='megasena.sqlite'      # container do db SQLite
declare -r db_renew='sql/db-renew.sql'    # script para criar/regenerar o db
declare -r data_load='sql/data-load.sql'  # script de importação de dados do db
declare -r xsl='xsl/list-builder.xsl'     # xsl gerador dos dados do db
declare -r xox='sql/ganhadores.sql'       # script para atualizar "ganhadores"
declare -r oxo='xsl/ganhadores.xsl'       # xsl gerador de dados de "ganhadores"
declare -r lst='xsl/localidades.xsl'      # xsl listador de localidades de "ganhadores"

# endereço do zipfile remoto container do arquivo html
declare -r url='http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_megase.zip'

declare -r zipfile=${url##*/}   # equivalente a basename $url

# expressão XPath p/obter a quantidade de registros no xml
declare -r count_n_xml='count(//table/tr[count(td)=21])'

declare -r data_ultimo_concurso='//table/tr[count(td)=21][last()]/td[2]/text()'

declare -r numero_ultimo_concurso='//table/tr[count(td)=21][last()]/td[1]/text()'

# sql p/obter a quantidade de registros na tabela 'concursos'
declare -r count_n_db='SELECT COUNT(concurso) FROM concursos'

# HABILITAÇÃO DO DOWNLOAD DO ZIPFILE CONTAINER DO HTML

if [[ $force_update == false ]] && [[ -e $xml ]]; then

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

  # se a data presumida do sorteio mais recente for posterior à data
  # do último registro no xml então força a atualização do zipfile
  if (( $(unixtime $F) > $(unixtime $data) )); then
    force_update=true
  fi

fi

# DOWNLOAD DO ZIPFILE CONTAINER DO HTML

if [[ $force_update == true ]] || [[ ! -e $xml ]]; then

  # se existe zipfile então preserva seu timestamp
  [[ -e $zipfile ]] && declare -i tm=$(timestamp $zipfile)

  printf '\nRequisitando "%s" ao website.\n' $zipfile

  # realiza o download do zipfile remoto se mais recente que o localmente
  # disponível ou se ainda não existir
  wget -o wget.log --no-cache --timestamping $url

  # termina a execução do script se o zipfile não está disponível
  if [[ ! -e $zipfile ]]; then
    printf '\nErro: Arquivo "%s" não está disponível.\n\n' $zipfile
    exit 1
  fi

  printf '\nInformação: "%s" ' $zipfile
  if [[ $tm ]]; then
    (( $tm < $(timestamp $zipfile) )) || printf 'não '
    printf 'foi atualizado.\n'
  else
    printf 'está disponível.\n'
  fi

  unzip -q -o -u -C -L -d /tmp $zipfile $html   # extrai o html temporariamente

  [[ -e $xml ]] && tm=$(timestamp $xml) || unset -v tm

  # MONTAGEM DO XML

  code=$(file -bi /tmp/$html | sed -ru "s/^.+=//" | tr [:lower:] [:upper:])
  if [[ $code != 'UTF-8' ]]; then
    iconv --from-code $code --to-code 'UTF-8' /tmp/$html > /tmp/$html.utf8
    touch -r /tmp/$html /tmp/$html.utf8
    cp --preserve /tmp/$html.utf8 /tmp/$html
    rm -f /tmp/$html.utf8
  fi
  sed -r -f scripts/xml.sed /tmp/$html > $xml
  
  touch -r /tmp/$html $xml    # timestamp do xml <- timestamp do html

  if [[ $tm ]] && (( ! $tm < $(timestamp $xml) )); then
    # se o db existe e não foi requisitada sua reconstrução
    if [[ -e $db_file ]] && [[ $rebuild_db == false ]]; then
      k=$(xpath $count_n_xml)
      # se a quantidade de registros no db é igual a quantidade de
      # registros no xml recém criado ou atualizado
      if (( $(sqlite $count_n_db) == $k )); then
        # extrai o separador de campos declarado no script
        SEP=$(value_of 'separator' $data_load)
        # obtêm o último registro no db
        dbrec=$(sqlite -separator "$SEP" 'SELECT * FROM concursos WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')
        # extrai o último registro do xml e formata como se obtido via SQLite
        xmlrec=$(xsltproc --param OFFSET $k --stringparam SEPARATOR "$SEP" $xsl $xml | sed -r 's/([^0-9.-])0+([1-9])/\1\2/g; s/(\.[0-9])0+/\1/g; s/NULL//g')
        # se o último registro de concurso no db for igual ao último registro
        # de concurso no xml então prepara o teste da lista de localidades dos
        # ganhadores montada pelo db e da lista de localidades dos ganhadores
        # extraída do xml via XSLT
        if [[ $dbrec == $xmlrec ]]; then
          dbrec=$(sqlite 'SELECT GROUP_CONCAT(IFNULL(cidade, "") || "::" || IFNULL(uf, ""), "|") FROM ganhadores WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')
          k=$(xpath $numero_ultimo_concurso)
          xmlrec=$(xsltproc --stringparam FIELDS_SEPARATOR "::" --stringparam RECORDS_SEPARATOR "|" --param CONCURSO $k $lst $xml)
        fi
        # se as strings não são iguais então força a sincronização do db
        # eliminando seu último registro
        if [[ $dbrec != $xmlrec ]]; then
          sqlite 'DELETE FROM concursos WHERE concurso IS (SELECT MAX(concurso) FROM concursos)'
        fi
      fi
    fi
  fi

fi

data=$(date -r $xml '+%Y-%m-%d')
printf '\nArquivo "%s" gerado em: %s.\n\n' $html "$(long_date $data)"
n=$(xpath $count_n_xml)
k=$(xpath $numero_ultimo_concurso)
data=$(xpath $data_ultimo_concurso)
Printf "            #registros: %'d\n\n" $n
printf '    Concurso mais recente\n\n'
Printf "                número: %'d\n" $k
printf '       data do sorteio: %s\n' "$(long_date $data)"

# MANUTENÇÃO DO DB

monta_buffer() {
  printf '\n\tXML ---( XSLT )--> Text'
  # extrai o path do buffer declarado no script
  local buffer=$(value_of 'import' $data_load)
  # extrai o separador de campos declarado no script
  local SEP=$(value_of 'separator' $data_load)
  # monta o buffer de preenchimento da tabela "concursos"
  xsltproc --param OFFSET $1 --stringparam SEPARATOR "$SEP" $xsl $xml > $buffer
  # obtem parâmetros e monta o buffer de preenchimento da tabela "ganhadores"
  buffer=$(value_of 'import'  $xox)
  SEP=$(value_of 'separator'  $xox)
  xsltproc --stringparam SEPARATOR "$SEP" $oxo $xml > $buffer
}

processa_buffer() {
  printf ' ---( SQLite )---> DB'
  # preenche ou completa a tabela "concursos"
  sqlite ".read $data_load" > /dev/null
  # esvazia a tabela "ganhadores" se não houve criação/regeneração do db
  [[ $2 == true ]] && sqlite 'DELETE FROM ganhadores'
  # preenche a tabela "ganhadores"
  sqlite ".read '$xox'" > /dev/null
  # compara as quantidades de registros do xml e do db
  m=$(sqlite $count_n_db)
  (( $n == $m )) && local status='bem' || local status='mal'
  printf '\n\n%s do db "%s" foi %s sucedida.\n' $1 $db_file $status
}

if [[ $rebuild_db == true ]] || [[ ! -e $db_file ]]; then

  # CRIAÇÃO OU RECONSTRUÇÃO PARCIAL DO DB

  [[ -e $db_file ]] && operation='Reconstrução' || operation='Criação'

  sqlite ".read $db_renew" > /dev/null

  monta_buffer 1  # todos os dados do xml

  processa_buffer $operation false

else  # ATUALIZAÇÃO DO DB

  m=$(sqlite $count_n_db)

  # atualiza o db somente se a quantidade de registros no db
  # é estritamente menor que a quantidade de registros no xml
  if (( $m < $n )); then

    monta_buffer $(( m + 1 ))  # dados complementares do xml

    processa_buffer 'Sincronização' true

  else
    printf '\nNão foi necessário sincronizar o db "%s".\n' $db_file
    if (( $m > $n )); then
      printf '\nObservação: Quantidade de registros no db > quantidade de registros no xml.\n'
    fi
  fi

fi

currency() {
  Printf "R$ %'d" ${1%.*}
  local f=${1#*.}
  if [[ $1 == $f ]] || (( ${#f} == 0 )); then
    printf ',00'
  else
    (( ${#f} == 1 )) && printf ',%s0' $f || printf ',%s' ${f:0:2}
  fi
}

Printf "\n            #registros: %'d\n\n" $m

read n data acumulado dezenas <<< $(sqlite -separator ' ' 'SELECT concurso, data_sorteio, acumulado, GROUP_CONCAT(dezena, " ") FROM concursos NATURAL JOIN dezenas_sorteadas WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')

printf '    Concurso mais recente\n\n'
Printf "                número: %'d\n" $n
printf '       data do sorteio: %s\n\n' "$(long_date $data)"
printf '     dezenas sorteadas: %02d %02d %02d %02d %02d %02d\n\n' $dezenas

if (( $acumulado == 1 )); then
  valor=$(sqlite "SELECT valor_acumulado FROM concursos WHERE concurso IS $n")
  [[ $valor ]] && valor=$(currency $valor) || valor='NOT FOUND'
  printf '       valor acumulado: %s\n' "$valor"
else
  read m valor <<< $(sqlite -separator ' ' "SELECT ganhadores_sena, rateio_sena FROM concursos WHERE concurso IS $n")
  printf '   #ganhadores da sena: %d\n' $m
  printf '        rateio da sena: %s\n' "$(currency $valor)"
fi
echo
