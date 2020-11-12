#/bin/bash

# executa o script sql que implementa o esquema "param"
sqlite3 megasena.sqlite '.read sql/param.sql'
