# db-megasena

Scripts para criação, atualização e consultas a DB dos concursos da **Mega-Sena** com utilização do <a href="http://www.sqlite.org" title="clique para acessar o website do SQLite">SQLite</a> mais extensões carregáveis, viabilizando analises estatísticas via <a href="http://www.r-project.org/" title="clique para acessar o website do R Statistical Computing...">R Statistical Computing Environment</a> ou similar.

A versão mais recente contempla as modificações dos dados públicos de 06/05/2021, quando deixaram de ser publicados os arquivos das séries históricas dos concursos, porém disponíveis publicamente numa tabela organizada pelos autores para fácil apreciação visual, embora com perda de qualidade da informação.

## Importante

Esse projeto **NÃO TEM POR OBJETIVO A PREVISÃO DE NÚMEROS QUE SERÃO SORTEADOS** em algum concurso, embora disponibilize a tabela de nome **sugestoes** montada com estatísticas fundamentadas no estudo de probabilidades.

Contrariando asneiras divulgadas por espertalhões, todos os scripts "aqui" publicados dão subsídios IRREFUTÁVEIS contra teorias absurdas de vícios e tendências nos concursos da MegaSena.

## Uso Corriqueiro

Após a montagem do projeto conforme documentado na página do wiki sobre <a href="https://github.com/dekassegui/db-megasena/wiki/Depend%C3%AAncias" title="clique para acessar o documento">Dependências</a>:

  1. Execute o script que baixa os dados do site da <a href="http://loterias.caixa.gov.br/wps/portal/loterias/landing/megasena" title="link de download no final da página">Caixa Econômica Federal > Loterias > Mega-Sena</a> para atualizar/criar o DB da MegaSena se necessário:

  > <code>prompt/ <strong>./atualiza-db.sh</strong></code>

  2. Execute o script que gera o documento *megasena.html* contendo estatísticas e inferências:

  > <code>prompt/ <strong>./monta</strong></code>

  3. Execute o script que sugere uma lista de dezenas para o próximo concurso:

  > <code>prompt/ <strong>./scripts/sugestao.sh</strong></code>

  4. Execute os scripts que geram os diagramas de estatísticas do concurso mais recente:

  > <code>prompt/ <strong>R/dia.R && R/plot-both.R</strong></code>


Assista a <a href="http://youtu.be/r2UlHOk1kh8" title="clique aqui para acessar a animação">animação das evoluções das séries temporais das frequências e latências dos números da MegaSena até o concurso 1600</a>.
