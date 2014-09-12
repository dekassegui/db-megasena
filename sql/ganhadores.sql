-- Criação/Regeneração e preenchimento da tabela "ganhadores"

.separator '|'

PRAGMA legacy_file_format = ON;

DROP TABLE IF EXISTS ganhadores;
CREATE TABLE ganhadores (
  concurso  INTEGER NOT NULL,
  cidade    TEXT,
  uf        TEXT,
  FOREIGN KEY (concurso) REFERENCES concursos(concurso));

.import '/tmp/ganhadores.dat' ganhadores

UPDATE ganhadores SET cidade=NULL WHERE cidade IS '';
UPDATE ganhadores SET uf=NULL WHERE uf IS '';
