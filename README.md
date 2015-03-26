# db-megasena

Scripts para criação, atualização e consultas a DB dos concursos da MegaSena com utilização do <a href="http://www.sqlite.org" title="clique para acessar o website do SQLite">SQLite</a> mais extensões carregáveis, viabilizando analises estatísticas via <a href="http://www.r-project.org/" title="clique para acessar o website do R Statistical Computing...">R Statistical Computing Environment</a> ou similar.

A versão mais recente contempla as modificações dos dados públicos de 04/09/2014.

## Uso Corriqueiro

Após a montagem do projeto conforme documentado na página do wiki sobre <a href="https://github.com/dekassegui/db-megasena/wiki/Depend%C3%AAncias" title="clique para acessar o documento">Dependências</a>:

  1. Execute o script que baixa os dados do site da <a href="http://www1.caixa.gov.br/loterias/loterias/megasena/megasena_resultado.asp" title="clique aqui para acessar o website da Caixa Econômica Federal">Caixa Econômica Federal > Loterias</a> para atualizar/criar o DB da MegaSena se necessário:

  <code>prompt/ <strong>./atualiza-db</strong></code>

  2. Execute o script que gera o documento *megasena.html* contendo estatísticas e inferências:

   <code>prompt/ <strong>./monta</strong></code>

  3. Execute o script que sugere uma lista de dezenas a apostar no próximo concurso:

   <code>prompt/ <strong>./scripts/sugestao.sh</strong></code>


Assista a <a href="http://youtu.be/r2UlHOk1kh8" title="clique aqui para acessar a animação">animação das evoluções das séries temporais das frequências e latências dos números da MegaSena até o concurso 1600</a>.
