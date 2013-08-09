#!/bin/bash

declare -r html='megasena.html'
declare -r css_file='css/frequencias.css'

long_date () {
  TZ=$(date '+%Z') date -d $1 '+%d&nbsp;de&nbsp;%B&nbsp;de&nbsp;%Y'
}

currency () {
  echo $1 | sed 'y/./,/;:×;s/\B[0-9]\{3\}\>/.&/;t×;s/,[0-9]$/&0/'
}

query_db () {
  sqlite3 -init ./sqlite/onload megasena.sqlite "$@"
}

n=$(sqlite3 megasena.sqlite "SELECT count(concurso) FROM concursos")
num_concurso=$n

cat > $html <<DOC
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="pt_BR">
<head>
<title>Análise dos Números Sorteados nos $n Concursos da Mega-sena</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="authorship" content="@sergio_cps" />
<link rel="stylesheet" type="text/css" media="screen" href="css/megasena.css" />
<link rel="stylesheet" type="text/css" media="screen" href="css/frequencias.css" />
<script type="text/javascript" src="js/mootools-core-1.4.5-full-compat-yc.js"></script>
<script type="text/javascript" src="js/mootools-more-1.4.0.1.js"></script>
<script type="text/javascript" src="js/megasena.js"></script>
</head>
<body>
  <div id="conteudo">
    <h1>análise dos números sorteados<br/>nos <em>$n</em> concursos da mega-sena</h1>
    <table class="boleto">
      <caption>frequências e latências das dezenas</caption>
      <tfoot>
        <tr>
          <td colspan="10"><span>Observação:</span><span>Quanto mais intensa a cor de fundo da célula, maior é a frequência da dezena que contém e quanto<br/> mais intensa a cor dos dígitos da dezena, mais recentemente essa dezena foi sorteada.</span></td>
        </tr>
      </tfoot>
      <tbody>
DOC

query_db "
DROP TABLE IF EXISTS view_to_build_html;
CREATE TABLE view_to_build_html
AS SELECT
    dezena, frequencia, latencia,
    (latencia+max_latencia/2)*100.0/frequencia/frequencia AS ifrap,
    0.2+0.8*((frequencia-min_frequencia)/amplitude) AS alfa,
    0.1+0.9*(1-POWER(latencia*1.0/max_latencia, exponent)) AS beta
   FROM info_dezenas,
     (SELECT
       MIN(frequencia)*1.0 AS min_frequencia,
       MAX(frequencia)-MIN(frequencia) AS amplitude,
       MAX(latencia) AS max_latencia,
       5/12.0 AS exponent
      FROM info_dezenas);"

[[ -e $css_file ]] && rm -f $css_file
touch $css_file

for (( dezena=1, row=1; row <= 6; row++ ))
do
  cat >> $html <<DOC
        <tr>
