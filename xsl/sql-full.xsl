<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:include href="sql-insert.xsl"/>

  <xsl:template match="/">
BEGIN TRANSACTION;
PRAGMA foreign_keys = ON;
PRAGMA legacy_file_format = ON;
DROP TABLE IF EXISTS concursos;
CREATE TABLE concursos (
  -- tabela obtida por convers�o de documento HTML que cont�m
  -- a s�rie temporal completa dos concursos da megasena
  concurso                INTEGER PRIMARY KEY,
  data_sorteio            DATETIME NOT NULL ON CONFLICT ABORT, -- yyyy-mm-dd
  dezena1                 INTEGER CHECK (dezena1 BETWEEN 1 AND 60),
  dezena2                 INTEGER CHECK (dezena2 BETWEEN 1 AND 60),
  dezena3                 INTEGER CHECK (dezena3 BETWEEN 1 AND 60),
  dezena4                 INTEGER CHECK (dezena4 BETWEEN 1 AND 60),
  dezena5                 INTEGER CHECK (dezena5 BETWEEN 1 AND 60),
  dezena6                 INTEGER CHECK (dezena6 BETWEEN 1 AND 60),
  arrecadacao_total       DOUBLE,
  ganhadores_sena         INTEGER,
  rateio_sena             DOUBLE,
  ganhadores_quina        INTEGER,
  rateio_quina            DOUBLE,
  ganhadores_quadra       INTEGER,
  rateio_quadra           DOUBLE,
  acumulado               BOOL NOT NULL ON CONFLICT ABORT,  -- 0 = false e 1 = true
  valor_acumulado         DOUBLE,
  estimativa_premio       DOUBLE,
  acumulada_mega_virada   DOUBLE);
CREATE TRIGGER IF NOT EXISTS on_concursos_insert AFTER INSERT ON concursos BEGIN
  INSERT INTO dezenas_juntadas (concurso,dezenas) VALUES (new.concurso,(1 &#60;&#60; new.dezena1-1) | (1 &#60;&#60; new.dezena2-1) | (1 &#60;&#60; new.dezena3-1) | (1 &#60;&#60; new.dezena4-1) | (1 &#60;&#60; new.dezena5-1) | (1 &#60;&#60; new.dezena6-1));
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena1);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena2);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena3);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena4);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena5);
  INSERT INTO dezenas_sorteadas (concurso,dezena) VALUES (new.concurso,new.dezena6);
END;
CREATE TRIGGER IF NOT EXISTS on_concursos_delete AFTER DELETE ON concursos BEGIN
  DELETE FROM dezenas_juntadas WHERE (concurso == old.concurso);
  DELETE FROM dezenas_sorteadas WHERE (concurso == old.concurso);
END;
DROP TABLE IF EXISTS dezenas_juntadas;
CREATE TABLE dezenas_juntadas (
  -- agrupamentos bitwise das dezenas sorteadas nos concursos
  -- preenchida automaticamente i.e.: sem interven��o direta do usu�rio
  concurso    INTEGER,
  dezenas     INTEGER,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
DROP TABLE IF EXISTS dezenas_sorteadas;
CREATE TABLE dezenas_sorteadas (
  -- tabela conveni�ncia p/facilitar an�lise dos n�meros sorteados ao longo do
  -- tempo, preenchida automaticamente i.e.: sem interven��o direta do usu�rio
  concurso    INTEGER,
  dezena      INTEGER,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));
DROP INDEX IF EXISTS ndx;
CREATE INDEX ndx ON dezenas_sorteadas (concurso COLLATE binary, dezena COLLATE binary);
CREATE VIEW IF NOT EXISTS info_dezenas
  -- frequ�ncias das dezenas desde o primeiro concurso
  -- n�mero de concursos recentes em que as dezenas n�o foram sorteadas
  AS SELECT dezena, count(dezena) AS frequencia, ((SELECT max(concurso) FROM concursos) - max(concurso)) AS latencia
  FROM dezenas_sorteadas
  GROUP BY dezena;

    <xsl:call-template name="SQL_INSERT">
      <xsl:with-param name="rows_offset" select="1"/>
    </xsl:call-template>

COMMIT;
  </xsl:template>

</xsl:stylesheet>
