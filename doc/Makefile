all:
	mkdir -p tmp
	mkdir -p new-templates
	# Extract the latest template tags from any demo project and put them in the new-templates folder
	cd ../test/Demo_Distrib && kazoo --doc -o ../../doc/tmp --gw -g --glue && mv ../../doc/tmp/Dump/Doc/* ../../doc/new-templates
	mkdir -p preprocess
	cp templates/templates_from_wiki preprocess # copy the previous one
	mv templates/templates_from_wiki templates/templates_from_wiki.old  # delete the old templates
	$(MAKE) -C preprocess
	cp preprocess/output/order.txt .
	./kazoo-merge-doc.py
	rm -rf tmp new-templates preprocess/output
	./to_html.sh

clean:
	rm -rf preprocess/output/*
	find preprocess/templates/ -type f -delete
