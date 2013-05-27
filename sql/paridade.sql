-- tabela das quantidades de dezenas pares sorteadas em cada concurso
CREATE TEMP TABLE paridades AS
  SELECT concurso, 6 - SUM(dezena % 2) AS paridade
  FROM dezenas_sorteadas
  GROUP BY concurso;

-- tabela das frequencias das paridades
CREATE TEMP TABLE frequencias_paridades AS
  SELECT paridade, COUNT(paridade) AS frequencia
  FROM paridades
  GROUP BY paridade;
