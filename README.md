# Prerequisites
This tool is part of the cFS modified TASTE toolchain (cFS Creator). Before we can work with cFS Creator we need tools to be available on the computer and some libraries to compile against.

1. Install the TASTE VM following the instructions in https://gitrepos.estec.esa.int/taste/taste-setup
2. Replace the startup scripts with our modified startup scripts in the ~/tool-src folder and install them executing the command `~/tool-src/install/90_misc.sh`
3. Replace the kazoo with our modified Kazoo in the ~/tool-src folder and install it executing the command `~/tool-src/install/87_kazoo.sh`
4. Setup our modified QtCreator environment following the instructions in the repo - cFS Creator
5. Add the cFS runtime following the instructions in https://github.com/nasa/cFS.git

# How to use
It works exactly the same way as the original TASTE version. You can use `taste` or `taste-cfs` to create a new project and it should load the modified QtCreator environment.



# More information 
Kazoo is the TASTE tool in charge of generating code skeletons, glue code and build scripts

License: GPL with runtime exception (see LICENSE file)

Copyright (c) 2019-2020 Maxime Perrotin / European Space Agency

Check the full documentation of Kazoo here:

https://taste.tuxfamily.org/wiki/index.php?title=Kazoo
