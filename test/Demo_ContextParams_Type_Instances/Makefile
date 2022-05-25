KAZOO?=../../kazoo

all:	c
	./regression.py

c:	work/glue_built
	$(MAKE) -C work

ada:	work_ada/glue_built
	$(MAKE) -C work_ada

skeletons:	InterfaceView.aadl DataView.aadl
	$(KAZOO) --gw -o work
	$(MAKE) -C work dataview

work/glue_built:	InterfaceView.aadl DeploymentView.aadl DataView.aadl
	$(KAZOO) -p --glue --gw -o work
	touch work/glue_built

work_ada/glue_built:	InterfaceView.aadl DeploymentView.aadl DataView.aadl
	$(KAZOO) --glue --gw -o work_ada
	touch work_ada/glue_built

clean:  soft-clean
	

soft-clean:
	$(MAKE) -C work clean
	$(MAKE) -C work_ada clean

.PHONY: clean skeletons c

