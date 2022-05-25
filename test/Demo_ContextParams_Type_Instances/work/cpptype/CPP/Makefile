VISUAL?=kate

all: compile-linux

clean:
	rm -rf obj

edit:
	$(VISUAL) ../../dataview/C/dataview-uniq.h \
                  ../../dataview/C/Context-cpptype.h \
                  ../../dataview/C/Context-cpptype.c \
                  src/cpptype.h \
                  src/cpptype_state.h \
                  src/cpptype.cc

compile-linux:
	mkdir -p obj && cd obj && g++ -c ../src/*.cc
