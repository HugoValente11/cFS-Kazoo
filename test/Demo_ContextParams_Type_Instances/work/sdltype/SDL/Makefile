# SDL
#Taste::Active_Interfaces any
#Taste::coordinates 1607 60 2108 444
#Taste::is_Component_Type true
OPENGEODE?=opengeode

all: compile-linux

clean:
	rm -rf obj

edit:
	cd src && $(OPENGEODE) system_structure.pr sdltype.pr

# Ada
generate-code:
	mkdir -p code && cd code && \
	   $(OPENGEODE) --taste --toAda ../src/sdltype.pr ../src/system_structure.pr && \
	:

compile-linux: generate-code
	:

