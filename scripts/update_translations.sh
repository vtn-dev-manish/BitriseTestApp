#!/bin/sh
set -e
languages=("de-AT" "de-CH" "it-CH" "fr-CH" "fr-FR" "ro" "bg")
wti pull -l "${languages[*]}"

for language in ${languages[*]}; do
  folder="values-${language/-/-r}"
  for file in app/src/*/res/"$folder"/{strings,plurals}.xml; do
    echo "$language: Cleaning $file"
    perl -i -ne 'print unless m/^\s*<string name=".+"><\/string>\s*$|^\s*<eat-comment \/>\s*$|^\s*<!-- .+ -->\s*$|^\s+$|^\s*s\s*$/' "$file"
    if [ "$(cat "$file" | wc -l)" -eq 2 ]; then # three lines (two since no trailing newline) -> empty file (header, <resources>, </resources>)
      echo "$language: deleting (now) empty $file"
      rm "$file"
    fi
  done
done
