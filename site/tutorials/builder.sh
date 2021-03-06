#!/bin/bash

if [[ $1 != "" ]]; then
  ./markymark $1
  claat export -ga "UA-133584243-1" ${1/.md/_gen.md}
else

  for file in ./*.md
  do
    # do not touch generated files
    if [[ $file != *"_gen.md"* ]] && [[ $file != *"tutorial-template.md"* ]] && [[ $file != *"README.md"* ]]; then 
      ./markymark "$file"
      # export the generated files
      claat export -ga "UA-133584243-1" ${file/.md/_gen.md}
    fi
  done

fi
# now serve the content to check locally
# claat serve
