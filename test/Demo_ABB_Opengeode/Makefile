KAZOO=../../kazoo

all: c

simu:
	$(KAZOO) -t SIMU -p --gw --glue -g
	cp controller/controller.pr work/controller/SDL/src
	cp lift_model/* work/lift_model/SIMULINK/src
	$(MAKE) -C work

c: test-parse-c # Polyorb_HI_C output
	cp controller/controller.pr work/controller/SDL/src
	cp lift_model/* work/lift_model/SIMULINK/src
	make -C work
	# Test the MSC converter tool and execute the MSC scenario
	./regression_ok.sh
	./regression_nok.sh

test-parse-c: clean-c
	$(KAZOO) -p --gw \
	         -o work \
	         --glue #-g
buildsupport_pohic:
	buildsupport -o output.buildsupport.pohic -p --aadlv2 --glue -i InterfaceView.aadl -c DeploymentView.aadl -d DataView.aadl ../common/ocarina_components.aadl ../common/TASTE_IV_Properties.aadl ../common/TASTE_DV_Properties.aadl

buildsupport_pohiada:
	buildsupport -o output.buildsupport.ada --aadlv2 --glue -i InterfaceView.aadl -c DeploymentView.aadl -d DataView.aadl ../common/ocarina_components.aadl ../common/TASTE_IV_Properties.aadl ../common/TASTE_DV_Properties.aadl

gdb: clean
	gdb --args $(KAZOO) --gw -p \
	               -o work \
	               --glue \
		       --debug

clean-c:
	rm -rf work

skeletons:
	$(KAZOO) -p --gw --glue -o work && make -C work dataview

clean-skeletons:
	rm -rf work

clean: clean-c clean-skeletons

.PHONY: clean simu clean-c gdb test-parse-c buildsupport_pohic buildsupport_pohiada c skeletons clean-skeletons
