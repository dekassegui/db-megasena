-- Cria ou recria todas as tabelas, views, índices e triggers.
BEGIN TRANSACTION;
PRAGMA legacy_file_format = ON;
DROP TABLE IF EXISTS concursos;
CREATE TABLE concursos (
  -- tabela obtida por conversão de documento HTML que contém
  -- a série temporal completa dos concursos da megasena
  concurso                INTEGER PRIMARY KEY,
  data_sorteio            DATETIME NOT NULL ON CONFLICT ABORT, -- yyyy-mm-dd
  dezena1                 INTEGER CHECK (dezena1 BETWEEN 1 AND 60),
  dezena2                 INTEGER CHECK (dezena2 BETWEEN 1 AND 60),
  dezena3                 INTEGER CHECK (dezena3 BETWEEN 1 AND 60),
  dezena4                 INTEGER CHECK (dezena4 BETWEEN 1 AND 60),
  dezena5                 INTEGER CHECK (dezena5 BETWEEN 1 AND 60),
  dezena6                 INTEGER CHECK (dezena6 BETWEEN 1 AND 60),
  ganhadores_sena         INTEGER,
  ganhadores_quina        INTEGER,
  ganhadores_quadra       INTEGER,
  rateio_sena             DOUBLE,
  rateio_quina            DOUBLE,
  rateio_quadra           DOUBLE,
  arrecadacao_total       DOUBLE,
  estimativa_premio       DOUBLE,
  valor_acumulado         DOUBLE,
  acumulado               BOOL NOT NULL ON CONFLICT ABORT,  -- 0 = false e 1 = true
  CONSTRAINT dezenas_unicas CHECK(
    dezena1 NOT IN (dezena2, dezena3, dezena4, dezena5, dezena6) AND
    dezena2 NOT IN (dezena3, dezena4, dezena5, dezena6) AND
    dezena3 NOT IN (dezena4, dezena5, dezena6) AND
    dezena4 NOT IN (dezena5, dezena6) AND
    dezena5 != dezena6
  ));
CREATE TRIGGER IF NOT EXISTS on_concursos_insert AFTER INSERT ON concursos BEGIN
  INSERT INTO dezenas_juntadas (concurso,dezenas) VALUES (new.concurso,(1 << new.dezena1-1) | (1 << new.dezena2-1) | (1 << new.dezena3-1) | (1 << new.dezena4-1) | (1 << new.dezena5-1) | (1 << new.dezena6-1));
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena1);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena2);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena3);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena4);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena5);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena6);
  INSERT INTO sugestoes SELECT new.concurso, dezena FROM info_dezenas WHERE frequencia < new.concurso/10.0 AND latencia >= 10;
END;
CREATE TRIGGER IF NOT EXISTS on_concursos_delete AFTER DELETE ON concursos BEGIN
  DELETE FROM dezenas_juntadas WHERE (concurso == old.concurso);
  DELETE FROM dezenas_sorteadas WHERE (concurso == old.concurso);
  DELETE FROM sugestoes WHERE (concurso == old.concurso);
  DELETE FROM ganhadores WHERE (concurso == old.concurso);
END;
DROP TABLE IF EXISTS dezenas_juntadas;
CREATE TABLE dezenas_juntadas (
  -- agrupamentos bitwise das dezenas sorteadas nos concursos
  -- preenchida automaticamente i.e.: sem intervenção direta do usuário
  concurso    INTEGER,
  dezenas     INTEGER,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
DROP TABLE IF EXISTS dezenas_sorteadas;
CREATE TABLE dezenas_sorteadas (
  -- tabela conveniência p/facilitar análise dos números sorteados ao longo do
  -- tempo, preenchida automaticamente i.e.: sem intervenção direta do usuário
  concurso    INTEGER,
  dezena      INTEGER,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
DROP INDEX IF EXISTS ndx;
CREATE INDEX ndx ON dezenas_sorteadas (concurso COLLATE binary, dezena COLLATE binary);
CREATE VIEW IF NOT EXISTS info_dezenas AS
  -- frequências das dezenas desde o primeiro concurso
  -- número de concursos recentes em que as dezenas não foram sorteadas
  SELECT dezena, count(dezena) AS frequencia, (M - max(concurso)) AS latencia
  FROM (
    SELECT concurso AS M FROM concursos ORDER BY concurso DESC LIMIT 1
  ), dezenas_sorteadas
  GROUP BY dezena;
DROP TABLE IF EXISTS sugestoes;
CREATE TABLE sugestoes (
  -- tabela dos números sugeridos para o próximo concurso, preenchida
  -- automaticamente a cada inserção de registro na tabela concursos
  concurso    INTEGER,
  dezena      INTEGER,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
CREATE VIEW IF NOT EXISTS acertos
  -- tabela dos números sugeridos que foram sorteados
  AS SELECT s.* FROM sugestoes AS s JOIN dezenas_sorteadas AS z
    ON s.concurso+1 == z.concurso AND s.dezena == z.dezena;
COMMIT;
DROP TABLE IF EXISTS ganhadores;
CREATE TABLE ganhadores (
  concurso  INTEGER NOT NULL,
  cidade    TEXT,
  uf        TEXT,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
