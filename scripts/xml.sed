# substitui a primeira linha por xml prolog e tags iniciais do elemento
# raiz "table" e seu first-child "tr"
1 c\
<?xml version="1.0" encoding="UTF-8"?><table><tr>
# remove Carriage Return
s/\r//g
# remove atributos de elementos "tr" e "td"
s/<(td|tr)[^>]+/<\1/g
# modifica conteúdo de elementos "td"
/<td>/ {
  s/&nbsp//g                # remove entity mal declarada
  s/\.//g; y/,/./;          # normaliza formato numérico
  s/SIM/1/; s/NÃO/0/        # normaliza valor tipo boolean
  s/>\s*(\w.+\w)\s+</>\1</  # remove espaços em branco redundantes
}
# remove tags finais de elementos "body" e "html"
/<\/(body|html)>/d
