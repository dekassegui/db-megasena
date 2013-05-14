#/bin/bash
#
# Cria, reconstrói parcialmente ou sincroniza db SQLite com dados extraídos de
# arquivo html contendo tabela da série temporal dos concursos da mega-sena.

# checa disponibilidade dos comandos utilizados neste script
for comando in sqlite3 unzip wget xmllint xsltproc
do
  if ! 1>/dev/null which ${comando}
  then
    [[ $comando == xmllint ]] && pacote='libxml2-utils' || pacote=$comando
    echo "Comando '$comando' não encontrado. Instale o pacote '$pacote'."
    exit
  fi
done

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
tz=$(date +%Z)

# formata indiferentemente ao separador de campos, data no formato
# yyyy.mm.dd ou dd.mm.yyyy como data no formato "data por extenso"
long_date() {
  TZ=$tz date -d $(full_date $1) '+%A, %d de %B de %Y'
}

unixtime() {
  TZ=$tz date -d $(full_date $1) '+%s'
}

declare -r html='D_MEGA.HTM'   # filename do html

xpath() {
  xmllint --html --xpath "$1" $html
}

# expressão XPath p/obter o número de concursos no html
declare -r count_n_html='count(//table/tr)-1'

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

  # extrai a data do último concurso no html :: 2ª coluna da última linha
  data=$(xpath '//table/tr[last()]/td[2]/text()')

  # se a data presumida do concurso mais recente for posterior à data do
  # último concurso no html então tentará obter o html remoto atualizado
  (( $(unixtime $F) > $(unixtime $data) )) && force_update=true

fi

# DOWNLOAD DO ARQUIVO HTML

declare -r db_file='megasena.sqlite' # nome do arquivo container do db SQLite

if [[ $force_update == true ]] || [[ ! -e $html ]]; then

  echo -e "\nTentando obter '$html' atualizado do website.\n"

  timestamp() {
    stat -c %Y "$1" # data de modificação do arquivo em segundos da era unix
  }

  if [[ -e $html ]]; then
    declare -i tm=$(timestamp $html)
    declare -i n=$(xpath $count_n_html)
  fi

  # endereço do zipfile remoto contendo o arquivo html
  url='http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_megase.zip'

  # realiza o download do zipfile remoto se mais recente que o localmente
  # disponível ou se ainda não existir localmente e então extrai o html
  # se mais recente que o previamente existente ou se ainda não existir,
  # tal que ambos procedimentos sobrescrevem arquivos
  wget --timestamping $url && unzip -q -o -u $(basename $url) $html

  # verifica a disponibilidade do arquivo html no diretório corrente no caso
  # do arquivo não existir previamente e o download ser mal sucedido
  if [[ ! -e $html ]]; then
    echo -e "\nErro: Arquivo '$html' não disponível e o download foi mal sucedido.\n"
    exit 1
  # checa se a reconstrução do db pré-existente não foi requerida e se o html
  # pré-existente foi atualizado e se seu número de concursos não foi alterado
  elif [[ -e $db_file ]] && [[ $rebuild_db == false ]] \
      && [[ $tm ]] && (( $tm <= $(timestamp $html) )) \
      && (( $n == $(xpath $count_n_html) ))
  then
    # obtêm o registro correspondente no db
    db_rec=$(sqlite3 -separator ' ' $db_file "SELECT * FROM concursos WHERE concurso == $n")
    # se os últimos registros do db e do html não forem iguais então
    # força sincronização do db eliminando seu último registro
    if [[ $db_rec ]]; then
      # extrai o último registro do html e formata como se obtido via SQLite
      xml_rec=$(xpath '//table/tr[last()]/td' | sed 's|<td>\(.*\)</td>|\1|; s|</td><td>| |g; s|\([0-9]\{2\}\)/\([0-9]\{2\}\)/\([0-9]\{4\}\)|\3-\2-\1|; s/\.//g; y/,/./; s/\.\([0-9]\)0/.\1/g; s/ 0\([1-9]\)/ \1/g' | sed 's/SIM/1/; t; s/N.*O/0/')
      if [[ $xml_rec != $db_rec ]]; then
        sqlite3 $db_file "DELETE FROM concursos WHERE concurso == $n"
      fi
    fi
  fi

fi

# extrai a data do último concurso no html mais recente
data=$(xpath '//table/tr[last()]/td[2]/text()')
echo -e "\nData do concurso mais recente em '$html':" $(long_date $data)'.'

n=$(xpath $count_n_html)  # número de concursos no html

# MANUTENÇÃO DO DB

declare -r buffer='/tmp/buffer.sql'  # filename do buffer de comandos sql

# expressão SQL p/obter o número de registros na tabela 'concursos' do db
declare -r count_n_db='SELECT count(concurso) FROM concursos'

monta_buffer() {
  (( $1 )) && par="--param OFFSET $1 ./xsl/sql-partial.xsl" || par='./xsl/sql-full.xsl'
  printf '\n HTML ---( XSLT )--> Text'
  # monta o buffer de comandos sql transformando o conteúdo do html
  xsltproc --html $par $html > $buffer
}

processa_buffer() {
  local op=( 'Criação' 'Reconstrução parcial' 'Sincronização' )
  printf ' ---( SQLite )---> DB'
  if sqlite3 $db_file ".read $buffer"
  then
    # número de registros na tabela 'concursos' do db
    (( m=$(sqlite3 $db_file "$count_n_db") ))
    # compara os números de registros do html e do db
    (( $n == $m )) && status='bem' || status='mal'
    printf "\n\n%s do db '%s' foi %s sucedida.\n" "${op[${1:-2}]}" $db_file $status
  fi
}

if [[ $rebuild_db == true ]] || [[ ! -e $db_file ]]; then

  # CRIAÇÃO OU RECONSTRUÇÃO PARCIAL DO DB

  monta_buffer  # usando todos os dados do html

  processa_buffer $( [[ -e $db_file ]] && echo 1 || echo 0 )

else  # SINCRONIZAÇÃO DO DB

  (( m=$(sqlite3 $db_file "$count_n_db") ))

  # sincroniza o db somente se o número de registros na tabela
  # 'concursos' do db é menor que o número de concursos no html
  if (( $m < $n )); then

    monta_buffer $(( m + 1 )) # usando os dados complementares do html

    processa_buffer

  else
    printf "\nNão foi necessário sincronizar o db '%s'.\n" $db_file
  fi

fi

echo -e "\nTabela 'concursos':\n\n  #registros = ${m}\n"

read n data m valor dezenas <<< $(sqlite3 -separator ' ' $db_file 'SELECT concurso, data_sorteio, acumulado, valor_acumulado, GROUP_CONCAT(SUBSTR(dezena+100,2)," ") FROM concursos NATURAL JOIN dezenas_sorteadas WHERE concurso IS (SELECT MAX(concurso) FROM concursos)')
echo -e 'Concurso mais recente\n'
echo ' número do concurso:' $n
echo '    data do sorteio:' $(long_date $data)
echo -e "  dezenas sorteadas: ${dezenas}\n"

# ecoa o valor acumulado no formato de valor monetário do Brasil
(( $m )) && printf 'Valor acumulado p/próximo concurso = R$ %s\n\n' $(echo $valor | sed 'y/./,/;:×;s/\B[0-9]\{3\}\>/.&/;t×;s/,[0-9]$/&0/')
