# this file was written manually.. for now

all: mc

mc: observer/my_observer.adb mcsrc/mc.adb mcsrc/properties.adb
	ADA_PROJECT_PATH=~/.local/share/gpr:${ADA_PROJECT_PATH} gprbuild -p -P mc

observer/my_observer.adb: observer/observer.pr observer/observer.asn
	cd observer && opengeode --toAda observer.pr && \
	asn1scc  -Ada -typePrefix asn1scc -equal  --target allboards observer.asn my_observer_datamodel.asn  && \
	mv src/my_observer_datamodel.ad? .
	# generate Ada package to print asn1 values
	taste-asn1-gser --raw -o observer --module gser observer/observer.asn observer/my_observer_datamodel.asn
	

# gather dataviews needed to build an observer
observer/observer.asn: ../dataview/dataview-uniq.asn ../build/simulation.asn ../orchestrator/SDL/code/orchestrator_datamodel.asn  ../another_function/SDL/code/another_function_datamodel.asn 
	cat $^ > $@

clean:
	ADA_PROJECT_PATH=~/.local/share/gpr:${ADA_PROJECT_PATH} gprclean -P mc
	rm observer/my_observer.ad?
