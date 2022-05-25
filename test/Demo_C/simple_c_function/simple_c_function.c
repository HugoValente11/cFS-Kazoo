/* Functions to be filled by the user (never overwritten by buildsupport tool) */

#include "simple_c_function.h"
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <stddef.h>

void myhandler();

void simple_c_function_startup(void)
{
   printf ("[Startup] Expected output: \"Hello, world...\" every 2 seconds\n");
   (void) signal (SIGUSR1, myhandler);
}

void myhandler(void)
{
   printf ("SIGUSR1 received\n");
   exit (0);
}

void simple_c_function_PI_cyclic_operation(void)
{
   printf ("Hello, world...\n");
}