DOC
  for (( column=1; column <= 10; column++, dezena++ ))
  do
    read frequencia latencia ifrap alfa beta <<< $(query_db "
      SELECT frequencia, latencia, round(ifrap,5), alfa, beta
      FROM view_to_build_html
      WHERE dezena == $dezena")
    printf -v dec '%02d' $dezena
    classname="dezena$dec"
    cat >> $html <<DOC
    <td class="$classname" title="dezena $dec&lt;br/&gt;IFR = ${ifrap} :: foi sorteada em $frequencia concursos e pela última vez há $latencia concursos">$dec</td>
DOC
    [[ $beta == '1.0' ]] && cor='0' || cor='18'
    cat >> $css_file <<CSS_DOC
td.$classname {
  background-color: rgba(240,80,0,$alfa);
  color: rgba($cor,$cor,$cor,$beta);
}
CSS_DOC
  done
  cat >> $html <<DOC
        </tr>
DOC
done

query_db 'DROP TABLE IF EXISTS view_to_build_html'

cat >> $html <<DOC
      </tbody>
    </table>
DOC

# cria gráfico das frequências e latências
./R/plot-both.r

png_compress() {
  local tmpfile=/tmp/saida.png
  # renderiza texto sobre o número do concurso no canto inferior direito e
  # converte a imagem PNG de true-color para indexed 256 colors
  1>/dev/null which convert && convert -pointsize 11 -fill '#778899' -gravity SouthEast -draw "text 1,1 'Concurso $num_concurso da MegaSena.'" -quality 0 +dither -colors 256 "$1" $tmpfile
  # compressão default da imagem resultante
  1>/dev/null which pngcrush && pngcrush -q $tmpfile "$1"
}

png_compress "img/both-$n.png"
cat >> $html <<DOC
    <h2>Diagramas das frequências e latências</h2>
    <div>
      <img src="img/both-$n.png" alt="frequências e latências" height="558" width="1300" />
    </div>
DOC

probability='5%'
critical='77.931'
read n chi status <<< $(sqlite3 -separator ' ' megasena.sqlite "SELECT n, round(chi,3), (chi >= $critical) FROM (SELECT n, sum(desvio*desvio/esperanca) AS chi FROM (SELECT n, esperanca, (frequencia-esperanca) AS desvio FROM info_dezenas, (SELECT n, n/10.0 AS esperanca FROM (SELECT count(concurso) AS n from concursos))))")
R/plot-chi-59.r $chi
png_compress 'img/chi-59.png'
cat >> $html <<DOC
    <h2>Teste de Aderência <span>χ²</span></h2>
    <div>
      <p title="&lt;strong&gt;hipótese nula&lt;/strong&gt; :: ao longo do tempo as dezenas são sorteadas o mesmo número de vezes">H₀: <span>As dezenas têm distribuição uniforme.</span></p>
      <p title="&lt;strong&gt;hipótese alternativa&lt;/strong&gt; ::  ao longo do tempo as dezenas não são sorteadas o mesmo número de vezes">H₁: <span>As dezenas não têm distribuição uniforme.</span></p>
      <p><img src="img/chi-59.png" alt="distribuição chi-quadrado" width="640" height="480" /></p>
      <p><span class="chi">χ²</span> amostral = <em>$chi</em></p>
      <p>gl=<em>59</em></p>
      <p>Para X ∼ <span class="chi">χ²</span> , gl=<em>59</em> temos: P(X ≥ <em>$critical</em>) = <em>$probability</em></p>
      <p>portanto: P(X ≥ <em>$chi</em>) $( [ $status -ne 1 ] && echo '&gt;' || echo '&lt;' ) <em>$probability</em>.</p>
      <p>Conclusão: <span>“Ao nível de significância de $probability $( [ $status -ne 1 ] && echo 'não ' )rejeitamos a hipótese nula”.</span></p>
    </div>
DOC

tmp='/tmp/buffer.txt'
# monta e armazena a máscara de incidência das dezenas de cada concurso que
# contém ao menos uma sequência de duas dezenas consecutivas
query_db 'SELECT zeropad(concurso,4), MASK60(dezenas) AS mask FROM dezenas_juntadas WHERE mask LIKE "%11%"' | sed '/^$/d' > $tmp
cat >> $html <<DOC
    <h2>Sequências de dezenas consecutivas</h2>
    <ul>
    <li>Em <em>$(sed -n '$=' $tmp)</em> concursos ocorreram sequências de <em>2+</em> (duas ou mais) dezenas.</li>
    <li>Em <em>$(cut -d' ' -f2 $tmp | grep -Ec '111+')</em> concursos ocorreram sequências de <em>3+</em> dezenas.</li>
    <li>Em <em>$(cut -d' ' -f2 $tmp | grep -Ec '1111+')</em> concursos ocorreram sequências de <em>4+</em> dezenas.</li>
    <li>Em <em>$(cut -d' ' -f2 $tmp | grep -Ec '11+.+11+')</em> concursos ocorreram <em>2</em> sequências distintas de <em>2+</em> dezenas.</li>
DOC

cat >> $html <<DOC
    <li>Frequências de sequências de 2 dezenas:
      <ul>
DOC
query_db "select zeropad(frequencia,2), group_concat(dupla, ' ')
from (
  SELECT ' ('||zeropad(dezena,2)||'-'||zeropad(dezena+1,2)||') ' AS dupla, count(concurso) AS frequencia
  FROM dezenas_juntadas, (
    SELECT dezena, ((1 << dezena-1) | (1 << dezena)) AS mask
    FROM (
      SELECT DISTINCT dezena FROM dezenas_sorteadas WHERE dezena < 60
    )
  )
  WHERE (dezenas & mask) == mask
  GROUP BY dezena
) GROUP BY frequencia ORDER BY frequencia desc" | sed '/^$/d' | while read f m
do
  cat >> $html <<DOC
      <li>$f:<em>$m</em></li>
DOC
done
cat >> $html <<DOC
      </ul>
    </li>
DOC

cat >> $html <<DOC
    <li>Dezenas consecutivas recentes:
      <ul>
DOC
while read concurso mask
do
  unset lista
  while IFS=':' read offset submask
  do
    for (( n=offset+${#submask}; ++offset <= n; )); do
      lista=( ${lista[@]} $offset )
    done
  done < <(echo $mask | grep -Eob '11+')
  cat >> $html <<DOC
      <li>Concurso <em>$concurso</em>: $(printf ' <em>%02d</em>' ${lista[@]}).</li>
DOC
done < <(tail -n 10 $tmp)
cat >> $html <<DOC
      </ul>
    </li>
    </ul>
DOC

query_db 'SELECT replace(GROUP_CONCAT(bitstatus(dezenas, dezena-1), ""),"0"," ") FROM (SELECT DISTINCT dezena FROM dezenas_sorteadas), dezenas_juntadas GROUP BY dezena' > $tmp
cat >> $html <<DOC
    <h2>Reincidência de dezenas em concursos consecutivos</h2>
    <ul>
    <li>Ocorreram <em>$(grep -Eo '\b1{2,}\b' $tmp | wc -l)</em> reincidências de todas as dezenas em <em>2+</em> concursos consecutivos.</li>
DOC
for (( j=2; j<=4; j++ ))
do
  lista=$(grep -Eno "\b1{$j}\b" $tmp | cut -d ':' -f 1 | uniq -c | sort -nr | head -n 10 | sed -r 's/^.+\s//')
  cat >> $html <<DOC
    <li>Dezenas mais reincidentes em <em>$j</em> concursos consecutivos: $(printf ' <em>%02d</em>' $lista).</li>
DOC
done

n=20
lista=$(query_db "SELECT '<em>'||zeropad(dezena,2)||'</em>'
FROM (
  SELECT dezena, GROUP_CONCAT(bitstatus(dezenas, dezena-1),'') AS mask
  FROM (
    SELECT DISTINCT dezena FROM dezenas_sorteadas
  ), (
    SELECT dezenas
    FROM dezenas_juntadas
    WHERE concurso >= (SELECT MAX(concurso)-$n+1 FROM concursos)
  )
  GROUP BY dezena HAVING mask LIKE '%11%'
)
ORDER BY REVERSE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(mask,'1111','AAAA'),'111','AAA'),'11','AA'),'1','0'),'A','1')) DESC")
[[ $lista ]] && cat >> $html <<DOC
    <li>Dezenas reincidentes nos <em>$n</em> últimos concursos: $lista.</li>
