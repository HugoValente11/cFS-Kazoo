-- User implementation of the ada_fct function
-- This file will never be overwritten once edited and modified
-- Only the interface of functions is regenerated (in the .ads file)

pragma style_checks (off);
pragma warnings (off);
with adaasn1rtl;
use adaasn1rtl;

with taste_basictypes;
use taste_basictypes;
with system.io;
use system.io;

package body ada_fct is

	---------------------------------------------------------
	-- Provided interface "start_ada_timer"
	---------------------------------------------------------
	procedure start_ada_timer is
            timer: asn1sccT_UInt32 := 3000;
	begin
            SET_ada_timer(timer);
            system.io.put_line("[Ada] Timer should expire in 3 seconds");
	end start_ada_timer;

	-- This function is called when the timer "ada_timer" expires 
	procedure ada_timer is
	begin
            system.io.put_line("[Ada] timer expired !");
            Ada_Timer_Expired;
	end;


end ada_fct;
