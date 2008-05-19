#!/bin/bash

cd lib
f=$(mktemp)
echo "strict digraph requirestree { " > $f
grep -r "^require " * |grep -v svn |grep -v swp | sed "s/^\(.*\).rb:require '\(.*\)'/\1 -> \2;/" | sed 's/\//_/g' >> $f
echo "}" >> $f
cd ..
dot -Tpng $f -o gen_requires.png
rm -f $f