DOC
cat >> $html <<DOC
    </ul>
DOC

read n m p desvio <<< $(query_db 'SELECT n, m, replace(round(p*100,3),".",","), replace(round(d*100,3),".",",") FROM (SELECT n, m, p, power(p*q/n, .5) AS d FROM (SELECT n, m, p, 1-p AS q FROM (SELECT m, n, m/1.0/n AS p FROM (SELECT sum(acumulado) AS m, count(acumulado) AS n FROM concursos))))')
cat >> $html <<DOC
    <h2>Concursos acumulados</h2>
    <ul>
    <li>A mega-sena acumulou em <em>$m</em> concursos dos <em>$n</em> realizados, portanto estimamos: <span>Probabilidade de um concurso acumular = <em>${p}%</em>&nbsp;±&nbsp;<em>${desvio}%</em>.</span></li>
DOC

sqlite3 megasena.sqlite "SELECT replace(replace(group_concat(acumulado, ''), '01', '0'||X'0A'||'1'), '10', '1'||X'0A'||'0') FROM concursos" | sort | uniq -c | sed -r 's/^\s*//g' | while read f m
                 do
                   echo ${m:0:1} ${#m} $f
                 done > '/tmp/frequencias.dat'

read n media desvio f m <<< $(sqlite3 -init ./sqlite/workaround megasena.sqlite "CREATE TEMP VIEW IF NOT EXISTS acc1 AS SELECT dim, freq FROM acc WHERE tipo IS 1;
SELECT N, replace(round(media,3),'.',','), replace(round(desvio,3),'.',','), f, m
FROM (
  SELECT
    N, f, m, media,
    -- cálculo do desvio padrão via frequências de classes e média ponderada
    power(SUM(freq*power(dim-media, 2))/N, .5) AS desvio
  FROM (
    SELECT
      N, f, m,
      SUM(dim*freq)*1.0/N AS media -- média aritimética ponderada
    FROM (
      SELECT sum(freq) AS N FROM acc1
    ), (
      SELECT (SELECT max(dim) FROM acc1) AS m, freq AS f FROM acc1 WHERE dim IS m
    ), acc1
  ), acc1);")
cat >> $html <<DOC
    <li>Com base nos <em>$n</em> períodos distintos nos quais acumulou por <em>1+</em> concursos consecutivos, estimamos: <span>Média das amplitudes de períodos cumulativos = <em>$media</em>&nbsp;±&nbsp;<em>$desvio</em> concursos.</span></li>
    <li>A maior amplitude observada; <em>$m</em> concursos acumulados consecutivos, ocorreu por <em>$f</em> vêzes.</li>
DOC

m=$(sqlite3 megasena.sqlite 'SELECT (SELECT max(concurso) FROM concursos) -  max(concurso) FROM concursos WHERE not acumulado');
(( m > 0 )) && cat >> $html <<DOC
    <li>A megasena está acumulada há <em>$m</em> concursos.</li>
DOC

cat >> $html <<DOC
    </ul>
DOC

critical='3.841'
read chi status <<< $(query_db "CREATE TEMP TABLE t2 AS
  SELECT concurso FROM dezenas_juntadas WHERE mask60(dezenas) LIKE '%11%';
SELECT round(chi,3), (chi >= $critical)
FROM (
  SELECT power(fa-ea,2)/ea + power(fb-eb,2)/eb + power(fc-ec,2)/ec + power(fd-ed,2)/ed AS chi
  FROM (
    SELECT
      (fa+fc)*(fa+fb)/total AS ea,
      (fb+fd)*(fa+fb)/total AS eb,
      (fa+fc)*(fc+fd)/total AS ec,
      (fb+fd)*(fc+fd)/total AS ed,
      fa, fb, fc, fd
    FROM (
      SELECT count(*) AS fa FROM concursos WHERE acumulado and concurso in t2
    ), (
      SELECT count(*) AS fb FROM concursos WHERE acumulado and not concurso in t2
    ), (
      SELECT count(*) AS fc FROM concursos WHERE not acumulado and concurso in t2
    ), (
      SELECT count(*) AS fd FROM concursos WHERE not acumulado and not concurso in
        t2
    ), (
      SELECT cast(count(*) AS real) AS total FROM concursos
    )
  )
)")
R/plot-chi-one.r $chi
png_compress 'img/chi-one.png'
cat >> $html <<DOC
    <h2>Teste de Independência “Acumular x Sequência de dezenas consecutivas”</h2>
    <div>
      <p title="&lt;strong&gt;hipótese nula&lt;/strong&gt; :: concursos acumulam indiferentemente ao sorteio de dezenas consecutivas">H₀: <span>Os eventos são independentes entre si.</span></p>
      <p title="&lt;strong&gt;hipótese alternativa&lt;/strong&gt; :: quando são sorteadas dezenas consecutivas quase certamente os concursos acumulam">H₁: <span>Os eventos não são independentes entre si.</span></p>
      <p><img src="img/chi-one.png" alt="distribuição chi-quadrado" width="640" height="480" /></p>
      <p><span class="chi">χ²</span> amostral = <em>$chi</em></p>
      <p>gl = <em>1</em></p>
      <p>Para X ∼ <span class="chi">χ²</span> , gl=1 temos: P(X ≥ <em>$critical</em>) = <em>$probability</em></p>
      <p>portanto: P(X ≥ <em>$chi</em>) $( [ $status -ne 1 ] && echo '&gt;' || echo '&lt;' ) <em>$probability</em>.</p>
      <p>Conclusão: <span>“Ao nível de significância de $probability $( [ $status -ne 1 ] && echo 'não ' )rejeitamos a hipótese nula”.</span></p>
    </div>
DOC

cat >> $html <<DOC
  </div>
  <div id="footer">
    <p>
      <span class="kandji">
        <span class="displace">opensource by <span lang="ja">安藤</span></span>
      </span>
    </p>
  </div>
</body>
</html>
DOC
