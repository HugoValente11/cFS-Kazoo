# Prerequisites
This tool is part of the cFS modified TASTE toolchain (cFS Creator). Before we can work with cFS Creator we need tools to be available on the computer and some libraries to compile against.

1. Install the TASTE VM following the instructions in https://gitrepos.estec.esa.int/taste/taste-setup. <strong>All the following instructions assume you are using the TASTE VM.</strong>
2. Replace the misc folder with our modified one following the instructions in [cFS misc](https://gitlab.com/aurora-software/cFS-misc).
3. Replace kazoo with our modified Kazoo following the instructions in [cFS Kazoo](https://github.com/HugoValente11/cFS-Kazoo).
4. Setup our modified QtCreator environment, cFS Creator, following the instructions in [cFS Creator](https://gitlab.com/aurora-software/cFS-Creator).
5. Add the cFS runtime following the instructions in [TASTE cFS Runtime](https://gitlab.com/aurora-software/taste-cfs-runtime).
6. Replace the local configuration files for Qt with our modified ones following the instructions in [cFS Local Config](https://gitlab.com/aurora-software/cFS-local-config).

# How to use
It works exactly the same way as the original TASTE version. You can use the `taste` command to create a new project and it should load the modified QtCreator environment, cFS Creator.

# Build kazoo
To update the kazoo to our modified version that allows to generate code for cFS applications execute the following commands

`$ mv ~/tool-src/kazoo ~/tool-src/kazoo-bu`

`$ git clone https://github.com/HugoValente11/cFS-Kazoo ~/tool-src/kazoo`

`$ ~/tool-src/install/87_kazoo.sh`


# More information 
Kazoo is the TASTE tool in charge of generating code skeletons, glue code and build scripts

License: GPL with runtime exception (see LICENSE file)

Copyright (c) 2019-2020 Maxime Perrotin / European Space Agency

Check the full documentation of Kazoo here:

https://taste.tuxfamily.org/wiki/index.php?title=Kazoo
