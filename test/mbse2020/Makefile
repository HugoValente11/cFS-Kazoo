KAZOO?=kazoo
# Here you can specify custom compiler/linker flags, and add folders containing
# external code you want to compile and link for a specific partition.
# Use upper case for the partition name:
# export <PARTITIONNAME>_USER_CFLAGS=...
# export <PARTITIONNAME>_USER_LDFLAGS=...
# export <PARTITIONNAME>_EXTERNAL_SOURCE_PATH=

all:	c

c:	work/glue_built
	$(MAKE) -C work

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
	rm -rf work/Makefile \
	work/binaries/ \
	work/build-script.sh \
	work/dataview/ \
	work/fdir/ \
	work/flight_software/SDL/Makefile \
	work/flight_software/SDL/code/ \
	work/flight_software/SDL/flight_software_ada.gpr \
	work/flight_software/SDL/src/Flight_Software.cfg \
	work/flight_software/SDL/src/Makefile.flight_software \
	work/flight_software/SDL/src/dataview-uniq.asn \
	work/flight_software/SDL/src/dataview_ada.gpr \
	work/flight_software/SDL/src/dataview_c.gpr \
	work/flight_software/SDL/src/flight_software.gpr \
	work/flight_software/SDL/src/flight_software.pr.autosave \
	work/flight_software/SDL/src/flight_software.pr.ini \
	work/flight_software/SDL/src/system_structure.pr \
	work/flight_software/flight_software.pro \
	work/ground_segment/ \
	work/mass_memory/Ada/Makefile \
	work/mass_memory/Ada/gnatinspect.db \
	work/mass_memory/Ada/src/mass_memory.ads \
	work/mass_memory/Ada/src/mass_memory_ri.ads \
	work/mass_memory/Ada/tmp_mass_memory-loc.xml \
	work/mass_memory/mass_memory.pro \
	work/payload/SDL/Makefile \
	work/payload/SDL/code/ \
	work/payload/SDL/payload_ada.gpr \
	work/payload/SDL/src/Makefile.payload \
	work/payload/SDL/src/Payload.cfg \
	work/payload/SDL/src/dataview-uniq.asn \
	work/payload/SDL/src/dataview_ada.gpr \
	work/payload/SDL/src/dataview_c.gpr \
	work/payload/SDL/src/payload.gpr \
	work/payload/SDL/src/payload.pr.autosave \
	work/payload/SDL/src/payload.pr.ini \
	work/payload/SDL/src/system_structure.pr \
	work/payload/payload.pro \
	work/satellite_platform_timer_manager/ \
	work/sql_db/ \
	work/simulation \
	work/taste.pro

.PHONY: clean skeletons c simu

