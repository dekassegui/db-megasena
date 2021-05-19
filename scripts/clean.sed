s/<(td|tr|th)[^>]+/<\1/g  # remove atributos das tags
/<td>/ {
  s/\.//g                 # remove separador de milhares
  y/,/./                  # substitui separador de ponto flutuante
}

