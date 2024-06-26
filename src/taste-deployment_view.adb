--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

--  Deployment View parser

with Ada.Exceptions,
     Ada.Strings.Fixed,
     System.Assertions,
     Ocarina.Instances.Queries,
     Ocarina.Instances,
     --  Ocarina.Files,
     --  Ocarina.FE_AADL.Parser,
     --  Ocarina.Parser,
     Ocarina.Namet,
     Ocarina.Analyzer,
     Ocarina.Options,
     Ocarina.Backends.Properties.ARINC653,
     --  Locations,
     Ocarina.ME_AADL.AADL_Instances.Nodes,
     Ocarina.ME_AADL.AADL_Instances.Nutils,
     Ocarina.ME_AADL.AADL_Instances.Entities;

package body TASTE.Deployment_View is

   use Ada.Exceptions,
       Ada.Strings.Fixed,
       System.Assertions,
       Ocarina.Instances.Queries,
       Ocarina.Namet,
       --  Ocarina.FE_AADL.Parser,
       Ocarina.Backends.Properties.ARINC653,
       --  Locations,
       Ocarina.ME_AADL.AADL_Instances.Nodes,
       Ocarina.ME_AADL.AADL_Instances.Nutils,
       Ocarina.ME_AADL.AADL_Instances.Entities,
       Ocarina.ME_AADL;

   function Initialize (Root : Node_Id) return Node_Id is
      --  Root_Depl      : Node_Id := Root;
      Success        : Boolean;
      Root_Instance  : Node_Id;
      AADL_Language  : constant Name_Id := Get_String_Name ("aadl");
      --  Loc : Location;
      --  F   : Name_Id;
   begin
      --  Ocarina.FE_AADL.Parser.Add_Pre_Prop_Sets := True;

      Success := Ocarina.Analyzer.Analyze (AADL_Language, Root);

      if not Success then
         raise Deployment_View_Error with "Deployment view is incorrect";
      end if;

      Ocarina.Options.Root_System_Name :=
        Get_String_Name ("deploymentview.others");

      --  Instantiate AADL tree
      Root_Instance := Ocarina.Instances.Instantiate_Model (Root => Root);
      return Root_System (Root_Instance);
   end Initialize;

   function Device_Instance_Name (Driver : Taste_Device_Driver) return String
   is
      Dot : constant Natural := Index (Driver.Name, ".");
      Name : constant String := To_String (Driver.Name);
      Device_Name : constant String :=
        (if Dot > 0
           then Name (Name'First .. Dot - 1)
           else "ERROR_MALFORMED_DEVICE_NAME");
   begin
         return Device_Name;
   end Device_Instance_Name;

   function Drivers_To_Template (Drivers : Taste_Drivers.Vector)
                                return Translate_Set is
      Device_Names,
      Device_Driver_Names,
      Device_Package_Names,
      Device_Classifiers,
      Device_Associated_Processor_Names,
      Device_Configurations,
      Device_Packetizers,
      Device_Addresses,
      Device_Network_Numbers,
      Device_Throughputs,
      Device_Transmissions,
      Device_Max_Blockings,
      Device_Max_Packet_Sizes,
      Device_Min_Packet_Sizes,
      Device_Speed_Factors,
      Device_Protocols,
      Device_Accessed_Bus_Names,
      Device_Accessed_Port_Names,
      Device_Init_Entrypoints,
      Device_Send_Functions,
      Device_Init_Languages,
      Device_ASN1_Filenames,
      Device_ASN1_Typenames,
      Device_ASN1_Modules : Vector_Tag;
   begin
      for Driver of Drivers loop
         --  Only consider devices that are actually connected to a bus
         if not Driver.Accessed_Bus_Name.Is_Empty then
            Device_Names := Device_Names & Driver.Device_Instance_Name;
            Device_Driver_Names := Device_Driver_Names
              & Driver.Driver_Name;
            Device_Package_Names := Device_Package_Names
              & Driver.Package_Name;
            Device_Classifiers := Device_Classifiers
              & Driver.Device_Classifier;
            Device_Associated_Processor_Names :=
              Device_Associated_Processor_Names
              & Driver.Associated_Processor_Name;
            Device_Configurations := Device_Configurations
              & Driver.Device_Configuration;
            Device_Packetizers := Device_Packetizers
              & Driver.Device_Packetizer;
            Device_Addresses := Device_Addresses
              & Driver.Device_Address;
            Device_Network_Numbers := Device_Network_Numbers
              & Driver.Device_Network_Number;
            Device_Transmissions := Device_Transmissions
              & Driver.Device_Transmission;
            Device_Throughputs := Device_Throughputs
              & Driver.Device_Throughput;
            Device_Max_Blockings := Device_Max_Blockings
              & Driver.Device_Max_Blocking;
            Device_Max_Packet_Sizes := Device_Max_Packet_Sizes
              & Driver.Device_Max_Packet_Size;
            Device_Min_Packet_Sizes := Device_Min_Packet_Sizes
              & Driver.Device_Min_Packet_Size;
            Device_Speed_Factors := Device_Speed_Factors
              & Driver.Device_Speed_Factor;
            Device_Protocols := Device_Protocols
              & Driver.Device_Protocol;
            Device_Accessed_Bus_Names :=  Device_Accessed_Bus_Names
              & Driver.Accessed_Bus_Name.Element;
            Device_Accessed_Port_Names := Device_Accessed_Port_Names
              & Driver.Accessed_Port_Name.Element;
            Device_ASN1_Filenames := Device_ASN1_Filenames
              & Driver.ASN1_Filename;
            Device_ASN1_Typenames := Device_ASN1_Typenames
              & Driver.ASN1_Typename;
            Device_ASN1_Modules := Device_ASN1_Modules
              & Driver.ASN1_Module;
            Device_Init_Entrypoints := Device_Init_Entrypoints
              & Driver.Init_Function;
            Device_Send_Functions := Device_Send_Functions
              & Driver.Send_Function;
            Device_Init_Languages := Device_Init_Languages
              & Driver.Init_Language;
         end if;
      end loop;

      return +Assoc ("Device_Names",     Device_Names)
        & Assoc ("Device_Driver_Names",  Device_Driver_Names)
        & Assoc ("Device_AADL_Pkg",      Device_Package_Names)
        & Assoc ("Device_Classifier",    Device_Classifiers)
        & Assoc ("Device_CPU",           Device_Associated_Processor_Names)
        & Assoc ("Device_Config",        Device_Configurations)
        & Assoc ("Device_Packetizer",    Device_Packetizers)
        & Assoc ("Device_Address",    Device_Addresses)
        & Assoc ("Device_Network_Number",    Device_Network_Numbers)
        & Assoc ("Device_Throughput",    Device_Throughputs)
        & Assoc ("Device_Transmission",    Device_Transmissions)
        & Assoc ("Device_Max_Blocking",    Device_Max_Blockings)
        & Assoc ("Device_Max_Packet_Size",    Device_Max_Packet_Sizes)
        & Assoc ("Device_Min_Packet_Size",    Device_Min_Packet_Sizes)
        & Assoc ("Device_Speed_Factor",    Device_Speed_Factors)
        & Assoc ("Device_Protocol",    Device_Protocols)
        & Assoc ("Device_Bus_Name",      Device_Accessed_Bus_Names)
        & Assoc ("Device_Port_Name",     Device_Accessed_Port_Names)
        & Assoc ("Device_ASN1_File",     Device_ASN1_Filenames)
        & Assoc ("Device_ASN1_Sort",     Device_ASN1_Typenames)
        & Assoc ("Device_ASN1_Module",   Device_ASN1_Modules)
        & Assoc ("Device_Init",          Device_Init_Entrypoints)
        & Assoc ("Device_Send_Function", Device_Send_Functions)
        & Assoc ("Device_Language",      Device_Init_Languages);
   end Drivers_To_Template;

   ---------------------------
   -- AST Builder Functions --
   ---------------------------

   function Parse_Deployment_View (System : Node_Id;
                                   IV     : Complete_Interface_View)
                                   return Complete_Deployment_View
   is
      use type Bus_Connections.Vector;

      Nodes          : Node_Maps.Map;
      Node           : Taste_Node;
      Busses         : Taste_Busses.Vector;
      Conns          : Bus_Connections.Vector;
      My_Root_System : Node_Id;
      Subs           : Node_Id;
      CI             : Node_Id;

      Result_DV      : Complete_Deployment_View;

      function Parse_Bus (Elem : Node_Id; Bus : Node_Id) return Taste_Bus is
         Properties : constant Property_Maps.Map := Get_Properties_Map (CI);
         Classifier : Name_Id;
         Pkg_Name   : Name_Id := No_Name;
      begin
         Set_Str_To_Name_Buffer ("");
         if ATN.Namespace
             (Corresponding_Declaration (Bus)) /= No_Node
         then
            Set_Str_To_Name_Buffer ("");
            Get_Name_String (ATN.Name (ATN.Identifier (ATN.Namespace
                             (Corresponding_Declaration (Bus)))));
            Pkg_Name := Name_Find;
            Set_Str_To_Name_Buffer ("");
            Get_Name_String (Pkg_Name);
            Add_Str_To_Name_Buffer ("::");
            Get_Name_String_And_Append
               (Name (Identifier (Bus)));
            Classifier := Name_Find;
         else
            Classifier := Name (Identifier (Bus));
            --  No "default" Pkg_Name?
         end if;
         return Taste_Bus'(Name         =>
                             US (Get_Name_String (Name (Identifier (Elem)))),
                           AADL_Package => US (Get_Name_String (Pkg_Name)),
                           Classifier   => US (Get_Name_String (Classifier)),
                           Properties   => Properties);
      end Parse_Bus;

      procedure Rec_Parse_Connections (AADL_System : Node_Id;
                                       Result : in out Bus_Connections.Vector)
      is
         use Bus_Connections;
         Conn,
         Bound_Bus      : Node_Id;
         Bound_Bus_Name : Name_Id;
         Subs,
         Sub_System_CI  : Node_Id;
      begin
         Conn := First_Node (Connections (AADL_System));
         while Present (Conn) loop
            Put_Debug ("Parsing Connection " & AIN_Case (Conn));
            --  AADL is confusing because it reverses the meaning of source
            --  and destination. Source is the message receiver (the PI) and
            --  destination is the message sender (the RI)
            Bound_Bus := Get_Bound_Bus (Conn, False);
            if Bound_Bus /= No_Node then
               Bound_Bus_Name := Name
                  (Identifier (Parent_Subcomponent (Bound_Bus)));
               --  The source and destination function/ports are irrelevant
               --  here because they may not be end-to-end connections in
               --  case of a hierarchical structure. All bus connections
               --  must be updated before processing the concurrency view, but
               --  this can be done only using the interface view information.
               --  Put_Debug ("Added bus connnection: ");
               --  Put_Debug (" ... Channel: " & AIN_Case (Conn));
               --  Put_Debug (" ... Bus: " & Get_Name_String (Bound_Bus_Name));

               Result := Result
                 & Bus_Connection'(Channel_Name => US (AIN_Case (Conn)),
                                   Bus_Name     =>
                                     US (Get_Name_String (Bound_Bus_Name)),
                                   others       => <>);
            end if;
            Conn := Next_Node (Conn);
         end loop;
         --  We now check if there are subsystems in the current system
         --  and go recusively to collect all connections bound to a bus
         Subs := First_Node (Subcomponents (AADL_System));
         while Present (Subs) loop
            Sub_System_CI := Corresponding_Instance (Subs);
            if Get_Category_Of_Component (Sub_System_CI) = CC_System then
               --  Put_Debug ("Sub node: " & AIN_Case (Sub_System_CI));
               if not Is_Empty (Connections (Sub_System_CI)) then
                  Rec_Parse_Connections (Sub_System_CI, Result);
               end if;
            end if;
            Subs := Next_Node (Subs);
         end loop;
      end Rec_Parse_Connections;

      --  Find the bus that is connected to a device through a require access
      procedure Find_Connected_Bus (Device        : Node_Id;
                                    Accessed_Bus  : out Node_Id;
                                    Accessed_Port : out Node_Id) is
         F   : Node_Id;
         Src : Node_Id;
      begin
         Accessed_Bus := No_Node;
         Accessed_Port := No_Node;
         if not Is_Empty (Features (Device)) then
            F := First_Node (Features (Device));
            while Present (F) loop
               --  The sources of F
               if not Is_Empty (AIN.Sources (F)) then
                  Src := First_Node (AIN.Sources (F));
                  if Src /= No_Node then
                     if Item (Src) /= No_Node and then
                        not Is_Empty (AIN.Sources (Item (Src))) and then
                        First_Node (AIN.Sources (Item (Src))) /= No_Node
                     then
                        Src := Item (First_Node (AIN.Sources (Item (Src))));
                        Accessed_Bus := Src;
                        Accessed_Port := F;
                     end if;
                  end if;
               end if;
               F := Next_Node (F);
            end loop;
         end if;
      end Find_Connected_Bus;

      function Parse_Device (CI : Node_Id) return Taste_Device_Driver is
         Result                : Taste_Device_Driver;
         Pkg_Name              : Name_Id;
         Accessed_Bus,
         Accessed_Port,
         Device_Implementation,
         Configuration_Data,
         Driver_Init_Data,
         Subco                 : Node_Id;
      begin
         Result.Name := US (Get_Name_String (Name (Identifier (CI))));

         --  Get_Implementation returns the "abstract driver" part of the
         --  device, which comes from the "Device_Driver" property of the
         --  instance
         --  This is an example of this part in AADL:
         --     abstract Driver_GRSPW_Protocol
         --     properties
         --       Deployment::Version  => "0.1beta";
         --       Deployment::Help     => "Help!";
         --       Deployment::Configuration_Type =>
         --        classifier (ocarina_drivers::configuration_type_spacewire);
         --   end Driver_GRSPW_Protocol;
         --
         --   abstract implementation Driver_GRSPW_Protocol.impl
         --   subcomponents
         --      receiver : thread Driver_GRSPW_Protocol_thread_receiver.impl;
         --      sender : subprogram Send;
         --   end Driver_GRSPW_Protocol.impl;
         Device_Implementation := Get_Implementation (CI);

         --  Retrieve the unique driver name
         for P of Get_Properties_Map (CI) loop
            if P.Name = "Deployment::Driver_Name" then
               Result.Driver_Name := P.Value;
            end if;
         end loop;

         --  *** GET INFORMATION ABOUT DRIVER INITIALIZATION ***
         --  Devices constain this property:
         --  Initialize_Entrypoint => classifier (Native_UART::Initialize);
         --  This subprorgam has two properties of interest, e.g.:
         --     Source_Name => "PolyORB_HI_Drivers_Native_UART.Initialize";
         --     Source_Language => (Ada);
         Driver_Init_Data := Get_Classifier_Property
           (CI, Get_String_Name ("initialize_entrypoint"));

         if Driver_Init_Data /= No_Node and then
           Is_Defined_Property (Driver_Init_Data, "source_name")
         then
            Result.Init_Function :=
              US (Get_Name_String (Get_String_Property
                  (Driver_Init_Data, "source_name")));
         else
            raise Device_Driver_Error with "Driver error ("
                       & To_String (Result.Name)
                       & ") : no initialization function specified in AADL";
         end if;
         Result.Init_Language := US (Get_Language (Driver_Init_Data));
         Put_Debug ("Driver init: " & To_String (Result.Init_Function));
         Put_Debug ("Driver Language: " & To_String (Result.Init_Language));
         --  *** END OF DRIVER INITIALIZATION ***

         --  *** GET INFORMATION ABOUT DRIVER SEND FUNCTION ***
         --  this is defined in the abstract implementation part, but unlike
         --  intiialization, it is not a simple property with the name, we
         --  have to parse subcomponents (see example above) and look for the
         --  one named "sender", which should be a subprogram
         if Present (AIN.Subcomponents (Device_Implementation)) then
            Subco := AIN.First_Node
                (AIN.Subcomponents (Device_Implementation));
            while Present (Subco) loop
               if Get_Name_String (Name (Identifier (Subco))) = "sender" then
                  for P of Get_Properties_Map (Corresponding_Instance (Subco))
                  loop
                     if P.Name = "Source_Name" then
                        Result.Send_Function := P.Value;
                     end if;
                  end loop;
               end if;
               Subco := AIN.Next_Node (Subco);
            end loop;
         end if;

         --  *** END OF DRIVER SEND FUNCTION ***

         if Device_Implementation /= No_Node and then
            Is_Defined_Property (Device_Implementation,
                                 "deployment::configuration_type")
         then
            Configuration_Data := Get_Classifier_Property
                (Device_Implementation, "deployment::configuration_type");

            if Is_Defined_Property (Configuration_Data, "type_source_name")
            then
               Result.ASN1_Typename :=
                 US (Get_Name_String (Get_String_Property
                    (Configuration_Data, "type_source_name")));
               declare
                  ST : constant Name_Array :=
                    Get_Source_Text (Configuration_Data);
               begin
                  --  ST is a tuple (asn.1 file, .h file)
                  if ST'Length = 0 then
                     raise Device_Driver_Error with "Driver error ("
                       & To_String (Result.Name)
                       & ") : Missing configuration data";
                  end if;
                  for Index in ST'Range loop
                     Get_Name_String (ST (Index));
                     pragma Assert (Name_Len >= 1 and then Name_Len <= 16384);
                     if Tail (Source => Name_Buffer (1 .. Name_Len),
                              Count  => 4) = ".asn"
                     then
                        Result.ASN1_Filename :=
                          US (Name_Buffer (1 .. Name_Len));
                     end if;
                  end loop;
               end;
            end if;
            if Result.ASN1_Filename = US ("") then
               raise Device_Driver_Error with "Driver error ("
                 & To_String (Result.Name)
                 & ") : Missing ASN.1 configuration file";
            end if;

            if Is_Defined_Property
                 (Configuration_Data, "deployment::asn1_module_name")
            then
               Result.ASN1_Module := US (Get_Name_String
                                                (Get_String_Property
                 (Configuration_Data, "deployment::asn1_module_name")));
            else
               raise Device_Driver_Error with "Driver error ("
                 & To_String (Result.Name) & ") : Missing ASN.1 module name";
            end if;
         else
            raise Device_Driver_Error with
              "Device configuration is incorrect ("
              & Get_Name_String (Name (Identifier (CI))) & ")";
         end if;

         if Is_Defined_Property
               (Configuration_Data, "taste::protocol")
         then
            Result.Protocol := US (Get_Name_String
                                             (Get_String_Property
               (Configuration_Data, "taste::protocol")));
         end if;

         Set_Str_To_Name_Buffer ("");
         if ATN.Namespace (Corresponding_Declaration (CI)) /= No_Node
         then
            Set_Str_To_Name_Buffer ("");
            Get_Name_String (ATN.Name (ATN.Identifier
                        (ATN.Namespace (Corresponding_Declaration (CI)))));
            Pkg_Name := Name_Find;
            --  CHECKME : I don't kwnow when this needed, check buildsupport
            --            C_Add_Package   (Get_Name_String (Pkg_Name),
            Result.Package_Name := US (Get_Name_String (Pkg_Name));
            Set_Str_To_Name_Buffer ("");
            Get_Name_String (Pkg_Name);
            Add_Str_To_Name_Buffer ("::");
            Get_Name_String_And_Append (Name (Identifier (CI)));
            Result.Device_Classifier := US (Get_Name_String (Name_Find));
         else
            Result.Device_Classifier :=
              US (Get_Name_String (Name (Identifier (CI))));
         end if;

         if Get_Bound_Processor (CI) /= No_Node then
            Set_Str_To_Name_Buffer ("");
            Result.Associated_Processor_Name := US (Get_Name_String (Name
               (Identifier (Parent_Subcomponent (Get_Bound_Processor (CI))))));
         end if;

         if Is_Defined_Property (CI, "deployment::configuration") and then
            Get_String_Property (CI, "deployment::configuration") /= No_Name
         then
            Result.Device_Configuration :=
              US (Get_Name_String
                  (Get_String_Property (CI, "deployment::configuration")));
         else
            Result.Device_Configuration := US ("noconf");
         end if;

         if Is_Defined_Property (CI, "deployment::packetizer") and then
            Get_String_Property (CI, "deployment::packetizer") /= No_Name
         then
            Result.Device_Packetizer :=
              US (Get_Name_String
                  (Get_String_Property (CI, "deployment::packetizer")));
         else
            Result.Device_Packetizer := US ("default");
         end if;

         if Is_Defined_Property (CI, "taste::address") and then
            Get_String_Property (CI, "taste::address") /= No_Name
         then
            Result.Device_Address :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::address")));
         else
            Result.Device_Address := US ("127.0.0.1:1234");
         end if;

         if Is_Defined_Property (CI, "taste::networknumber") and then
            Get_String_Property (CI, "taste::networknumber") /= No_Name
         then
            Result.Device_Network_Number :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::networknumber")));
         else
            Result.Device_Network_Number := US ("0");
         end if;

         if Is_Defined_Property (CI, "taste::transmission") and then
            Get_String_Property (CI, "taste::transmission") /= No_Name
         then
            Result.Device_Transmission :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::transmission")));
         end if;

         if Is_Defined_Property (CI, "taste::throughput") and then
            Get_String_Property (CI, "taste::throughput") /= No_Name
         then
            Result.Device_Throughput :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::throughput")));
         end if;

         if Is_Defined_Property (CI, "taste::max_blocking") and then
            Get_String_Property (CI, "taste::max_blocking") /= No_Name
         then
            Result.Device_Max_Blocking :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::max_blocking")));
         end if;

         if Is_Defined_Property (CI, "taste::max_packet_size") and then
            Get_String_Property (CI, "taste::max_packet_size") /= No_Name
         then
            Result.Device_Max_Packet_Size :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::max_packet_size")));
         end if;

         if Is_Defined_Property (CI, "taste::min_packet_size") and then
            Get_String_Property (CI, "taste::min_packet_size") /= No_Name
         then
            Result.Device_Min_Packet_Size :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::min_packet_size")));
         end if;

         if Is_Defined_Property (CI, "taste::speed_factor") and then
            Get_String_Property (CI, "taste::speed_factor") /= No_Name
         then
            Result.Device_Speed_Factor :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::speed_factor")));
         end if;

         if Is_Defined_Property (CI, "taste::protocol") and then
            Get_String_Property (CI, "taste::protocol") /= No_Name
         then
            Result.Device_Protocol :=
              US (Get_Name_String
                  (Get_String_Property (CI, "taste::protocol")));
         else
            Result.Device_Protocol := US ("udp");
         end if;

         Find_Connected_Bus (CI, Accessed_Bus, Accessed_Port);

         --  Set the optional fields if the device is connected
         if Accessed_Bus /= No_Node and then Accessed_Port /= No_Node
         then
            Result.Accessed_Bus_Name :=
              String_Holders.To_Holder
                  (Get_Name_String (Name (Identifier (Accessed_Bus))));
            Result.Accessed_Port_Name :=
              String_Holders.To_Holder
                  (Get_Name_String (Name (Identifier (Accessed_Port))));
         end if;
         return Result;
      exception
         when Error : Device_Driver_Error =>
            raise Device_Driver_Error with Exception_Message (Error);
         when Error : others =>
            raise Device_Driver_Error with "Device driver unknown error : "
              & Exception_Message (Error);
      end Parse_Device;

      --  TSP systems have memory regions, declared in the deployment view
      --  the partitions are bound to the memory region. This function
      --  is a placeholder to parse any required memory information.
      --  Currently the backends only need to know that a memory is defined
      --  actual size or segements information are not needed to build the
      --  concurrency view.
      function Parse_Memory (CI : Node_Id;
                             dummy_Depl : Node_Id) return Taste_Memory
      is
         Result : Taste_Memory;
      begin
         Result.Name :=  -- Memory identifier (usually "main_memory")
           US (Get_Name_String (ATN.Name (ATN.Component_Type_Identifier
               (Corresponding_Declaration (CI)))));
         return Result;
      end Parse_Memory;

      function Parse_Partition (CI : Node_Id; Depl : Node_Id)
                                return Taste_Partition is
         Result               : Taste_Partition;
         CPU                  : Node_Id;
         Processes            : Node_Id;
         P_CI                 : Node_Id;
         Ref                  : Node_Id;
         Startup_Priorities   : Unsigned_Long_Long_Vectors.Vector;
         procedure Separate_CPU_Family_From_Instance
         --  If the CPU in the AADL model is "leon3.air", then split into
         --  family "leon3" and instance "air" based on dot separator
           (CPU              : Node_Id;
            Family, Instance : out Unbounded_String) is
            CPU_With_Instance : constant String :=
              Get_Name_String (Name (Identifier (CPU)));
            Dot : constant Natural := Index (CPU_With_Instance, ".");
            Fam : constant String :=
              (if Dot > 0
               then CPU_With_Instance (CPU_With_Instance'First .. Dot - 1)
               else "");
            Inst : constant String :=
              (if Dot >= CPU_With_Instance'First
               and then Dot + 1 <= CPU_With_Instance'Last
               then CPU_With_Instance (Dot + 1 .. CPU_With_Instance'Last)
               else "");
         begin
            Family := US (Fam);
            Instance := US (Inst);
         end Separate_CPU_Family_From_Instance;

         --  Built-in sort not used because we need to
         --  sort two vectors at once
         procedure Sort_Functions_Based_On_Startup_Priority
            (Bound_Functions : in out String_Vectors.Vector;
             Startup_Priorities : in out Unsigned_Long_Long_Vectors.Vector) is
         begin
            if Bound_Functions.Length /= Startup_Priorities.Length then
               raise Startup_Priority_Error;
            end if;

            for I in Bound_Functions.First_Index ..
                     Bound_Functions.Last_Index - 1 loop
               for J in Bound_Functions.First_Index ..
                        Bound_Functions.Last_Index - I - 1 loop
                  if Startup_Priorities (J) < Startup_Priorities (J + 1) then
                     Bound_Functions.Swap (J, J + 1);
                     Startup_Priorities.Swap (J, J + 1);
                  end if;
               end loop;
            end loop;
         end Sort_Functions_Based_On_Startup_Priority;

      begin
         if Is_Defined_Property (CI, "taste_dv_properties::coverageenabled")
         then
            Result.Coverage := Get_Boolean_Property
               (CI, Get_String_Name ("taste_dv_properties::coverageenabled"));
         end if;

         --  Gather all user properties
         Result.User_Properties := Get_Properties_Map (CI);

         CPU := Get_Bound_Processor (CI);

         Result.CPU_Name :=
           US
             (Get_Name_String (Name (Identifier (Parent_Subcomponent (CPU)))));

         Separate_CPU_Family_From_Instance (CPU,
                                            Result.CPU_Family,
                                            Result.CPU_Instance);

         Result.CPU_Platform := Get_Execution_Platform (CPU);
         if Result.CPU_Platform = Platform_GNAT_Runtime then
            Result.Ada_Runtime := US (Get_Name_String (Get_Ada_Runtime (CPU)));
         else
            Result.Ada_Runtime := US ("");
         end if;

         if ATN.Namespace (Corresponding_Declaration (CPU)) /= No_Node
         then
            Set_Str_To_Name_Buffer ("");
            Get_Name_String (ATN.Name (ATN.Identifier (ATN.Namespace
                        (Corresponding_Declaration (CPU)))));
            Result.Package_Name := US (Get_Name_String (Name_Find));

            Set_Str_To_Name_Buffer ("");
            Get_Name_String
              (Get_String_Name (To_String (Result.Package_Name)));
            Add_Str_To_Name_Buffer ("::");
            Get_Name_String_And_Append (Name (Identifier (CPU)));
            Result.CPU_Classifier := US (Get_Name_String (Name_Find));
         else
            Result.CPU_Classifier :=
              US (Get_Name_String (Name (Identifier (CPU))));
            Result.Package_Name := US ("");
         end if;

         Result.Name :=
           US (Get_Name_String (ATN.Name (ATN.Component_Type_Identifier
               (Corresponding_Declaration (CI)))));

         --  If case of virtual processor, find the physical processor it is
         --  bounded to, and set the values in the taste partition
         --  The physical CPU in that case should contain two additional
         --  properties:
         --  ARINC653::Module_Major_Frame (time with unit),
         --  and ARINC653::Module_Schedule
         if Get_Category_Of_Component (CPU) = CC_Virtual_Processor then
            declare
               Phy_CPU      : constant Node_Id :=
                 Get_Reference_Property (CPU,
                                         Get_String_Name
                                           ("actual_processor_binding"));
               Phy_CPU_Name : constant String :=
                 Get_Name_String
                   (Name (Identifier (Parent_Subcomponent (Phy_CPU))));
               Phy_CPU_Platform : constant Supported_Execution_Platform :=
                 Get_Execution_Platform (Phy_CPU);
               Phy_CPU_Classifier   : Unbounded_String;
               Phy_CPU_Package_Name : Unbounded_String;
            begin
               --  Build the classifier string (package::...::cpu....)
               Set_Str_To_Name_Buffer ("");
               Get_Name_String (ATN.Name (ATN.Identifier (ATN.Namespace
                                (Corresponding_Declaration (Phy_CPU)))));
               Phy_CPU_Package_Name := US (Get_Name_String (Name_Find));

               Set_Str_To_Name_Buffer ("");
               Get_Name_String (Get_String_Name
                                (To_String (Phy_CPU_Package_Name)));
               Add_Str_To_Name_Buffer ("::");
               Get_Name_String_And_Append (Name (Identifier (Phy_CPU)));

               Phy_CPU_Classifier := US (Get_Name_String (Name_Find));

               Result.VP_Package_Name := Result.Package_Name;
               Result.VP_Name         := Result.CPU_Name;
               Result.VP_Platform     := Result.CPU_Platform;
               Result.VP_Classifier   := Result.CPU_Classifier;
               Result.CPU_Name        := US (Phy_CPU_Name);
               Result.CPU_Platform    := Phy_CPU_Platform;
               Result.CPU_Classifier  := Phy_CPU_Classifier;
               Result.Package_Name    := Phy_CPU_Package_Name;
               Separate_CPU_Family_From_Instance (Phy_CPU,
                                                  Result.CPU_Family,
                                                  Result.CPU_Instance);
               --  Detect the CPU major frame duration and the time
               --  allocation for this specific partition
               declare
                  Major_Frame : constant Time_Type :=
                    Get_POK_Major_Frame (Phy_CPU);
                  Schedule : constant Schedule_Window_Record_Term_Array :=
                    Get_Module_Schedule_Property (Phy_CPU);
               begin
                  if Major_Frame /= Null_Time
                    and then Major_Frame.U = Millisecond
                  then

                     Result.CPU_Total_Time := US (Major_Frame.T'Img);
                  end if;   -- otherwise, error?
                  for Each of Schedule loop
                     --  To know if the schedule applies to the current VP,
                     --  we need to compare it with "Corresponding_Declaration
                     --  (Parent_Subcomponent (CPU)
                     if Each.Partition = Corresponding_Declaration
                       (Parent_Subcomponent (CPU))
                     then
                        Result.VP_Duration := US (Each.Duration.T'Img);
                     end if;
                  end loop;
               end;

            end;
         end if;

         --  Bounded functions
         Processes := First_Node (Subcomponents (Depl));
         while Present (Processes) loop
            P_CI := Corresponding_Instance (Processes);

            if Get_Category_Of_Component (P_CI) = CC_System
              and then Is_Defined_Property (P_CI, "taste::aplc_binding")
            then
               Ref := Get_Reference_Property
                  (P_CI, Get_String_Name ("taste::aplc_binding"));

               if Ref = CI then
                  begin
                     if Result.Bound_Functions.Contains (
                        Get_Name_String (ATN.Name
                        (ATN.Component_Type_Identifier
                            (Corresponding_Declaration (P_CI)))))
                     then
                        raise Constraint_Error;
                     else
                        Result.Bound_Functions.Append (Get_Name_String
                           (ATN.Name
                           (ATN.Component_Type_Identifier
                           (Corresponding_Declaration (P_CI)))));
                        if Is_Defined_Integer_Property (P_CI,
                              Get_String_Name ("taste::startup_priority"))
                        then
                           Startup_Priorities.Append (
                              Get_Integer_Property (P_CI,
                              Get_String_Name ("taste::startup_priority")));
                        else
                           Startup_Priorities.Append (1);
                        end if;
                     end if;
                  exception
                     when Assert_Failure =>
                        Put_Info ("Detected DV from TASTE version 1.2");
                        Result.Bound_Functions.Append
                          (Get_Name_String (Name (Identifier (Processes))));
                     when Constraint_Error =>
                        --  If there are duplicate function in partition
                        Put_Info ("Duplicate bounded function in partition: "
                           & To_String (Result.Name));
                  end;
               end if;
            end if;
            Processes := Next_Node (Processes);
         end loop;
         Sort_Functions_Based_On_Startup_Priority (
            Result.Bound_Functions, Startup_Priorities);
         return Result;
         exception
            when Startup_Priority_Error =>
               Put_Info ("Bound functions and startup priorities " &
                         "lengths do not match for partition: "
                         & To_String (Result.Name));
               return Result;
      end Parse_Partition;

      function Parse_Node (Depl_View_System : Node_Id) return Taste_Node is
         Subcos    : Node_Id;
         CI        : Node_Id;
         Result    : Taste_Node;
         Partition : Taste_Partition;
      begin
         Subcos := First_Node (Subcomponents (Depl_View_System));

         while Present (Subcos) loop
            CI := Corresponding_Instance (Subcos);

            if Get_Category_Of_Component (CI) = CC_Device then
               Result.Drivers.Append (Parse_Device (CI));

            elsif Get_Category_Of_Component (CI) = CC_Memory then
               Result.Memory := Parse_Memory (CI, Depl_View_System);

            elsif Get_Category_Of_Component (CI) = CC_Process then
               Partition := Parse_Partition (CI, Depl_View_System);
               Result.Partitions.Insert
                 (Key      => To_String (Partition.Name),
                  New_Item => Partition);
               Result.CPU_Name       := Partition.CPU_Name;
               Result.CPU_Duration   := Partition.CPU_Total_Time;
               Result.CPU_Family     := Partition.CPU_Family;
               Result.CPU_Instance   := Partition.CPU_Instance;
               Result.CPU_Platform   := Partition.CPU_Platform;
               Result.CPU_Classifier := Partition.CPU_Classifier;
               Result.Ada_Runtime    := Partition.Ada_Runtime;
               Result.Package_Name   := Partition.Package_Name;
               --  Check if there is a Virtual processor, add it to the list
               if Partition.VP_Name /= "" then
                  Result.Virtual_CPUs.Insert
                    (Key      => To_String (Partition.VP_Name),
                     New_Item => (Name         => Partition.VP_Name,
                                  Package_Name => Partition.VP_Package_Name,
                                  Platform     =>
                                    US (Partition.VP_Platform'Img),
                                  Classifier   => Partition.VP_Classifier));
               end if;
            end if;

            Subcos := Next_Node (Subcos);
         end loop;
         return Result;
      end Parse_Node;

   begin
      Put_Info ("Parsing deployment view");
      My_Root_System := Initialize (System);

      if Is_Empty (Subcomponents (My_Root_System)) then
         raise Empty_Deployment_View_Error;
      end if;

      Subs := First_Node (Subcomponents (My_Root_System));

      while Present (Subs) loop
         CI := Corresponding_Instance (Subs);

         if Get_Category_Of_Component (CI) = CC_System then  --  Node
            Put_Debug ("Deployment node name: " & AIN_Case (CI));
            if not Is_Empty (Connections (CI)) then
               --  Parse the connections that are bound to a bus
               --  the connections are found in the interface view, not
               --  in the nodes, because of the Actual_Connection_Binding
               --  property that applies only to interface view connections
               --  Since the interface view can contain nested functions,
               --  the Parse_Connections has to go recursively in them
               --  to find all connection that are bound to a bus
               Rec_Parse_Connections (CI, Conns);
            end if;

            if not Is_Empty (Subcomponents (CI)) then
               Node      := Parse_Node (CI);
               Node.Name := US (Get_Name_String (Name (Identifier (Subs))));
               if Node.Name /= "interfaceview" then
                  Nodes.Insert (Key      => To_String (Node.Name),
                                New_Item => Node);
               end if;
            end if;
         elsif Get_Category_Of_Component (CI) = CC_Bus then  --  Bus
            Busses.Append (Parse_Bus (Subs, CI));
         else
            raise Deployment_View_Error with "Unknown component found: "
                                         & Get_Category_Of_Component (CI)'Img;
         end if;
         Subs := Next_Node (Subs);
      end loop;

      Result_DV := (Nodes          => Nodes,
                    Connections    => Conns,
                    Busses         => Busses);

      Result_DV.Fix_Bus_Connections (IV);

      return Result_DV;

   end Parse_Deployment_View;

   function Find_Node (Deployment    : Complete_Deployment_View;
                       Function_Name : String) return Option_Node.Option is
   begin
      for Node of Deployment.Nodes loop
         for Partition of Node.Partitions loop
            if Partition.Bound_Functions.Contains (Function_Name) then
               return Option_Node.Just (Node);
            end if;
         end loop;
      end loop;
      return Option_Node.Nothing;
   end Find_Node;

   function Find_Partition (Node          : Taste_Node;
                            Function_Name : String)
                            return Partition_Holder is
   begin
      for Partition of Node.Partitions loop
         if Partition.Bound_Functions.Contains (Function_Name) then
            return Partition_Holders.To_Holder (Partition);
         end if;
      end loop;
      return Partition_Holders.Empty_Holder;
   end Find_Partition;

   procedure Fix_Bus_Connections (DV : in out Complete_Deployment_View;
                                  IV : Complete_Interface_View) is
      use Option_Node;
   begin
      --  We must find the channel referenced in the bus connection
      --  among all the connections of the interface view to retrieve
      --  the end-to-end connections and set the source/dest port properly,
      --  i.e. not referencing any nesting functions (which are not mapped
      --  to any partition)
      Put_Debug ("Computing end-to-end connections (for bus bindings)");
      for C_DV : Bus_Connection of DV.Connections loop
         for C_IV : Connection of IV.Connections loop
            for Channel of C_IV.Channels loop
               if Channel = C_DV.Channel_Name then
                  if Find_Node (DV, To_String (C_IV.Caller))
                    = Find_Node (DV, To_String (C_IV.Callee))
                  then
                     Put_Debug ("No bus connection between "
                             & To_String (C_IV.Caller)
                             & "." & To_String (C_IV.RI_Name)
                             & " and " & To_String (C_IV.Callee)
                             & "." & To_String (C_IV.PI_Name));
                  else
                     Put_Debug ("Bus connection: " & To_String (C_IV.Caller)
                                & "." & To_String (C_IV.RI_Name)
                                & " -> " & To_String (C_IV.Callee)
                                & "." & To_String (C_IV.PI_Name));

                     --  Update the information in the deployment view
                     C_DV.Source_Function := C_IV.Caller;

                     --  C_DV.Protocol := C_IV.Caller;
                  --  C_DV.Source_Port     := C_IV.Callee & "_" & C_IV.RI_Name;
                     --  Port name
                     C_DV.Source_Port     := C_IV.Caller
                                             & "_" & C_IV.RI_Name
                                             & "_" & C_IV.Callee
                                             & "_" & C_IV.PI_Name;
                     C_DV.Dest_Function   := C_IV.Callee;
                     C_DV.Dest_Port       := C_IV.PI_Name;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
   end Fix_Bus_Connections;

   procedure Dump_Nodes (DV : Complete_Deployment_View; Output : File_Type) is
   begin
      for Each of DV.Nodes loop
         Put_Line (Output, "Node : " & To_String (Each.Name));
         for Partition of Each.Partitions loop
            Put_Line (Output, "  |_ Partition        : "
                      & To_String (Partition.Name));
            Put_Line (Output, "    |_ Coverage       : "
                      & Partition.Coverage'Img);
            Put_Line (Output, "    |_ Package        : "
                      & To_String (Partition.Package_Name));
            Put_Line (Output, "    |_ CPU Name       : "
                      & To_String (Partition.CPU_Name));
            Put_Line (Output, "    |_ CPU Platform   : "
                      & Partition.CPU_Platform'Img);
            Put_Line (Output, "    |_ CPU Classifier : "
                      & To_String (Partition.CPU_Classifier));
            if Partition.VP_Name /= "" then
               Put_Line (Output, "    |_ VP Name        : "
                         & To_String (Partition.VP_Name));
               Put_Line (Output, "    |_ VP Platform    : "
                         & Partition.VP_Platform'Img);
               Put_Line (Output, "    |_ VP Classifier  : "
                         & To_String (Partition.VP_Classifier));
            end if;

            Put (Output, "    |_ Contains       : ");
            for Bounded of Partition.Bound_Functions loop
               Put (Output, Bounded & " ");
            end loop;
            New_Line (Output);
         end loop;
         for Driver of Each.Drivers loop
            if not Driver.Accessed_Bus_Name.Is_Empty then
               Put_Line (Output, "  |_ Driver : " & To_String (Driver.Name));
               Put_Line (Output, "    |_ Name          : "
                         & To_String (Driver.Driver_Name));
               Put_Line (Output, "    |_ Package       : "
                         & To_String (Driver.Package_Name));
               Put_Line (Output, "    |_ Classifier    : "
                         & To_String (Driver.Device_Classifier));
               Put_Line (Output, "    |_ Processor     : "
                         & To_String (Driver.Associated_Processor_Name));
               Put_Line (Output, "    |_ Configuration : "
                         & To_String (Driver.Device_Configuration));
               Put_Line (Output, "    |_ Packetizer : "
                         & To_String (Driver.Device_Packetizer));
               Put_Line (Output, "    |_ Address : "
                         & To_String (Driver.Device_Address));
               Put_Line (Output, "    |_ Device_Transmission : "
                         & To_String (Driver.Device_Transmission));
               Put_Line (Output, "    |_ Device_Throughput : "
                         & To_String (Driver.Device_Throughput));
               Put_Line (Output, "    |_ Device_Max_Blocking : "
                         & To_String (Driver.Device_Max_Blocking));
               Put_Line (Output, "    |_ Device_Min_Packet_Size : "
                         & To_String (Driver.Device_Min_Packet_Size));
               Put_Line (Output, "    |_ Device_Speed_Factor : "
                         & To_String (Driver.Device_Speed_Factor));
               Put_Line (Output, "    |_ Protocol : "
                         & To_String (Driver.Device_Protocol));
               Put_Line (Output, "    |_ Bus_Name      : "
                         & Driver.Accessed_Bus_Name.Element);
               Put_Line (Output, "    |_ Port_Name     : "
                         & Driver.Accessed_Port_Name.Element);
               Put_Line (Output, "    |_ ASN.1 File    : "
                         & To_String (Driver.ASN1_Filename));
               Put_Line (Output, "    |_ ASN.1 Type    : "
                         & To_String (Driver.ASN1_Typename));
               Put_Line (Output, "    |_ ASN.1 Module  : "
                         & To_String (Driver.ASN1_Module));
               Put_Line (Output, "    |_ Init function : "
                         & To_String (Driver.Init_Function));
               Put_Line (Output, "    |_ Init function : "
                         & To_String (Driver.Send_Function));
               Put_Line (Output, "    |_ Language : "
                         & To_String (Driver.Init_Language));
            end if;
         end loop;
      end loop;
   end Dump_Nodes;

   procedure Dump_Connections (DV     : Complete_Deployment_View;
                               Output : File_Type) is
   begin
      for Each of DV.Connections loop
         Put_Line (Output, "Connection on bus : " & To_String (Each.Bus_Name));
         Put_Line (Output, "  |_ Protocol : "
                   & To_String (Each.Protocol));
         Put_Line (Output, "  |_ Source Function : "
                   & To_String (Each.Source_Function));
         Put_Line (Output, "  |_ Source Port : "
                   & To_String (Each.Source_Port));
         Put_Line (Output, "  |_ Dest Function : "
                   & To_String (Each.Dest_Function));
         Put_Line (Output, "  |_ Dest Port   : " & To_String (Each.Dest_Port));
      end loop;
   end Dump_Connections;

   procedure Dump_Busses (DV : Complete_Deployment_View; Output : File_Type) is
   begin
      for Each of DV.Busses loop
         Put_Line (Output, "Bus : " & To_String (Each.Name));
         Put_Line (Output, "  |_ Package    : "
                   & To_String (Each.AADL_Package));
         Put_Line (Output, "  |_ Classifier : " & To_String (Each.Classifier));
         for Prop of Each.Properties loop
            Put_Line (Output, "    |_ Property: " & To_String (Prop.Name)
                      & " = " & To_String (Prop.Value));
         end loop;
      end loop;
   end Dump_Busses;

   procedure Debug_Dump (DV : Complete_Deployment_View; Output : File_Type) is
   begin
      DV.Dump_Nodes       (Output);
      DV.Dump_Busses      (Output);
      DV.Dump_Connections (Output);
   end Debug_Dump;

end TASTE.Deployment_View;
