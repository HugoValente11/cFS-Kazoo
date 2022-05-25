with Text_IO; use Text_IO;
with iterators_types;
use iterators_types;

with My_Observer;

with My_Observer_Datamodel;
use My_Observer_Datamodel;

with GSER;

package body Properties is

   procedure Update_State (Full_State        : in out State_With_Observers;
                           Application_State : asn1SccSystem_State) is
   begin
       Full_State.User_State := Application_State;
   end Update_State;

   procedure Print_Full_State (Full_State : State_With_Observers) is
   begin
       Put_Line (State_To_String (Full_State));
   end Print_Full_State;

   procedure My_Properties (Full_State : in out State_With_Observers;
                            Event      : in out asn1sccObservable_Event;
                            Id         : out Natural;
                            Success    : out Boolean) is
       Observer_State_Status : asn1SccObserver_State_Kind;
   begin
       Id := 0;
       -- Restore the state of the observer, and execute it
       My_Observer.Ctxt := Full_State.My_Observer_State;
       --  Put_Line ("[OBS] Context set to: " & GSER.Image (My_Observer.Ctxt));

       --  Set the observer's monitors
       Observer_State_Status := My_Observer.Observe (Full_State.User_State, Event);
       --  Read the modified state from the observer
       Event                 := My_Observer.Event;
       Full_State.User_state := My_Observer.St;
       Full_State.My_Observer_State := My_Observer.Ctxt;
       --  Simple stop condition:
       Success := (Observer_State_Status = asn1SccError_State);
       --  My_Observer.Ctxt.State = My_Observer_Datamodel.asn1SccEnd_Success);
       if Success then
          Put_Line ("Stop condition found");
       end if;
   end;
end Properties;
