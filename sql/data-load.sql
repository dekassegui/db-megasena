-- Importa dados do buffer de registros plain/text
PRAGMA foreign_keys = ON;
.separator '|'
.import '/tmp/buffer.dat' concursos
UPDATE concursos SET cidade=NULL WHERE cidade IS 'NULL';
UPDATE concursos SET uf=NULL WHERE uf IS 'NULL';
