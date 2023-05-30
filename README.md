# Prerequisites
This tool is part of the cFS modified TASTE toolchain (cFS Creator). Before we can work with cFS Creator we need tools to be available on the computer and some libraries to compile against.

1. Install the TASTE VM following the instructions in https://gitrepos.estec.esa.int/taste/taste-setup. <strong>All the following prerequisites assume you are using the TASTE VM.</strong>
2. Replace the misc folder with our modified one following the instructions in [insert repo url](here)
3. Replace kazoo with our modified Kazoo following the instructions in [insert repo url](here)
4. Setup our modified QtCreator environment, cFS Creator, following the instructions in [insert repo url](here)
5. Add the cFS runtime following the instructions in [insert repo url](here)
6. Replace the local configuration files for Qt with our modified ones following the instructions in [insert repo url](here)

# How to use
It works exactly the same way as the original TASTE version. You can use the `taste` command to create a new project and it should load the modified QtCreator environment, cFS Creator.

# Build kazoo
To update the kazoo to our modified version that allows to generate code for cFS applications execute the following commands

`$ mv ~/tool-src/kazoo ~/tool-src/kazoo-bu`

`$ git clone url ~/tool-src/kazoo`


# More information 
Kazoo is the TASTE tool in charge of generating code skeletons, glue code and build scripts

License: GPL with runtime exception (see LICENSE file)

Copyright (c) 2019-2020 Maxime Perrotin / European Space Agency

Check the full documentation of Kazoo here:

https://taste.tuxfamily.org/wiki/index.php?title=Kazoo
