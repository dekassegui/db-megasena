#!/bin/bash
#
# Geração de imagem do histograma das dezenas sorteadas na Mega-Sena
#
R/plot_frequencias.r >/dev/null
pdf='Rplots.pdf'
if [[ -e $pdf ]]; then
  # converte pdf para png combinando possíveis quadros com fundo branco
  convert -background white -flatten +matte $pdf Rplots.png
fi
