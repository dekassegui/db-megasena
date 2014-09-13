-- Preenchimento da tabela "ganhadores"
PRAGMA foreign_keys = ON;
.separator '|'
.import '/tmp/ganhadores.dat' ganhadores
UPDATE ganhadores SET cidade=NULL WHERE cidade IS '';
UPDATE ganhadores SET uf=NULL WHERE uf IS '';
