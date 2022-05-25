--  Add the data model of all observers to form the full state
with My_Observer;
with My_Observer_Datamodel;

with Simulation_Dataview; use Simulation_Dataview;

with adaasn1rtl; use adaasn1rtl;
with GSER;

package Properties is

    --  The state stored in the graph is defined here, putting together the
    --  state of the TASTE system and the state of the observers
    type State_With_Observers is tagged
        record
            User_State        : asn1sccSystem_State;
            My_Observer_State : My_Observer_Datamodel.asn1SccMy_Observer_Context;
        end record;

   --  Define the functions of the tagged type
   --  Later the User state part can be a PER-encoded string to save space
   --  When this happens, the following functions need to be update to do
   --  The encoding/decoding on the fly
   function Application_State (Full_State : State_With_Observers)
       return asn1SccSystem_State is (Full_State.User_State);

   procedure Update_State (Full_State        : in out State_With_Observers;
                           Application_State : asn1SccSystem_State);

   -- Return a GSER string of the state, useful to print or to compute hash
   function State_To_String (Full_State : State_With_Observers) return String is
       (GSER.Image (Full_State.User_State) & GSER.Image (Full_State.My_Observer_State));


   procedure Print_Full_State (Full_State : State_With_Observers);

   function Full_State_Init return State_With_Observers is
       (User_State        => asn1sccSystem_State_Init,
        My_Observer_State => My_Observer.Ctxt);

   procedure My_Properties (Full_State : in out State_With_Observers;
                            Event      : in out asn1sccObservable_Event;
                            Id         : out Natural;
                            Success    : out Boolean);

end Properties;
