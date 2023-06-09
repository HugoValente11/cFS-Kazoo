cd templates
# to generate html output with tables
pandoc --toc -N -c ../kazoo.css -f mediawiki -t html5 -s templates_from_wiki -o templates_doc.html
# To generate text documentation with nice tables:
for f in *.split
do
   OUTPUT=${f%.*}.ascii
   # Following does not work with recent versions of pandoc (debian11)
   # pandoc -c ../kazoo.css -f mediawiki -t rst+grid_tables --toc -o "$OUTPUT" $f &&  rm -f $f
   # use this instead:
   pandoc -c ../kazoo.css -f mediawiki -t plain-simple_tables-multiline_tables-pipe_tables --toc -o "$OUTPUT" $f &&  rm -f $f
done
