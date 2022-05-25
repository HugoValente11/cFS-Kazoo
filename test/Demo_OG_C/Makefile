KAZOO?=kazoo
# Here you can specify folders containing external code you want to
# compile and link for a specific partition.
# Use upper case for the partition name:
# export <PARTITION_NAME>_EXTERNAL_SOURCE_PATH=/absolute/path/1:/....

all:	c

c:	work/glue_built
	$(MAKE) -C work

skeletons:
	$(MAKE) work/skeletons_built

work/skeletons_built:	InterfaceView.aadl DataView.aadl
	$(KAZOO) -g  --gw -o work
	$(MAKE) -C work dataview
	touch $@

work/glue_built:	InterfaceView.aadl DeploymentView.aadl DataView.aadl
	$(KAZOO) -p --glue --gw -o work
	touch $@

clean:
	rm -rf work/build
	rm -f work/glue_built work/skeletons_built
	find work -type d -name "wrappers" -exec rm -rf {} +
	find work -type d -name "*_GUI" -exec rm -rf {} +
	rm -rf work/Debug/ \
	work/Dump/ \
	work/Makefile \
	work/binaries/ \
	work/build-script.sh \
	work/dataview/ \
	work/demo_sdl_to_c/C/ \
	work/demo_sdl_to_c/SDL/Makefile \
	work/demo_sdl_to_c/SDL/code/ \
	work/demo_sdl_to_c/SDL/src/Makefile.demo_sdl_to_c \
	work/demo_sdl_to_c/SDL/src/dataview-uniq.asn \
	work/demo_sdl_to_c/SDL/src/dataview_ada.gpr \
	work/demo_sdl_to_c/SDL/src/dataview_c.gpr \
	work/demo_sdl_to_c/SDL/src/demo_sdl_to_c.gpr \
	work/demo_sdl_to_c/SDL/src/demo_sdl_to_c.pr.ini \
	work/demo_sdl_to_c/SDL/src/system_structure.pr

.PHONY: clean skeletons c

