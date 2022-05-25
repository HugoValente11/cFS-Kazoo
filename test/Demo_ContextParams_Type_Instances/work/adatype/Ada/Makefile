VISUAL?=kate

all: compile-linux

clean:
	rm -rf obj
edit:
	echo "project tmp_adatype is For Source_Dirs use (\"src\", \"../../dataview/Ada/\"); end tmp_adatype;" > tmp_adatype.gpr
	gnat-gps -P tmp_adatype.gpr
	rm tmp_adatype.gpr

compile-linux:
	mkdir -p obj && cd obj && ADA_INCLUDE_PATH=../../../dataview/Ada gnat make ../src/adatype
