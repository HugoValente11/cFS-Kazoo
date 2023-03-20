--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --
with Ada.Strings.Unbounded,
     Ada.Characters.Handling,  --  To_Lower
     Ada.Containers,
     TASTE.Deployment_View,
     TASTE.Interface_View,
     TASTE.Parser_Utils;

use Ada.Strings.Unbounded,
    Ada.Containers,
    Ada.Characters.Handling,
    TASTE.Deployment_View,
    TASTE.Interface_View,
    TASTE.Interface_View.Interfaces_Maps,
    TASTE.Parser_Utils;

package body TASTE.Semantic_Check is
   --  use String_Vectors;
   procedure Check_Model (Model : TASTE_Model) is
      use Option_Partition;
      Opt_Part     : Option_Partition.Option;
      Found_Error  : Boolean := False;
      --  Allow case insensitive checks of unbounded strings:
      function "="(A, B : Unbounded_String) return Boolean is
          (To_Lower (To_String (A)) = (To_Lower (To_String (B))));

      Error_Found : Boolean := False;
   begin
      --  Checks done when generating skeletons
      for Each of Model.Interface_View.Flat_Functions loop
         --  SDL functions
         if Each.Language = "sdl" then
            for PI of Each.Provided loop
               --  Check that if a PI and a RI have the same name, they
               --  also have the same interface (since they are translated
               --  to a single "signal" in SDL)
               for RI of Each.Required loop
                  if PI.Name = RI.Name then --  Case insensitive check
                     if PI.Params.Length /= RI.Params.Length then
                        Error_Found := True;
                     else
                        for I in PI.Params.First_Index .. PI.Params.Last_Index
                        loop
                           --  Compare each param (name + type)
                           if PI.Params (I).Name /= RI.Params (I).Name
                               or PI.Params (I).Sort /= RI.Params (I).Sort
                           then
                              Error_Found := True;
                           end if;
                        end loop;
                     end if;
                     if Error_Found then
                        raise Semantic_Error with
                           "In SDL function " & To_String (Each.Name)
                           & ": PI and RI signatures shall be identical when "
                           & "interfaces have the same name - "
                           & To_String (PI.Name);
                     end if;
                  end if;
               end loop;
               --  Check that sporadic inputs only have one IN param at most
               if PI.RCM = Sporadic_Operation and then
                  (PI.Params.Length > 1 or (PI.Params.Length = 1 and
                  (for all Param of PI.Params => Param.Direction /= param_in)))
               then
                  raise Semantic_Error with
                   "In SDL function " & To_String (Each.Name) & ": sporadic "
                     & "interfaces shall have at most one IN parameter "
                     & "(fix " &  To_String (PI.Name) & ")";
               end if;
            end loop;
         end if;
      end loop;
      --  Checks done when generating glue
      if Model.Configuration.Glue then
         for Each of Model.Interface_View.Flat_Functions loop
            Opt_Part  := Model.Find_Binding (Each.Name);
            --  Check that each function is placed on a partition
            if not Each.Is_Type and then not Opt_Part.Has_Value then
               raise Semantic_Error with
                "In the deployment view, the function " & To_String (Each.Name)
                & " is not bound to any partition!";
            end if;

            --  --  Check that functions have at least one PI
            --  --  with the exception of GUIs and Blackbox devices
            --  if Each.Language /= "gui"
            --     and then Each.Language /= "blackbox_device"
            --     and then Each.Provided.Length = 0
            --  then
            --     raise Semantic_Error with
            --       "Function " & To_String (Each.Name) & " has no provided "
            --        & "interfaces, and dead code is not allowed";
            --  end if;

            --  Check that Simulink functions have exactly one PI and no RI
            --  if (Each.Language    = "simulink"
            --    or Each.Language = "qgenada"
            --    or Each.Language = "qgenc")
            --    and then (Each.Provided.Length /= 1
            --              or Each.Required.Length /= 0)
            --  then
            --   raise Semantic_Error with
            --      "Function " & To_String (Each.Name) & " must contain only "
            --      & "one Provided Interface and no Required Interfaces";
            --  end if;

            --  Check that Simulink/QGen functions's PI is synchronous
            --  if Each.Language    = "simulink"
            --    or Each.Language = "qgenada"
            --    or Each.Language = "qgenc"
            --  then
            --     for PI of Each.Provided loop
            --       if PI.RCM /= Unprotected_Operation
            --           and PI.RCM /= Protected_Operation
            --        then
            --           raise Semantic_Error with "The provided interface of "
            --        & "function " & To_String (Each.Name) & " must be either"
            --       & " protected or unprotected, but not sporadic or cyclic";
            --       end if;
            --    end loop;
            --  end if;

            --  GUI check:
            --  interfaces must all be sporadic
            if Each.Language = "gui"
            then
               for PI of Each.Provided loop
                  if PI.RCM /= Sporadic_Operation then
                     Put_Error ("PI " & To_String (PI.Name) & " shall be "
                        & " sporadic in GUI " & To_String (Each.Name));
                     Found_Error := True;
                  end if;
               end loop;
               for RI of Each.Required loop
                  if RI.RCM /= Sporadic_Operation then
                     Put_Error ("RI " & To_String (RI.Name) & " shall be "
                        & " sporadic in GUI " & To_String (Each.Name));
                     Found_Error := True;
                  end if;
               end loop;
               if Found_Error then
                  raise Semantic_Error with
                     "GUI interfaces must all be sporadic";
               end if;
            end if;

            for PI of Each.Provided loop
               --  Check that functions including at least one (un)protected
               --  interface are located on the same partition as their callers
               if not Each.Is_Type and then (PI.RCM = Protected_Operation
                                          or PI.RCM = Unprotected_Operation)
               then
                  for Remote of PI.Remote_Interfaces loop
                     if not Opt_Part.Unsafe_Just.Bound_Functions.Contains
                       (To_String (Remote.Function_Name))
                     then
                        raise Semantic_Error with "Function "
                        & To_String (Each.Name) & " and function "
                        & To_String (Remote.Function_Name) & " must be located"
                        & " on the same partition in the deployment view, "
                        & "because they share a synchronous interface";
                     end if;
                  end loop;
               end if;

               --  Check that Cyclic PIs are not connected and that they have
               --  no parameters.
               if PI.RCM = Cyclic_Operation and then
                  (PI.Remote_Interfaces.Length > 0 or PI.Params.Length > 0)
               then
                  raise Semantic_Error with "Interface " & To_String (PI.Name)
                  & " in function " & To_String (Each.Name) & " is incorrect: "
                  & "it shall have no parameters and shall not be connected";

                  --  Check that sporadic PIs have at most one IN pararmeter
               elsif PI.RCM = Sporadic_Operation and then
                  (PI.Params.Length > 1 or (PI.Params.Length = 1 and
                  (for all Param of PI.Params => Param.Direction /= param_in)))
               then
                  raise Semantic_Error with "Interface " & To_String (PI.Name)
                  & " in function " & To_String (Each.Name) & " is incorrect: "
                  & "it shall have at most one IN parameter (no OUT param)";
               end if;
            end loop;

            --  Component type/instance checks
            if Each.Is_Type
               and Each.Language /= "ada"
               and Each.Language /= "sdl"
               and Each.Language /= "cpp"
            then
               raise Semantic_Error with "Function " & To_String (Each.Name)
               & " can be a type only if it is implemented in Ada, C++ or SDL"
               & " (not " & To_String (Each.Language) & ")";
            end if;

            if Each.Instance_Of.Has_Value then
               begin
                  declare
                     Corresponding_Type : constant Taste_Terminal_Function :=
                        Model.Interface_View.Flat_Functions.Element
                           (To_String (Each.Instance_Of.Unsafe_Just));
                  begin
                     if not Corresponding_Type.Is_Type then
                        raise Semantic_Error with "Function "
                        & To_String (Each.Name) & " is an instance of "
                        & To_String (Corresponding_Type.Name) & " which is NOT"
                        & " a type";
                     end if;

                     --  Much check that PIs and RIs of type and instance match
                     for PI of Each.Provided loop
                        null;
                     end loop;

                     for RI of Each.Required loop
                        null;
                     end loop;

--                      raise Semantic_Error with "Interface mismatch between "
--                      & "functions " & To_String (Corresponding_Type.Name) &
--                      " (type) and " & To_String (Each.Name) & " (instance)";
                  end;
               exception
                  when Constraint_Error =>
                     --  if the component type is not in the model,
                     --  it may not be an error: it could be a shared type
                     if not Model.Configuration.Shared_Types.Contains
                       (To_String (Each.Instance_Of.Unsafe_Just))
                     then
                        raise Semantic_Error with "Function not found : "
                          & To_String (Each.Instance_Of.Unsafe_Just)
                          & " (specified as type of function "
                          & To_String (Each.Name) & ")";
                     end if;
               end;
            end if;
         end loop;
      end if;
   end Check_Model;

end TASTE.Semantic_Check;
