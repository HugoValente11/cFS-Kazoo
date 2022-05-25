KAZOO?=kazoo
# Here you can specify custom compiler/linker flags, and add folders containing
# external code you want to compile and link for a specific partition.
# Use upper case for the partition name:
export TETRIS_USER_CFLAGS=-fdata-sections -ffunction-sections
export TETRIS_USER_LDFLAGS=-fdata-sections -ffunction-sections -Wl,--gc-sections 
# export <PARTITIONNAME>_EXTERNAL_SOURCE_PATH=

all:	c

c:	work/glue_built
	$(MAKE) -C work
	cp UserWidgets.py work/binaries/player_GUI/

# Simulation target (experimental)
simu:	InterfaceView.aadl DeploymentView.aadl DataView.aadl ConcurrencyView_Properties.aadl
	$(KAZOO) -t SIMU --glue --gw
	$(MAKE) -C work

skeletons:
	$(MAKE) work/skeletons_built

work/skeletons_built:	InterfaceView.aadl DataView.aadl
	$(KAZOO) --gw -o work
	$(MAKE) -C work dataview
	touch $@

work/glue_built:	InterfaceView.aadl DeploymentView.aadl DataView.aadl ConcurrencyView_Properties.aadl
	$(KAZOO) -p --glue --gw -o work
	touch $@

clean:
	rm -rf work/build
	rm -f work/glue_built work/skeletons_built
	find work -type d -name "wrappers" -exec rm -rf {} +
	find work -type d -name "*_GUI" -exec rm -rf {} +
	rm -rf work/engine/SDL/src/Engine.cfg \
	work/engine/SDL/src/Makefile.engine \
	work/engine/SDL/src/dataview_ada.gpr \
	work/engine/SDL/src/dataview_c.gpr \
	work/engine/SDL/src/engine.gpr \
	work/engine/SDL/src/engine.pr.ini


.PHONY: clean skeletons c simu

