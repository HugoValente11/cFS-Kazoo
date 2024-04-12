--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

--  Interface View parser

with Ada.Exceptions,
     Ada.Directories,
     Ada.Strings.Fixed,
     Ada.Characters.Handling,
     GNAT.String_Split,
     Ocarina.Instances.Queries,
     Ocarina.Analyzer,
     Ocarina.Options,
     Ocarina.Instances,
     Ocarina.Backends.Properties,
     Ocarina.ME_AADL.AADL_Tree.Nodes,
     Ocarina.ME_AADL.AADL_Instances.Nodes,
     Ocarina.Namet,
     Ocarina.ME_AADL.AADL_Tree.Nutils,
     Ocarina.ME_AADL.AADL_Instances.Nutils,
     Ocarina.ME_AADL.AADL_Instances.Entities,
     TASTE.Backend;

package body TASTE.Interface_View is

   use Ada.Exceptions,
       Ada.Strings.Fixed,
       Ada.Characters.Handling,
       GNAT,
       Ocarina.Instances.Queries,
       Ocarina.Namet,
       Ocarina.Options,
       Ocarina.Instances,
       Ocarina.Backends.Properties,
       Ocarina.ME_AADL.AADL_Instances.Nodes,
       Ocarina.ME_AADL.AADL_Instances.Nutils,
       Ocarina.ME_AADL.AADL_Instances.Entities,
       Ocarina.ME_AADL,
       TASTE.Backend;

   package ATN  renames Ocarina.ME_AADL.AADL_Tree.Nodes;
   package ATNU renames Ocarina.ME_AADL.AADL_Tree.Nutils;

   ------------------------------
   -- Get_Language (as string) --
   ------------------------------

   function Get_Language (E : Node_Id) return String is
      Source_Property : constant Name_Id :=
         Get_String_Name ("source_language");
   begin
      if Is_Defined_List_Property (E, Source_Property) then
         declare
            Source_Language_List : constant List_Id :=
               Get_List_Property (E, Source_Property);
         begin
            if ATNU.Length (Source_Language_List) > 1 then
               raise Interface_Error with "Cannot use more than one language";
            end if;

            return Get_Name_String
               (ATN.Name
                  (ATN.Identifier (ATN.First_Node (Source_Language_List))));
         end;
      else
         return "None";
      end if;
   end Get_Language;

   ----------------------------
   -- Get_RCM_Operation_Kind --
   ----------------------------

   function Get_RCM_Operation_Kind
     (E : Node_Id) return Supported_RCM_Operation_Kind
   is
      RCM_Operation_Kind_N : Name_Id;
      RCM_Operation_Kind : constant Name_Id :=
          Get_String_Name ("taste::rcmoperationkind");
      Unprotected_Name   : constant Name_Id := Get_String_Name ("unprotected");
      Protected_Name     : constant Name_Id := Get_String_Name ("protected");
      Cyclic_Name        : constant Name_Id := Get_String_Name ("cyclic");
      Sporadic_Name      : constant Name_Id := Get_String_Name ("sporadic");
      Event_Name      : constant Name_Id := Get_String_Name ("events");
      Message_Name      : constant Name_Id := Get_String_Name ("message");
      Component_Management_Name      : constant Name_Id :=
       Get_String_Name ("component_management");
      Any_Name           : constant Name_Id := Get_String_Name ("any");
   begin
      if Is_Defined_Enumeration_Property (E, RCM_Operation_Kind) then
         RCM_Operation_Kind_N :=
            Get_Enumeration_Property (E, RCM_Operation_Kind);

         if RCM_Operation_Kind_N = Unprotected_Name then
            return Unprotected_Operation;

         elsif RCM_Operation_Kind_N = Protected_Name then
            return Protected_Operation;

         elsif RCM_Operation_Kind_N = Cyclic_Name then
            return Cyclic_Operation;

         elsif RCM_Operation_Kind_N = Sporadic_Name then
            return Sporadic_Operation;

         elsif RCM_Operation_Kind_N = Event_Name then
            return Event_Operation;

         elsif RCM_Operation_Kind_N = Message_Name then
            return Message_Operation;

         elsif RCM_Operation_Kind_N = Component_Management_Name then
            return Component_Management_Operation;

         elsif RCM_Operation_Kind_N = Any_Name then
            return Any_Operation;
         end if;
      end if;
      raise No_RCM_Error;
   end Get_RCM_Operation_Kind;

   -----------------------
   -- Get_RCM_Operation --
   -----------------------

   function Get_RCM_Operation (E : Node_Id) return Node_Id is
      RCM_Operation : constant Name_Id :=
          Get_String_Name ("taste::rcmoperation");
   begin
      if Is_Subprogram_Access (E) then
         return Corresponding_Instance (E);
      else
         if Is_Defined_Property (E, RCM_Operation) then
            return Get_Classifier_Property (E, RCM_Operation);
         else
            return No_Node;
         end if;
      end if;
   end Get_RCM_Operation;

   --------------------
   -- Get_RCM_Period --
   --------------------

   function Get_RCM_Period (D : Node_Id) return Unsigned_Long_Long is
      RCM_Period : constant Name_Id := Get_String_Name ("taste::rcmperiod");
   begin
      if Is_Defined_Integer_Property (D, RCM_Period) then
         return Get_Integer_Property (D, RCM_Period);
      else
         return 0;
      end if;
   end Get_RCM_Period;

   --------------------
   -- Get_Event_Info --
   --------------------

   function Get_Event_Info (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::eventinfo");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Event_Info;

   --------------------
   -- Get_Event_ID --
   --------------------

   function Get_Event_ID (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::eventid");
   begin
      if Is_Defined_String_Property (D, Event_Name) then
         return Get_String_Property (D, Event_Name);
      else
         return "-1";
      end if;
   end Get_Event_ID;

   --------------------
   -- Get_Event_Type --
   --------------------

   function Get_Event_Type (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::eventtype");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Event_Type;

   --------------------
   -- Get_Message_ID --
   --------------------

   function Get_Message_ID (D : Node_Id) return String is
      Event_Name : constant Name_Id :=
         Get_String_Name ("taste::messageid");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Message_ID;

   --------------------
   -- Get_WCET --
   --------------------

   function Get_WCET (D : Node_Id) return String is
      Event_Name : constant Name_Id :=
         Get_String_Name ("taste::wcet");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_WCET;

   --------------------
   -- Get_Message_Content --
   --------------------

   function Get_Message_Content (D : Node_Id) return String is
      Event_Name : constant Name_Id :=
         Get_String_Name ("taste::messagecontent");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Message_Content;

   --------------------
   -- Get_Message_Size --
   --------------------

   function Get_Message_Size (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::messagesize");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Message_Size;

   --------------------
   -- Get_Store_Message --
   --------------------

   function Get_Store_Message (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::storemessage");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Store_Message;

   --------------------
   -- Get_Target_Component --
   --------------------

   function Get_Target_Component (D : Node_Id) return String is
      Event_Name : constant Name_Id := Get_String_Name ("taste::target_pi");
   begin
      return Get_String_Property (D, Event_Name);
   end Get_Target_Component;

   --------------------------
   -- Get_Ada_Package_Name --
   --------------------------

   function Get_Ada_Package_Name (D : Node_Id) return Name_Id is
      Ada_Package_Name : constant Name_id :=
         Get_String_Name ("taste::ada_package_name");
   begin
      return Get_String_Property (D, Ada_Package_Name);
   end Get_Ada_Package_Name;

   -------------------------------
   -- Get_Ellidiss_Tool_Version --
   -------------------------------

   function Get_Ellidiss_Tool_Version (D : Node_Id) return Name_Id is
      Ellidiss_Tool_Version : constant Name_id :=
         Get_String_Name ("taste::version");
   begin
      return Get_String_Property (D, Ellidiss_Tool_Version);
   end Get_Ellidiss_Tool_Version;

   ---------------------------
   -- Get ASN.1 Module name --
   ---------------------------

   function Get_ASN1_Module_Name (D : Node_Id) return String is
      id : Name_Id;
      ASN1_Module : constant Name_id :=
         Get_String_Name ("deployment::asn1_module_name");
   begin
      if Is_Defined_String_Property (D, ASN1_Module) then
         id := Get_String_Property (D, ASN1_Module);
         return Get_Name_String (id);
      else
         return Get_Name_String (Get_String_Name ("nomodule"));
      end if;
   end Get_ASN1_Module_Name;

   -----------------------
   -- Get_ASN1_Encoding --
   -----------------------

   function Get_ASN1_Encoding (E : Node_Id) return Supported_ASN1_Encoding is
      ASN1_Encoding_N : Name_Id;
      ASN1_Encoding : constant Name_Id := Get_String_Name ("taste::encoding");
      Native_Name   : constant Name_Id := Get_String_Name ("native");
      UPER_Name     : constant Name_Id := Get_String_Name ("uper");
      ACN_Name      : constant Name_Id := Get_String_Name ("acn");
   begin
      if Is_Defined_Enumeration_Property (E, ASN1_Encoding) then
         ASN1_Encoding_N := Get_Enumeration_Property (E, ASN1_Encoding);

         if ASN1_Encoding_N = Native_Name then
            return Native;

         elsif ASN1_Encoding_N = UPER_Name then
            return UPER;

         elsif ASN1_Encoding_N = ACN_Name then
            return ACN;
         end if;
      end if;
      raise Interface_Error with "ASN1 Encoding not set";
      return Default;
   end Get_ASN1_Encoding;

   -------------------------
   -- Get_ASN1_Basic_Type --
   -------------------------

   function Get_ASN1_Basic_Type (E : Node_Id) return Supported_ASN1_Basic_Type
   is
      ASN1_Basic_Type  : constant Name_Id :=
                               Get_String_Name ("taste::asn1_basic_type");
      Sequence_Name    : constant Name_Id := Get_String_Name ("asequence");
      SequenceOf_Name  : constant Name_Id := Get_String_Name ("asequenceof");
      Enumerated_Name  : constant Name_Id := Get_String_Name ("aenumerated");
      Set_Name         : constant Name_Id := Get_String_Name ("aset");
      SetOf_Name       : constant Name_Id := Get_String_Name ("asetof");
      Integer_Name     : constant Name_Id := Get_String_Name ("ainteger");
      Boolean_Name     : constant Name_Id := Get_String_Name ("aboolean");
      Real_Name        : constant Name_Id := Get_String_Name ("areal");
      OctetString_Name : constant Name_Id := Get_String_Name ("aoctetstring");
      Choice_Name      : constant Name_Id := Get_String_Name ("achoice");
      String_Name      : constant Name_Id := Get_String_Name ("astring");
      ASN1_Basic_Type_N : Name_Id;
   begin
      if Is_Defined_Enumeration_Property (E, ASN1_Basic_Type) then
         ASN1_Basic_Type_N := Get_Enumeration_Property (E, ASN1_Basic_Type);

         if ASN1_Basic_Type_N = Sequence_Name then
            return ASN1_Sequence;

         elsif ASN1_Basic_Type_N = SequenceOf_Name then
            return ASN1_SequenceOf;

         elsif ASN1_Basic_Type_N = Enumerated_Name then
            return ASN1_Enumerated;

         elsif ASN1_Basic_Type_N = Set_Name then
            return ASN1_Set;

         elsif ASN1_Basic_Type_N = SetOf_Name then
            return ASN1_SetOf;

         elsif ASN1_Basic_Type_N = Integer_Name then
            return ASN1_Integer;

         elsif ASN1_Basic_Type_N = Boolean_Name then
            return ASN1_Boolean;

         elsif ASN1_Basic_Type_N = Real_Name then
            return ASN1_Real;

         elsif ASN1_Basic_Type_N = OctetString_Name then
            return ASN1_OctetString;

         elsif ASN1_Basic_Type_N = Choice_Name then
            return ASN1_Choice;

         elsif ASN1_Basic_Type_N = String_Name then
            return ASN1_String;

         else
            raise Program_Error with "Undefined choice "
              & Get_Name_String (ASN1_Basic_Type_N);
         end if;
      end if;
      raise Interface_Error with "ASN.1 Basic type undefined!";
      return ASN1_Unknown;
   end Get_ASN1_Basic_Type;

   ---------------------------
   -- AST Builder Functions --
   ---------------------------

   function Parse_Interface_View (Interface_Root : Node_Id)
                                  return Complete_Interface_View
   is
      --  use type Functions.Vector;
      use type Channels.Vector;
      use type Ctxt_Params.Vector;
      use type Parameters.Vector;
      --  use type Connection_Maps.Map;
      System                 : Node_Id;
      Success                : Boolean;
      Functions              : Function_Maps.Map;
      Routes_Map             : Connection_Maps.Map;
      End_To_End_Connections : Channels.Vector;
      Current_Function       : Node_Id;

      --  Parse a connection
      function Parse_Connection (Conn : Node_Id) return Optional_Connection is
         use Option_Connection;

         Channel_Name : constant String := AIN_Case (Conn);
         Channels     : String_Vectors.Vector := String_Vectors.Empty_Vector;

         Caller  : constant Node_Id := AIN.Item (AIN.First_Node
                                         (AIN.Path (AIN.Destination (Conn))));
         Callee  : constant Node_Id := AIN.Item (AIN.First_Node
                                         (AIN.Path (AIN.Source (Conn))));
         PI_Name : Name_Id;  --  None in case of cyclic interface
         RI_Name : constant Name_Id := Get_Interface_Name
                              (Get_Referenced_Entity (AIN.Destination (Conn)));
      begin
         --  If RI_Name has no value it means the interface view misses the
         --  AADL property "TASTE::InterfaceName". Not supported.
         if RI_Name = No_Name then
            raise Interface_Error with "Interface view contains errors "
              & "(Missing TASTE::InterfaceName properties)"
              & ASCII.CR & ASCII.LF
              & "        Try updating it with the editor (run taste)";
         end if;

         --  Filter out connections if the PI is cyclic (not a connection!)
         if Get_RCM_Operation_Kind
           (Get_Referenced_Entity (AIN.Destination (Conn))) = Cyclic_Operation
         then
            return Option_Connection.Nothing;
         end if;

         PI_Name := Get_Interface_Name
           (Get_Referenced_Entity (AIN.Source (Conn)));

         Channels := Channels & Channel_Name;

         return Just (Connection'(
                      Channels     => Channels,
                      Caller       =>
                        (if Kind (Caller) = K_Subcomponent_Access_Instance
                         then US ("_env")
                         else US (AIN_Case (Caller))),
                      Callee       =>
                        (if Kind (Callee) = K_Subcomponent_Access_Instance
                         then US ("_env")
                         else US (AIN_Case (Callee))),
                      PI_Name      => US (Get_Name_String (PI_Name)),
                      RI_Name      => US (Get_Name_String (RI_Name))));
      end Parse_Connection;

      --  Create a vector of connections for a given system
      --  This vector will then be filtered to connect end-to-end functions
      --  once the system is flattened
      function Parse_System_Connections (System : Node_Id)
         return Channels.Vector
      is
         use Option_Connection;
         Conn     : Node_Id;
         Result   : Channels.Vector;
         Opt_Conn : Optional_Connection;
      begin
         if Present (AIN.Connections (System)) then
            Conn := AIN.First_Node (AIN.Connections (System));
            while Present (Conn) loop
               Opt_Conn := Parse_Connection (Conn);
               if Opt_Conn.Has_Value then
                  Result := Result & Opt_Conn.Unsafe_Just;
               end if;
               Conn := AIN.Next_Node (Conn);
            end loop;
         end if;
         return Result;
      end Parse_System_Connections;

      --  Parse an individual context parameter, timer, or implementation
      function Parse_CP (Subco : Node_Id) return Context_Parameter is
         CP_ASN1 : constant Node_Id    := Corresponding_Instance (Subco);
         NA      : constant Name_Array := Get_Source_Text (CP_ASN1);
         Name    : constant String := AIN_Case (Subco);
         Sort    : constant String :=
             Get_Name_String (Get_Type_Source_Name (CP_ASN1));
         Default_Value : Unbounded_String;
      begin
         if Sort = "Timer" then
            Default_Value := US ("");
         elsif Sort = "Taste-Implementation" then
            --  A function can have multiple implementations. They are stored
            --  as DATA sections, like context parameters. The Default value
            --  is used to retrieve the implementation language.
            Default_Value := US
                 (TASTE.Backend.Map_Language (Get_Language (CP_ASN1)));
         else
            Default_Value := US (Get_Name_String (Get_String_Property
                                       (CP_ASN1, "taste::fs_default_value")));
         end if;

         return Context_Parameter'(
            Name           => US (Name),
            Sort           => US (Sort),
            Default_Value  => Default_Value,
            ASN1_Module    => US (Get_ASN1_Module_Name (CP_ASN1)),
            ASN1_File_Name => (if NA'Length > 0 then
                               Just (US (Get_Name_String (NA (1))))
                               else Option_UString.Nothing));
      exception
         when others => raise Function_Error with Name;
      end Parse_CP;

      --  Parse a single parameter of an interface
      --  * Name                (Unbounded string)
      --  * Sort                (Unbounded string)
      --  * ASN1_Module         (Unbounded string)
      --  * ASN1_Basic_Type     (Supported_ASN1_Basic_Type)
      --  * ASN1_File_Name      (Unbounded string)
      --  * Encoding            (Supported_ASN1_Encoding)
      --  * Direction           (Parameter_Direction: IN or OUT)
      function Parse_Parameter (Param_I : Node_Id) return ASN1_Parameter is
         Asntype : constant Node_Id := Corresponding_Instance (Param_I);
      begin
         return ASN1_Parameter'(
             Name => US (AIN_Case (Param_I)),
             Sort => US (Get_Name_String (Get_Type_Source_Name (Asntype))),
             ASN1_Module =>
                 US (Get_Name_String (Get_Ada_Package_Name (Asntype))),
             ASN1_Basic_Type => Get_ASN1_Basic_Type (Asntype),
             ASN1_File_Name =>
                US (Get_Name_String (Get_Source_Text (Asntype)(1))),
             Encoding => Get_ASN1_Encoding (Param_I),
             Direction => (if AIN.Is_In (Param_I)
                           then param_in else param_out));
      end Parse_Parameter;

      --  Parse a function interface :
      --  * Name                (Unbounded string)
      --  * Params              (Parameters.Vector)
      --  * RCM                 (Supported_RCM_Operation_Kind)
      --  * Period_Or_MIAT      (Unsigned long long)
      --  * WCET_ms             (Optional unsigned long long)
      --  * Queue_Size          (Optional unsigned long long)
      --  * Priority            (Optional unsigned long long)
      --  * Dispatch offset     (Optional unsigned long long)
      --  * Stack Size          (Optional unsigned long long)
      --  * User_Properties     (Property_Maps.Map)
      function Parse_Interface (If_I : Node_Id) return Taste_Interface is
         Name    : constant Name_Id := Get_Interface_Name (If_I);
         CI      : constant Node_Id := Corresponding_Instance (If_I);
         Result  : Taste_Interface;
         Sub_I   : constant Node_Id := Get_RCM_Operation (If_I);
         Param_I : Node_Id;
      begin
         pragma Assert (Present (Sub_I));
         --  Keep compatibility with 1.2 models for the interface name
         Result.Name := (if Name = No_Name then US (AIN_Case (If_I)) else
                         US (Get_Name_String (Name)));
         Result.Queue_Size :=
           (if Kind (If_I) = K_Subcomponent_Access_Instance
            and then Is_Defined_Property (CI, "taste::associated_queue_size")
            then
               Just (Get_Integer_Property (CI, "taste::associated_queue_size"))
            else Option_ULL.Nothing);
         Result.RCM := Get_RCM_Operation_Kind (If_I);
         Result.Period_Or_MIAT := Get_RCM_Period (If_I);
         --  Result.WCET_ms := Get_Upper_WCET (If_I);
         Result.WCET_ms := US (Get_WCET (If_I));
         Result.Event_Info := US (Get_Event_Info (If_I));
         Result.Event_Type := US (Get_Event_Type (If_I));
         Result.Event_ID := US (Get_Event_ID (If_I));
         Result.Message_ID := US (Get_Message_ID (If_I));
         Result.Message_Content := US (Get_Message_Content (If_I));
         Result.Message_Size := US (Get_Message_Size (If_I));
         Result.Store_Message := US (Get_Store_Message (If_I));
         Result.Target_Name := US (Get_Target_Component (If_I));

         Result.User_Properties := Get_Properties_Map (If_I);
         --  Get various properties as 1st class citizens in the AST
         for P of Result.User_Properties loop
            if P.Name = "Taste::Associated_Queue_Size"
            then
               Result.Queue_Size :=
                   Just (Unsigned_Long_Long'Value (To_String (P.Value)));
            elsif P.Name = "Taste::Interface_Priority" then
               Result.Priority := Integer'Value (To_String (P.Value));
            elsif P.Name = "Taste::Interface_Cyclic_Offset" then
               Result.Dispatch_Offset := Integer'Value (To_String (P.Value));
            elsif P.Name = "Taste::Interface_Stack_Size" then
               Result.Stack_Size := Integer'Value (To_String (P.Value));
            end if;
         end loop;
         --  Parameters:
         if not Is_Empty (AIN.Features (Sub_I)) then
            Param_I := AIN.First_Node (AIN.Features (Sub_I));
            while Present (Param_I) loop
               if Kind (Param_I) = K_Parameter_Instance then
                  Result.Params := Result.Params & Parse_Parameter (Param_I);
               end if;
               Param_I := AIN.Next_Node (Param_I);
            end loop;
         end if;
         return Result;
      exception
         when No_RCM_Error =>
            raise Interface_Error with "Interface " & To_String (Result.Name)
                                       & " has no kind "
                                       & "(periodic, sporadic ...)";
      end Parse_Interface;

      --  Helper function - return the context name above the current one
      --  Needed to resolve the connections to "_env".
      function Parent_Context (Context : String) return String is
      begin
         for Each in Routes_Map.Iterate loop
            if Context /= Connection_Maps.Key (Each) then
               for Conn of Connection_Maps.Element (Each) loop
                  if Conn.Caller = Context or Conn.Callee = Context then
                     return Connection_Maps.Key (Each);
                  end if;
               end loop;
            end if;
         end loop;
         return "ERROR";
      end Parent_Context;

      --  Recursive function making jumps to find the provided interface
      --  connected to a required interface. It returns a Remote Entity,
      --  which contains the name of the remote PI and the name of the function
      function Rec_Jump (From, RI      : String;
                         Going_Out     : Boolean := False;
                         Via_Channels  : in out String_Vectors.Vector)
                         return Remote_Entities.Vector is

         Context     : constant String :=
           (if Functions.Contains (Key => From)
            then To_String (Functions.Element (Key => From).Context)
            else (if not Going_Out then From else Parent_Context (From)));
         Source      : constant String :=
           (if Context /= From then From else "_env");
         Result      : Remote_Entity :=
            (US ("Not found!"), US ("Not found!"), US ("Not found!"), US (""));
         Results     : Remote_Entities.Vector := Remote_Entities.Empty_Vector;
         SubResults  : Remote_Entities.Vector := Remote_Entities.Empty_Vector;
         Connections : Channels.Vector := Channels.Empty_Vector;
         Set_Going_Out : Boolean := False;
      begin
         --  Note: There is a limitation in the interface view when there are
         --  nested functions. At the border of a nested function, there can
         --  be only ONE function of a given name. This means that it is
         --  impossible to have two PIs with the same name, even in different
         --  functions, if they are located in the same nested context.
         --  * This is NOT RIGHT and should be fixed by Ellidiss *

         --  Retrieve the list of connections of the source function context
         if Routes_Map.Contains (Key => Context) then
            Connections := Routes_Map.Element (Key => Context);
         end if;

         for Each of Connections loop
            Put_Debug ("Analyzing connection "
               & To_String (Each.RI_Name)
               & " <-> "
               & To_String (Each.PI_Name));
            if Each.Caller = Source and Each.RI_Name = US (RI) then
               --  Found the connection in the current context
               --  Now recurse if the callee is a nested block,
               --  and return otherwise (if destination is a function)
               if Each.Callee = "_env" then
                  Set_Going_Out := True;
               end if;
               Via_Channels := Via_Channels & Each.Channels;

               if Functions.Contains (Key => To_String (Each.Callee)) then
                  Result := (Function_Name  => Each.Callee,
                        Language       =>
                          US (Language_Spelling
                            (Functions (To_String (Each.Callee)))),
                        Interface_Name => Each.PI_Name,
                        Instance_Of    =>
                          Functions (To_String (Each.Callee)).Instance_Of);
                  Results.Append (Result);
               else
                  SubResults := Rec_Jump (From => (if not Set_Going_Out
                        then To_String (Each.Callee)
                        else Context),
                     Going_Out    => Set_Going_Out,
                     RI           => To_String (Each.PI_Name),
                     Via_Channels => Via_Channels);
                  for SubResult of SubResults loop
                     begin
                        Results.Append (SubResult);
                     end;
                  end loop;
               end if;
            end if;
         end loop;
         return Results;
      end Rec_Jump;

      --  Parse the following content of a single function :
      --  * Name
      --  * Language
      --  * Zip File
      --  * Context Parameters
      --  * User Properties (from TASTE_IV_Properties.aadl)
      --  * Timers
      --  * Provided and Required Interfaces
      function Parse_Function (Prefix : String;
                               Name   : String;
                               Inst   : Node_Id) return Taste_Terminal_Function
      is
         Result      : Taste_Terminal_Function;
         --  To get the optional zip filename where user code is stored:
         Source_Text : constant Name_Array := Get_Source_Text (Inst);
         Zip_Id      : Name_Id;
         --  To get the context parameters
         Subco       : Node_Id;
         --  To get the provided and required interfaces
         PI_Or_RI    : Node_Id;
         Iface       : Taste_Interface;
      begin
         Result.Name          := US (Name);
         Result.Instance_Name := US (Name);
         Result.Full_Prefix   := (if Prefix'Length > 0 then Just (US (Prefix))
                                 else Option_UString.Nothing);
         --  Result.Language      := Get_Source_Language (Inst);
         Result.Language      := US (Get_Language (Inst));
         if Source_Text'Length /= 0 then
            Zip_Id          := Source_Text (1);
            Result.Zip_File := Just (US (Get_Name_String (Zip_Id)));
         end if;
         --  Parse context parameters (including timers)
         if Present (AIN.Subcomponents (Inst)) then
            Subco := AIN.First_Node (AIN.Subcomponents (Inst));
            while Present (Subco) loop
               case Get_Category_Of_Component (Subco) is
                  when CC_Data =>
                     declare
                        CP : Context_Parameter;
                     begin
                        CP := Parse_CP (Subco);
                        if CP.Sort = "Timer" then
                           Result.Timers := Result.Timers
                                            & To_String (CP.Name);
                        elsif CP.Sort = "Taste-directive" then
                           Result.Directives := Result.Directives & CP;
                        elsif CP.Sort = "Simulink-Tunable-Parameter" then
                           Result.Simulink := Result.Simulink & CP;
                        elsif CP.Sort = "Taste-Implementation" then
                           Result.Implems := Result.Implems & CP;
                        else
                           --  Standard Context Parameter (for C/C++/Ada)
                           Result.Context_Params := Result.Context_Params & CP;
                        end if;
                     exception
                        when E : others =>
                           raise Function_Error with
                           "In function " & Name & ": Failed parsing value of"
                           & " context parameter - " & Exception_Message (E);
                     end;
                  when others =>
                     null;
               end case;
               Subco := AIN.Next_Node (Subco);
            end loop;
         end if;
         --  Parse provided and required interfaces
         if Present (AIN.Features (Inst)) then
            PI_Or_RI := AIN.First_Node (AIN.Features (Inst));
            while Present (PI_Or_RI) loop
               Iface                 := Parse_Interface (PI_Or_RI);
               Iface.Parent_Function := Result.Name;
               Iface.Language        := Result.Language;
               if AIN.Is_Provided (PI_Or_RI) then
                  Result.Provided.Insert (Key      => To_String (Iface.Name),
                                          New_Item => Iface);
               else
                  Result.Required.Insert (Key      => To_String (Iface.Name),
                                          New_Item => Iface);
               end if;
               PI_Or_RI := AIN.Next_Node (PI_Or_RI);
            end loop;
         end if;
         Result.User_Properties := Get_Properties_Map (Inst);

         --  Check User properties for first-class attributes
         --  Currently: component type and instance
         for Each of Result.User_Properties loop
            if (Each.Name = "TASTE_IV_Properties::is_Component_Type"
            or To_Lower (To_String (Each.Name)) = "taste::is_component_type")
            and then To_Lower (To_String (Each.Value)) = "true"
            then
               Put_Debug ("Component type found : " & To_String (Each.Value));
               Result.Is_Type := True;
            end if;
            if Each.Name = "Taste::Startup_Priority"
            then
               Result.F_Priority := Just (Unsigned_Long_Long'Value
                  (To_String (Each.Value)));
            end if;
            if Each.Name = "Taste::Needs_datastore"
            then
               Result.DataStore := Each.Value;
            end if;
            if Each.Name = "Taste::Datastore_size"
            then
               Result.DataStoreSize := Each.Value;
            end if;
            if Each.Name = "Taste::FDIR"
            then
               Result.FDIR := Each.Value;
            end if;
            if Each.Name = "TASTE_IV_Properties::is_instance_of"
            then
               --  Old form, should not appear in new designs
               Result.Instance_Of := Each.Value;
            elsif Each.Name = "Taste::Instances_Min" then
               Result.Min_Instances := Integer'Value (To_String (Each.Value));
            elsif Each.Name = "Taste::Instances_Max" then
               Result.Max_Instances := Integer'Value (To_String (Each.Value));
            elsif Each.Name = "Taste::is_Instance_Of"
            then
               --  New form, however should be deprecated soon
               --  String "foo::bar::hello.world" -> we have to extract hello
               declare
                  Inp : constant String := To_String (Each.Value);
                  Sep1 : constant String := "::";
                  nb1  : constant Natural :=
                    Ada.Strings.Fixed.Count (Inp, sep1);
                  sep2 : constant String := ".";
                  From : Natural := Inp'First;
                  To : Natural;
               begin
                  for I in 0 .. nb1 loop
                     To := Index (Inp, Sep1, From => From);
                     if To = 0 then
                        To := Inp'Last + 1;
                     end if;
                     if I < nb1 then
                        From := To + 2;
                     end if;
                  end loop;
                  To := Index (Inp (From .. To - 1), Sep2, From => From);
                  Result.Instance_Of := US (Inp (From .. To - 1));
               end;
               Put_Debug ("Instance : " & To_String (Result.Instance_Of));
            elsif Each.Name = "Taste::is_Instance_Of2" then
               --  Each.Value has the form "foo.other"
               --  We must keep only "foo"
               declare
                  Inp : constant String := To_String (Each.Value);
                  Sep : constant String := ".";
                  Idx : constant Natural :=
                    Index (Inp, Sep, From => Inp'First);
               begin
                  Result.Instance_Of := US (Inp (Inp'First .. Idx - 1));
               exception
                  when others =>
                     Put_Error ("Incorrect instance: "
                                & To_String (Each.Value));
               end;
               Put_Debug ("Instance: " & To_String (Result.Instance_Of));
            end if;
         end loop;

         return Result;
      exception
         when Error : Interface_Error =>
            raise Function_Error with "Function " & To_String (Result.Name)
                                      & " : " & Exception_Message (Error);
      end Parse_Function;

      --  Recursive parsing of a system made of nested functions
      procedure Rec_Function (Prefix : String  := "";
                             Context : String := "_Root";
                             Func   : Node_Id)
        with Pre => Prefix'Length <= Integer'Last - 1
      is
         Inner        : Node_Id;
         Is_Terminal  : Boolean := True;
         CI           : constant Node_Id := Corresponding_Instance (Func);
         Name         : constant String := AIN_Case (Func);
         Next_Prefix  : constant String := Prefix &
                           (if Prefix'Length > 0 then "." else "") & Name;
         Terminal_Fn  : Taste_Terminal_Function;
      begin
         if No (CI) then
            raise Interface_Error
              with "Element " & Next_Prefix & " is not properly defined";
         end if;
         --  Put_Debug ("Parsing " & Name);

         case Get_Category_Of_Component (CI) is
            when CC_System =>
               if Present (AIN.Subcomponents (CI)) then
                  Inner := AIN.First_Node (AIN.Subcomponents (CI));
                  while Present (Inner) loop
                     --  Avoid DATA subcomponents
                     if Get_Category_Of_Component
                         (Corresponding_Instance (Inner)) = CC_System
                     then
                        Rec_Function (Prefix  => Next_Prefix,
                                      Context => Name,
                                      Func    => Inner);
                        --  At least one sub-function
                        Is_Terminal := False;
                     end if;
                     Inner := AIN.Next_Node (Inner);
                  end loop;

                  --  Inner components may not be functions but properties
                  if not Is_Terminal
                  then
                     Routes_Map.Insert (Key      => Name,
                                        New_Item =>
                                                Parse_System_Connections (CI));
                  end if;
               end if;

               if Is_Terminal
               then
                  Terminal_Fn := Parse_Function (Prefix => Prefix,
                                                 Name   => Name,
                                                 Inst   => CI);
                  Terminal_Fn.Context := US (Context);
                  Functions.Insert (Key       => Name,
                                    New_Item  => Terminal_Fn);
                  Put_Debug ("Added terminal function: " & Name);
               end if;
            when others =>
               --  There can be DATA subcomponents
               null;
         end case;
      end Rec_Function;
   begin
      Put_Info ("Parsing Interface View");
      if No (Interface_Root) then
         raise Interface_Error with "Interface View parsing error";
      end if;

      Success := Ocarina.Analyzer.Analyze (AADL_Language, Interface_Root);

      if not Success then
         raise Interface_Error with "Could not analyse Interface View";
      end if;

      Ocarina.Options.Root_System_Name :=
        Get_String_Name ("interfaceview.others");

      System := Root_System (Instantiate_Model (Root => Interface_Root));

      if No (System) then
         raise Interface_Error with "Could not instantiate Interface View";
      end if;

      Current_Function := AIN.First_Node (AIN.Subcomponents (System));
      --  Parse functions recursively
      while Present (Current_Function) loop
         Rec_Function (Func => Current_Function);
         Current_Function := AIN.Next_Node (Current_Function);
      end loop;

      --  Routes_Map contains all connections including the nested ones
      --  It is used in Rec_Jump to resolve all end-to-end connections
      Routes_Map.Insert (Key      => "_Root",
                         New_Item => Parse_System_Connections (System));

      --  Resolve the PI-RI connections within the functions
      for Each of Functions loop
         Put_Debug ("Analyzing function "
            & To_String (Each.Name));
         for RI of Each.Required loop
            declare
               Via_Channels : String_Vectors.Vector;
               --  From a RI, follow the connection until the remote PI
               --  Update list of visited channels on the spot
               Remotes : constant Remote_Entities.Vector := Rec_Jump
                 (To_String (Each.Name),
                  To_String (RI.Name),
                  Via_Channels => Via_Channels);
            begin
               for Remote of Remotes loop
                  begin
                     Put_Debug (To_String (Each.Name)
                        & " is connected to remote function "
                        & To_String (Remote.Function_Name));
                     if Remote.Function_Name /= "Not found!" then
                        RI.Remote_Interfaces.Append (Remote);
                        --  Update RCM of the RI to match the one of
                        --  the remote PI (by default it is set to Any)
                        RI.RCM :=
                          Functions (To_String (Remote.Function_Name)).Provided
                            (To_String (Remote.Interface_Name)).RCM;

                        --  Update list of end to end connections with RI->PI
                        End_To_End_Connections := End_To_End_Connections
                          & (Channels     => Via_Channels,
                             Caller       => Each.Name,
                             Callee       => Remote.Function_Name,
                             RI_Name      => RI.Name,
                             PI_Name      => Remote.Interface_Name);
                     end if;
                  end;
               end loop;

            end;
         end loop;
      end loop;
      --  Do the same for the PIs - they could not be updated at the same time
      --  because when we iterate on the functions, we can modify only the
      --  current function - we cannot touch the one with the remote PI.
      for Each of Functions loop
         for PI of Each.Provided loop

            --  Add periodic PIs to the list of connections
            if PI.RCM = Cyclic_Operation and not Each.Is_Type then
               End_To_End_Connections := End_To_End_Connections
                 & (Channels     => String_Vectors.Empty_Vector,
                    Caller       => US ("ENV"),
                    Callee       => Each.Name,
                    RI_Name      => PI.Name,
                    PI_Name      => PI.Name);
            end if;

            for Fn of Functions loop
               for RI of Fn.Required loop
                  for Remote of RI.Remote_Interfaces loop
                     if Remote.Function_Name = Each.Name and then
                       Remote.Interface_Name = PI.Name
                     then
                        Put_Debug ("Appending (2) remote interface for "
                           & To_String (Remote.Function_Name));
                        PI.Remote_Interfaces.Append
                          (Remote_Entity'(Function_Name  => Fn.Name,
                                          Language       =>
                                            US (Language_Spelling (Fn)),
                                          Interface_Name => RI.Name,
                                          Instance_Of => Fn.Instance_Of));
                     end if;
                  end loop;
               end loop;
            end loop;
         end loop;
      end loop;

      --  Debug: check end-to-end connection paths
      --  for C of End_To_End_Connections loop
      --     Put_Debug ("From " & To_String (C.Caller) & "."
      --                & To_String (C.RI_Name) & " to " & To_String (C.Callee)
      --                & "." & To_String (C.PI_Name) & " via ...");
      --     for P of C.Channels loop
      --        Put_Debug ("... " & P);
      --     end loop;
      --  end loop;

      return IV_AST : constant Complete_Interface_View :=
        (Flat_Functions => Functions,
         Connections    => End_To_End_Connections);
   end Parse_Interface_View;

   procedure Rename_Provided_Interface (IV    : in out Complete_Interface_View;
                                        Func  : String;
                                        Iface : String;
                                        To    : String) is
      FV        : Taste_Terminal_Function :=
                    IV.Flat_Functions.Element (Key => Func);
      FV_If     : Taste_Interface :=
                    FV.Provided.Element (Key => Iface);
   begin
      FV_If.Name := US (To);
      FV.Provided.Delete (Key       => Iface);
      FV.Provided.Insert  (Key      => To,
                           New_Item => FV_If);
      --  Now fix all references to this interface
      for Each of IV.Flat_Functions loop
         for RI of Each.Required loop
            for Remote of RI.Remote_Interfaces loop
               if Remote.Function_Name = FV.Name and then
                 Remote.Interface_Name = US (Iface)
               then
                  Remote.Interface_Name := FV_If.Name;
               end if;
            end loop;
         end loop;
      end loop;
   end Rename_Provided_Interface;

   procedure Rename_Required_Interface (IV    : in out Complete_Interface_View;
                                        Func  : String;
                                        Iface : String;
                                        To    : String) is
      FV        : Taste_Terminal_Function :=
                    IV.Flat_Functions.Element (Key => Func);
      FV_If     : Taste_Interface :=
                    FV.Provided.Element (Key => Iface);
   begin
      FV_If.Name := US (To);
      FV.Required.Delete (Key       => Iface);
      FV.Required.Insert  (Key      => To,
                           New_Item => FV_If);
      --  Now fix all references to this interface
      for Each of IV.Flat_Functions loop
         for PI of Each.Provided loop
            for Remote of PI.Remote_Interfaces loop
               if Remote.Function_Name = FV.Name and then
                 Remote.Interface_Name = US (Iface)
               then
                  Remote.Interface_Name := FV_If.Name;
               end if;
            end loop;
         end loop;
      end loop;
   end Rename_Required_Interface;

   function Function_To_Template (F : Taste_Terminal_Function)
                                  return Func_As_Template
   is
      use Ctxt_Params;
      use Template_Vectors;
      Result               : Func_As_Template;

      List_Of_PIs,
      List_Of_Events,
      List_Of_RIs,
      List_Of_Sync_PIs     : Tag;

      Instance_Identifiers : Tag;  --  Name of each instance (list i_1, i_2...)

      List_Of_ASync_PIs,
      ASync_PI_Kind, --  Can be Cyclic or Sporadic
      ASync_PI_Param_Name,
      ASync_PI_Is_Connected,
      ASync_PI_Param_Type  : Vector_Tag;

      Count_Cyclic_PIs : Natural := 0;

      List_Of_Sync_RIs,
      Sync_RIs_Parent_Instance_Of,
      Sync_RIs_Parent      : Vector_Tag;   --  Parent function of the sync RI

      List_Of_ASync_RIs,
      ASync_RIs_Parent,
      ASync_RI_Param_Name,
      ASync_RI_Param_Type  : Vector_Tag;   --  Parent function of the async RI

      Timers               : Tag;

      CP_Names,            --  CP = Context Parameters
      CP_Types,
      CP_Values,
      CP_Asn1Modules,
      CP_Filenames         : Vector_Tag;

      PIs_Have_Params,     --  True if at least one PI has an ASN.1 parameter
      RIs_Have_Params      : Boolean := False;   -- Same for RI
      Interface_Tmplt      : Translate_Set;
      --  Optional graphical coordinates of a function:
      X1, X2, Y1, Y2 : Unbounded_String := US ("0");
   begin
      Result.Header := +Assoc ("Name", F.Name)
        & Assoc ("Language",        Language_Spelling (F))
        & Assoc ("Has_Context",     (Length (F.Context_Params) > 0))
        & Assoc ("Min_Instances",   F.Min_Instances)
        & Assoc ("Max_Instances",   F.Max_Instances)
        & Assoc ("Instance_Number", F.Instance_Number)
        & Assoc ("Instance_Name",   F.Instance_Name);

      --  When the number of instances of a function is variable (i.e. user
      --  can create them at runtime) the template gets the list of instance
      --  names so that it is possible to generate code to manage the list
      --  of active instances. Note, the creation of instances at runtime is
      --  not dynamic in TASTE - they are all created at initialization. But
      --  their startup() function however is called until they have been
      --  "created" by user code.
      if F.Min_Instances /= F.Max_Instances then
         for I in 1 .. F.Max_Instances loop
            declare
               Id : constant String :=
                   To_String (F.Instance_Name) & "_" & Strip_String (I'Img);
            begin
               Instance_Identifiers := Instance_Identifiers & Id;
            end;
         end loop;
      end if;

      --  Add context parameters details
      for Each of F.Context_Params loop
         CP_Names       := CP_Names       & Each.Name;
         CP_Types       := CP_Types       & Each.Sort;
         CP_Values      := CP_Values      & Each.Default_Value;
         CP_Asn1Modules := CP_Asn1Modules & Each.ASN1_Module;
         CP_Filenames   := CP_Filenames
            & Each.ASN1_File_Name.Value_Or (US (""));
      end loop;

      --  Add list of all PI names (both synchronous and asynchronous)
      for Each of F.Provided loop
         --  Note: some backends need to have access to the function
         --  user defined properties, and implementation language
         --  They are added here. The user-defined properties
         --  of the interfaces themselves are also part of the template
         --  with the IF_ prefix (see in Interface_To_Template)
         Interface_Tmplt :=
           Join_Sets (Each.Interface_To_Template,
                      Properties_To_Template (F.User_Properties))
           & Assoc ("Direction", "PI")
           & Assoc ("Parent_Instance_Of", To_String (F.Instance_Of))
           & Assoc ("Language",  Language_Spelling (F));

         Result.Provided := Result.Provided & Interface_Tmplt;
         --  Note: List of PIs include timers, while List_Of_(A)Sync do not.
         List_Of_PIs     := List_Of_PIs & Each.Name;
         List_Of_Events     := List_Of_Events & Each.Event_ID;
         case Each.RCM is
            when Cyclic_Operation | Sporadic_Operation =>
               if Each.RCM = Cyclic_Operation then
                  Count_Cyclic_PIs := Count_Cyclic_PIs + 1;
               end if;
               if not Each.Is_Timer then
                  List_Of_ASync_PIs := List_Of_ASync_PIs & Each.Name;
                  ASync_PI_Kind := ASync_PI_Kind & Each.RCM'Img;
                  --  Keep a flag for non-connected async PIs,
                  --  useful in templates to skip unnecessary code
                  ASync_PI_Is_Connected := ASync_PI_Is_Connected
                    & (not Each.Remote_Interfaces.Is_Empty);
                  if not Each.Params.Is_Empty then
                     ASync_PI_Param_Name := ASync_PI_Param_Name
                       & Each.Params.First_Element.Name;
                     ASync_PI_Param_Type := ASync_PI_Param_Type &
                       Each.Params.First_Element.Sort;
                  else
                     ASync_PI_Param_Name := ASync_PI_Param_Name & "";
                     ASync_PI_Param_Type := ASync_PI_Param_Type & "";
                  end if;
               end if;
            when others =>
               List_Of_Sync_PIs := List_Of_Sync_PIs & Each.Name;
         end case;
         if Each.Params.Length > 0 then
            PIs_Have_Params := True;
         end if;
      end loop;

      --  Add list of all RI names (both synchronous and asynchronous)
      for Each of F.Required loop
         Interface_Tmplt :=
           Join_Sets (Each.Interface_To_Template,
                      Properties_To_Template (F.User_Properties))
           & Assoc ("Direction",       "RI")
           & Assoc ("Language",        Language_Spelling (F));

         Result.Required := Result.Required & Interface_Tmplt;
         List_Of_RIs     := List_Of_RIs & Each.Name;
         case Each.RCM is
            when Cyclic_Operation | Sporadic_Operation =>
               List_Of_ASync_RIs := List_Of_ASync_RIs & Each.Name;
               if not Each.Params.Is_Empty then
                  ASync_RI_Param_Name := ASync_RI_Param_Name
                    & Each.Params.First_Element.Name;
                  ASync_RI_Param_Type := ASync_RI_Param_Type &
                    Each.Params.First_Element.Sort;
               else
                  ASync_RI_Param_Name := ASync_RI_Param_Name & "";
                  ASync_RI_Param_Type := ASync_RI_Param_Type & "";
               end if;
               --  Find remote function name (only one remote per RI)
               if not Each.Remote_Interfaces.Is_Empty then
                  --  We can spot non-connected RIs..
                  Async_RIs_Parent  := Async_RIs_Parent
                    & Each.Remote_Interfaces.First_Element.Function_Name;
               else
                  Async_RIs_Parent := ASync_RIs_Parent & "";
               end if;
            when others =>
               List_Of_Sync_RIs  := List_Of_Sync_RIs & Each.Name;
               if not Each.Remote_Interfaces.Is_Empty then
                  Sync_RIs_Parent   := Sync_RIs_Parent
                     & Each.Remote_Interfaces.First_Element.Function_Name;
                  Sync_RIs_Parent_Instance_Of := Sync_RIs_Parent_Instance_Of
                     & Each.Remote_Interfaces.First_Element.Instance_Of;
               end if;
         end case;
         if Each.Params.Length > 0 then
            RIs_Have_Params := True;
         end if;
      end loop;

      --  Add list of timers (names)
      for Each of F.Timers loop
         Timers := Timers & Each;
      end loop;

      --  If there is a Coordinate property, extract the 4 values
      --  (Split the string)
      for P of F.User_Properties loop
         if P.Name = "Taste::coordinates" then
            --  P.Value = x1 y1 x2 y2 (four numbers separated with space)
            declare
               Subs : String_Split.Slice_Set;
               Seps : constant String := " ";
            begin
               String_Split.Create (S          => Subs,
                                    From       => To_String (P.Value),
                                    Separators => Seps,
                                    Mode       => String_Split.Multiple);
               if Integer (String_Split.Slice_Count (Subs)) = 4 then
                  X1 := US (String_Split.Slice (Subs, 1));
                  Y1 := US (String_Split.Slice (Subs, 2));
                  X2 := US (String_Split.Slice (Subs, 3));
                  Y2 := US (String_Split.Slice (Subs, 4));
               end if;
            end;
         end if;
      end loop;

      --  Setup the mapping for the template (processed by function.tmplt)
      Result.Header :=
        Join_Sets (Result.Header,
                   Properties_To_Template (F.User_Properties))
        & Assoc ("Zip_File",
                 (if not F.Zip_File.Has_Value
                  then ""
                  else Ada.Directories.Full_Name
                   (To_String (F.Zip_File.Unsafe_Just))))
        & Assoc ("List_Of_PIs",           List_Of_PIs)
        & Assoc ("List_Of_Events",        List_Of_Events)
        & Assoc ("List_Of_RIs",           List_Of_RIs)
        & Assoc ("List_Of_Sync_PIs",      List_Of_Sync_PIs)
        & Assoc ("List_Of_Sync_RIs",      List_Of_Sync_RIs)
        & Assoc ("Sync_RIs_Parent",       Sync_RIs_Parent)
        & Assoc ("Sync_RIs_Parent_Instance_Of",
               Sync_RIs_Parent_Instance_Of)
        & Assoc ("List_Of_ASync_PIs",     List_Of_ASync_PIs)
        & Assoc ("Count_Cyclic_PIs",      Count_Cyclic_PIs)
        & Assoc ("ASync_PI_Kind",         ASync_PI_Kind)
        & Assoc ("ASync_PI_Is_Connected", ASync_PI_Is_Connected)
        & Assoc ("ASync_PI_Param_Name",   ASync_PI_Param_Name)
        & Assoc ("ASync_PI_Param_Type",   ASync_PI_Param_Type)
        & Assoc ("List_Of_ASync_RIs",     List_Of_ASync_RIs)
        & Assoc ("ASync_RI_Param_Name",   ASync_RI_Param_Name)
        & Assoc ("ASync_RI_Param_Type",   ASync_RI_Param_Type)
        & Assoc ("Async_RIs_Parent",      Async_RIs_Parent)
        & Assoc ("CP_Names",              CP_Names)
        & Assoc ("DataStore",             F.DataStore)
        & Assoc ("DataStoreSize",         F.DataStoreSize)
        & Assoc ("FDIR",                  F.FDIR)
        & Assoc ("Function_Priority",     F.F_Priority.Value_Or (100)'Img)
        & Assoc ("CP_Types",              CP_Types)
        & Assoc ("CP_Values",             CP_Values)
        & Assoc ("CP_Asn1Modules",        CP_Asn1Modules)
        & Assoc ("CP_Asn1Filenames",      CP_Filenames)
        & Assoc ("Is_Type",               F.Is_Type)
        & Assoc ("Instance_Of",           F.Instance_Of)
        & Assoc ("Instance_Identifiers",  Instance_Identifiers)
        & Assoc ("Timers",                Timers)
        & Assoc ("PIs_Have_Params",       PIs_Have_Params)
        & Assoc ("RIs_Have_Params",       RIs_Have_Params)
        & Assoc ("Coord.X1",              X1)
        & Assoc ("Coord.Y1",              Y1)
        & Assoc ("Coord.X2",              X2)
        & Assoc ("Coord.Y2",              Y2);

      return Result;
   end Function_To_Template;

   procedure Debug_Dump (IV : Complete_Interface_View; Output : File_Type) is
      procedure Dump_Interface (I         : Taste_Interface;
                                Last_Leaf : Boolean := False;
                                Last_IF    : Boolean := False)
      is
         Ind : constant String := (if not Last_Leaf then "│  " else "   ");
         Bar : constant String := (if not Last_IF then "│  " else "   ");
         Pre : constant String := Ind & Bar;
      begin
         Put_Line (Output, Ind & (if Last_IF then "└─" else "├─")
                               & " Name : "
                   & To_String (I.Name) & " - in FV: "
                   & To_String (I.Parent_Function));
         Put_Line (Output, Pre & "├─ RCM Kind    : " & I.RCM'Img);
         Put_Line (Output, Pre & "├─ Period/MIAT : "
                               & I.Period_Or_MIAT'Img);
         --  Put_Line (Output, Pre & "├─ WCET (ms)   : "
         --            & I.WCET_ms.Value_Or (0)'Img);
         Put_Line (Output, Pre & "├─ Queue Size  : "
                   & I.Queue_Size.Value_Or (1)'Img);
         Put_Line (Output, Pre & "├─ Parameters  :");
         for Each of I.Params loop
            Put_Line (Output, Pre & "│  ├─ Name            : "
                      & To_String (Each.Name));
            Put_Line (Output, Pre & "│  │  ├─ Type         : "
                      & To_String (Each.Sort));
            Put_Line (Output, Pre & "│  │  ├─ ASN.1 Module : "
                      & To_String (Each.ASN1_Module));
            Put_Line (Output, Pre & "│  │  ├─ ASN.1 File   : "
                      & To_String (Each.ASN1_File_Name));
            Put_Line (Output, Pre & "│  │  ├─ Basic type   : "
                      & Each.ASN1_Basic_Type'Img);
            Put_Line (Output, Pre & "│  │  ├─ Encoding     : "
                      & Each.Encoding'Img);
            Put_Line (Output, Pre & "│  │  └─ Direction    : "
                      & Each.Direction'Img);
         end loop;
         Put_Line (Output, Pre & "└─ Connections :");
         for Each of I.Remote_Interfaces loop
            Put_Line (Output, Pre & "   "
                      & (if I.Remote_Interfaces.Last_Element = Each
                         then "└─" else "├─")
                      & " Function "
                      & To_String (Each.Function_Name)
                      & ", interface " & To_String (Each.Interface_Name));
         end loop;
      end Dump_Interface;
   begin
      for Each of IV.Flat_Functions loop
         Put_Line (Output, "Function " & To_String (Each.Name)
                   & " in context " & To_String (Each.Context));

         Put_Line (Output, "├─ Full Prefix : "
                   & To_String (Value_Or (Each.Full_Prefix, US ("(none)"))));
         Put_Line (Output, "├─ Language    : "
                   & To_String (Each.Language));
         Put_Line (Output, "├─ Zip file    : "
                   & To_String (Value_Or (Each.Zip_File, US ("(none)"))));
         Put_Line (Output, "├─ Is type     : " & Each.Is_Type'Img);
         Put_Line (Output, "├─ Instance of : "
                   & To_String (Each.Instance_Of));
         Put_Line (Output, "├─ Minimum number of instances : "
                   & Each.Min_Instances'Img);
         Put_Line (Output, "├─ Maximum number of instances : "
                   & Each.Max_Instances'Img);
         Put_Line (Output, "├─ Instance number : "
                   & Each.Instance_Number'Img);
         Put_Line (Output, "├─ Instance original name : "
                   & To_String (Each.Instance_Name));
         Put_Line (Output, "├─ Context Parameters :");
         for CP of Each.Context_Params loop
            Put_Line (Output, "│  "
                      & (if Each.Context_Params.Last_Element /= CP
                         then "├─ " else "└─ ")
                      & To_String (CP.Name) & " : "
                      & To_String (CP.Sort) & "- default : "
                      & To_String (CP.Default_Value) & " - asn1 module : "
                      & To_String (CP.ASN1_Module) & " - file : "
                      & To_String (Value_Or (CP.ASN1_File_Name,
                                             US ("(none)"))));
         end loop;
         Put_Line (Output, "├─ Directives:");
         for CP of Each.Directives loop
            Put_Line (Output, "│  "
                      & (if Each.Directives.Last_Element /= CP
                         then "├─ " else "└─ ")
                      & To_String (CP.Name) & " = "
                      & To_String (CP.Default_Value));
         end loop;
         Put_Line (Output, "├─ Simulink Tuneable Parameters:");
         for CP of Each.Simulink loop
            Put_Line (Output, "│  "
                      & (if Each.Simulink.Last_Element /= CP
                         then "├─ " else "└─ ")
                      & To_String (CP.Name) & " = "
                      & To_String (CP.Default_Value));
         end loop;
         Put_Line (Output, "├─ Implementations:");
         for CP of Each.Implems loop
            Put_Line (Output, "│  "
                      & (if Each.Implems.Last_Element /= CP
                         then "├─ " else "└─ ")
                      & To_String (CP.Name) & " = "
                      & To_String (CP.Default_Value));
         end loop;

         Put_Line (Output, "├─ User properties:");
         for Ppty of Each.User_Properties loop
            Put_Line (Output, "│  "
                      & (if Ppty /= Each.User_Properties.Last_Element
                         then "├─ " else "└─ ")
                      & To_String (Ppty.Name) & " = "
                      & To_String (Ppty.Value));
         end loop;
         Put_Line (Output, "├─ Timers:");
         for Timer of Each.Timers loop
            Put_Line (Output, "│  "
               & (if Each.Timers.Last_Element /= Timer
                  then "├─ " else "└─ ")
               & Timer);
         end loop;
         Put_Line (Output, "├─ Provided interfaces:");
         for PI of Each.Provided loop
            Dump_Interface (I         => PI,
                            Last_Leaf => False,
                            Last_IF   => Each.Provided.Last_Element = PI);
         end loop;
         Put_Line (Output, "└─ Required interfaces:");
         for RI of Each.Required loop
            Dump_Interface (I         => RI,
                            Last_Leaf => True,
                            Last_IF   => Each.Required.Last_Element = RI);
         end loop;
         New_Line (Output);
      end loop;
   end Debug_Dump;

   --  Create a Templates_Parser translate set for an interface (PI or RI)
   function Interface_To_Template (TI : Taste_Interface) return Translate_Set
   is
      Param_Names,
      Per_Interface_Param_Names,
      Param_Types,
      Param_ASN1_Modules,
      Param_Basic_Types,
      Param_Directions,
      Param_Encodings,
      Remote_Function_Names,
      Remote_Interface_Names,
      Remote_Languages : Vector_Tag;
      X, Y : Unbounded_String := US ("0"); --  interface graphical coordinates
      TI_Language : constant String := Map_Language (To_String (TI.Language));
   begin
      for Each of TI.Params loop
         Param_Names        := Param_Names & Each.Name;
         Param_Types        := Param_Types & Each.Sort;
         Param_Basic_Types  := Param_Basic_Types & Each.ASN1_Basic_Type'Img;
         Param_ASN1_Modules := Param_ASN1_Modules & Each.ASN1_Module;
         Param_Directions   := Param_Directions & Each.Direction'Img;
         Param_Encodings    := Param_Encodings & Each.Encoding'Img;
      end loop;

      --  Add list of callers or callees
      for Each of TI.Remote_Interfaces loop
         Per_Interface_Param_Names := Per_Interface_Param_Names & Param_Names;
         Remote_Function_Names  := Remote_Function_Names & Each.Function_Name;
         Remote_Interface_Names := Remote_Interface_Names
           & Each.Interface_Name;
         Remote_Languages := Remote_Languages & Each.Language;
      end loop;

      --  Get the graphical coordinates of the interface
      for P of TI.User_Properties loop
         if P.Name = "Taste::coordinates" then
            --  P.Value = x y
            declare
               Subs : String_Split.Slice_Set;
               Seps : constant String := " ";
            begin
               String_Split.Create (S          => Subs,
                                    From       => To_String (P.Value),
                                    Separators => Seps,
                                    Mode       => String_Split.Multiple);
               if Integer (String_Split.Slice_Count (Subs)) = 2 then
                  X := US (String_Split.Slice (Subs, 1));
                  Y := US (String_Split.Slice (Subs, 2));
               end if;
            end;
         end if;
      end loop;

      return
        Properties_To_Template (TI.User_Properties, Prefix => "IF_")
        & Assoc ("Name",                   TI.Name)
        & Assoc ("Kind",                   TI.RCM'Img)
        & Assoc ("Parent_Function",        TI.Parent_Function)
        & Assoc ("Language",               TI_Language)
        & Assoc ("Period",                 TI.Period_Or_MIAT'Img)
        & Assoc ("WCET",                   TI.WCET_ms)
        & Assoc ("Queue_Size",             TI.Queue_Size.Value_Or (1)'Img)
        & Assoc ("Event_Name",             TI.Name)
        & Assoc ("Event_Info",             TI.Event_Info)
        & Assoc ("Event_Type",             TI.Event_Type)
        & Assoc ("Event_ID",               TI.Event_ID)
        & Assoc ("Message_ID",             TI.Message_ID)
        & Assoc ("Message_Content",        TI.Message_Content)
        & Assoc ("Message_Size",           TI.Message_Size)
        & Assoc ("Store_Message",          TI.Store_Message)
        & Assoc ("Target_Name",            TI.Target_Name)
        & Assoc ("IF_Stack_Size",          TI.Stack_Size)
        & Assoc ("IF_Priority",            TI.Priority)
        & Assoc ("IF_Offset",              TI.Dispatch_Offset)
        & Assoc ("Param_Names",            Param_Names)
        & Assoc ("Per_If_Param_Names",     Per_Interface_Param_Names)
        & Assoc ("Param_Types",            Param_Types)
        & Assoc ("Param_ASN1_Modules",     Param_ASN1_Modules)
        & Assoc ("Param_Basic_Types",      Param_Basic_Types)
        & Assoc ("Param_Encodings",        Param_Encodings)
        & Assoc ("Param_Directions",       Param_Directions)
        & Assoc ("Remote_Function_Names",  Remote_Function_Names)
        & Assoc ("Remote_Interface_Names", Remote_Interface_Names)
        & Assoc ("Remote_Languages",       Remote_Languages)
        & Assoc ("Coord.X",                X)
        & Assoc ("Coord.Y",                Y)
        & Assoc ("Is_Timer",               TI.Is_Timer);
   end Interface_To_Template;

end TASTE.Interface_View;
