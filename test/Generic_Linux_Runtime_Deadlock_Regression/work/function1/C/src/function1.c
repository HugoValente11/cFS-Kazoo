/* Body file for function Function1
 * Generated by TASTE on 2021-09-06 14:46:17
 * You can edit this file, it will not be overwritten
 * Provided interfaces : op, trigger
 * Required interfaces : check
 * User-defined properties for this function:
 *   |_ Taste::Active_Interfaces = any
 *   |_ Taste::coordinates = 100785 75431 163145 149917
 * Timers              :
 */

#include "function1.h"
#include <stdio.h>

void function1_startup(void)
{
}

void function1_PI_op
      (const asn1SccT_Int32 *IN_a)
{
    printf("OP %d\n", *IN_a);
}
void function1_PI_trigger(void)
{
    static asn1SccT_Int32 a = 0;
    function1_RI_check(&a);
}
