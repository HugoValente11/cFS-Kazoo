KAZOO=../../kazoo

all: c

c: test-parse-c # Polyorb_HI_C output
	cp skels/a/a.c work/a/C/src
	cp skels/b/b.c work/b/C/src
	make -C work
	./regression_kazoo.py

test-parse-c: clean-c
	$(KAZOO) -p --gw \
	         -o work \
	         --glue #-g
buildsupport_pohic:
	buildsupport -o output.buildsupport.pohic -p --aadlv2 --glue -i InterfaceView.aadl -c DeploymentView.aadl -d DataView.aadl ../common/ocarina_components.aadl ../common/TASTE_IV_Properties.aadl ../common/TASTE_DV_Properties.aadl

gdb: clean
	gdb --args $(KAZOO) --gw \
	               -o work \
	               --glue \
		       --debug

skeletons:
	$(KAZOO) -p --gw --glue -o work && make -C code dataview

clean-skeletons:
	rm -rf work

clean-c:
	rm -rf work

clean: clean-c clean-skeletons

.PHONY: clean clean-c gdb test-parse-c buildsupport_pohic c skeletons clean-skeletons
