#!/bin/bash

declare -r html='D_MEGA.HTM'
declare -r xml='mega.xml'
declare -r db='megasena.sqlite'
declare -r sql='sql/ganhadores.sql'
declare -r xsl='xsl/ganhadores.xsl'

# cria o XML
printf '\n  HTML -- sed & XPath & Tidy --> XML'
sed -r 's/\r//g; s/&nbsp([^;])/\1/g; s/<(td|tr)[^>]+>/<\1>/g' $html | xmllint --html --encode 'UTF-8' --xpath '//table/tr[position()>1]' - | sed '1 i\
<?xml version="1.0" encoding="UTF-8"?><table>
' | sed -r '$ s#^.+$#&\n</table>#' | tidy -quiet -numeric -xml - > $xml
touch -r $html $xml

buffer=$(sed -nr '/^\.import/ s/.+("|\d39)(.+)\1.*/\2/p' $sql)
SEP=$(sed -nr '/^\.separator/ s/.+("|\d39)(.)\1.*/\2/p' $sql)

# monta a lista de "ganhadores"
printf ' -- XSLT --> text'
xsltproc --stringparam SEPARATOR "$SEP" $xsl $xml > $buffer

# regenera e preenche a tabela "ganhadores" do db
printf ' -- SQLite --> DB'
sqlite3 $db ".read $sql"
echo
