KAZOO=../../kazoo

all: test-parse
	cp input_data/helloworld1.c work/helloworld1/C/src
	cp input_data/helloworld2.c work/helloworld2/C/src
	make -C work

test-parse: clean
	$(KAZOO) --gw -p \
	         -o work \
	         --glue \
	         --debug

skeletons:
	$(MAKE) -C work skeletons

gdb: clean
	gdb --args $(KAZOO) --gw -p \
	               -o output \
	               --glue \
	         --debug

clean:
	rm -rf work

.PHONY: clean test-parse gdb
