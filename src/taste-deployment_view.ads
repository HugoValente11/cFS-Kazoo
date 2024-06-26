--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2022 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --
--  Deployment View parser

with Ada.Containers.Indefinite_Ordered_Maps,
     Ada.Containers.Indefinite_Vectors,
     Ada.Containers.Indefinite_Holders,
     Ada.Strings.Unbounded,
     Text_IO,
     Templates_Parser,
     Ocarina,
     Ocarina.Types,
     Ocarina.Backends.Properties,
     Option_Type,
     TASTE.Parser_Utils,
     TASTE.Interface_View;

use Ada.Containers,
    Ada.Strings.Unbounded,
    Text_IO,
    Templates_Parser,
    Ocarina,
    Ocarina.Types,
    Ocarina.Backends.Properties,
    TASTE.Parser_Utils,
    TASTE.Interface_View;

package TASTE.Deployment_View is

   use String_Vectors,
       String_Sets;

   --  Exceptions specific to the deployment view
   Deployment_View_Error       : exception;
   Device_Driver_Error         : exception;
   Empty_Deployment_View_Error : exception;

   --  List of Ocarina AADL models needed to parse the deployment view
   Deployment_AADL_Lib : String_Vectors.Vector :=
     Empty_Vector
     & "TASTE_DV_Properties.aadl"
     & "TASTE_IV_Properties.aadl"
     & "aadl_project.aadl"
     & "taste_properties.aadl"
     & "Cheddar_Properties.aadl"
     & "communication_properties.aadl"
     & "deployment_properties.aadl"
     & "thread_properties.aadl"
     & "timing_properties.aadl"
     & "programming_properties.aadl"
     & "memory_properties.aadl"
     & "modeling_properties.aadl"
     & "arinc653.aadl"
     & "base_types.aadl"
     & "data_model.aadl"
     & "deployment.aadl";

   --  Initialize Ocarina and instantiate the deployment view, return root.
   function Initialize (Root : Node_Id) return Node_Id
     with Pre => Root /= No_Node;

   type Taste_Bus is
      record
         Name,
         AADL_Package,
         Classifier   : Unbounded_String;
         Properties   : Property_Maps.Map;
      end record;

   package Taste_Busses is new Indefinite_Vectors (Natural, Taste_Bus);

   type Bus_Connection is tagged
      record
         Channel_Name,
         Source_Function,
         Source_Port,
         Protocol,
         Bus_Name,
         Dest_Function,
         Dest_Port   : Unbounded_String;
      end record;

   package Bus_Connections is new Indefinite_Vectors (Natural, Bus_Connection);

   type Taste_Device_Driver is tagged
      record
         Name,
         Driver_Name,
         Package_Name,
         Device_Classifier,
         Associated_Processor_Name,
         Device_Configuration,
         Device_Packetizer,
         Device_Address,
         Device_Network_Number,
         Device_Protocol,
         Device_Transmission,
         Device_Throughput,
         Device_Max_Blocking,
         Device_Max_Packet_Size,
         Device_Min_Packet_Size,
         Device_Speed_Factor,
         Init_Function,
         Init_Language,
         Send_Function,
         ASN1_Filename,
         Protocol,
         ASN1_Typename,
         ASN1_Module               : Unbounded_String;
         --  Optional fields: exist only if device is connected
         Accessed_Bus_Name,
         Accessed_Port_Name        : String_Holder;
      end record;

   function Device_Instance_Name (Driver : Taste_Device_Driver) return String;

   package Taste_Drivers is
     new Indefinite_Vectors (Natural, Taste_Device_Driver);

   function Drivers_To_Template (Drivers : Taste_Drivers.Vector)
                                return Translate_Set;

   --  Memory component specified at node level
   type Taste_Memory is
      record
         Name             : Unbounded_String;
         Bound_Partitions : String_Sets.Set;
      end record;

   --  Partition in the deployment view
   --  Supported_Execution_Platform is defined in:
   --  ocarina/src/backends/ocarina-backends-properties.ads
   --  Values are Plaform_Native, Platform_Leon_Rtems, etc.
   type Taste_Partition is tagged
      record
         Name            : Unbounded_String;
         Coverage        : Boolean := False;
         Package_Name    : Unbounded_String;
         CPU_Name        : Unbounded_String; --  AADL Identifier
         CPU_Family      : Unbounded_String; --  e.g. leon3
         CPU_Instance    : Unbounded_String; --  e.g. rtems_posix
         CPU_Platform    : Supported_Execution_Platform;
         CPU_Classifier  : Unbounded_String;
         CPU_Total_Time  : Unbounded_String := US ("");  -- TSP major frame
         VP_Package_Name : Unbounded_String := US ("");  -- Virtual Processor
         VP_Name         : Unbounded_String := US ("");
         VP_Platform     : Supported_Execution_Platform := Platform_None;
         VP_Classifier   : Unbounded_String := US ("");
         VP_Duration     : Unbounded_String := US ("");  --  TSP frame duration
         Memory_Region   : Unbounded_String := US ("");  --  TSP only
         Ada_Runtime     : Unbounded_String; --  if CPU_Platform = GNAT_Runtime
         Bound_Functions : String_Vectors.Vector;
         User_Properties : Property_Maps.Map;  -- From TASTE_DV_Properties.aadl
      end record;

   --  Make a Templates Parser translate set, to generate code
   function To_Template (P : Taste_Partition) return Translate_Set is
     (Properties_To_Template (P.User_Properties)
       & Assoc  ("Name",            P.Name)
       & Assoc ("Coverage",        P.Coverage)
       & Assoc ("Package_Name",    P.Package_Name)
       & Assoc ("CPU_Name",        P.CPU_Name)
       & Assoc ("CPU_Family",      P.CPU_Family)
       & Assoc ("CPU_Instance",    P.CPU_Instance)
       & Assoc ("CPU_Platform",    P.CPU_Platform'Img)
       & Assoc ("CPU_Classifier",  P.CPU_Classifier)
       & AssoC ("VP_Package_Name", P.VP_Package_Name)
       & Assoc ("VP_Name",         P.VP_Name)
       & Assoc ("VP_Platform",     P.VP_Platform'Img)
       & Assoc ("VP_Classifier",   P.VP_Classifier)
       & Assoc ("VP_Duration",     P.VP_Duration)
       & Assoc ("Memory_Region",   P.Memory_Region)
       & Assoc ("Ada_Runtime",     P.Ada_Runtime)
       & Assoc ("Bound_Functions", To_Template_Tag (P.Bound_Functions)));

   --  package Option_Partition is new Option_Type (Taste_Partition);
   package Partition_Holders is new Indefinite_Holders (Taste_Partition);
   subtype Partition_Holder is Partition_Holders.Holder;

   package Taste_Partitions is
     new Indefinite_Ordered_Maps (String, Taste_Partition);

   --  Virtual processors are used in TSP systems to represent partitions
   type Virtual_Processor is tagged
      record
         Name,
         Package_Name,
         Platform,
         Classifier : Unbounded_String;
      end record;

   package Virtual_Processors is
      new Indefinite_Ordered_Maps (String, Virtual_Processor);

   type Taste_Node is tagged
      record
         Name            : Unbounded_String;
         Drivers         : Taste_Drivers.Vector;
         Partitions      : Taste_Partitions.Map;
         Memory          : Taste_Memory;
         Virtual_CPUs    : Virtual_Processors.Map;
         Package_Name    : Unbounded_String;
         CPU_Name        : Unbounded_String;   --  AADL Identifier
         CPU_Family      : Unbounded_String;   --  e.g. leon3
         CPU_Instance    : Unbounded_String;   --  e.g. rtems_posix
         CPU_Platform    : Supported_Execution_Platform;
         CPU_Classifier  : Unbounded_String;
         CPU_Duration    : Unbounded_String := US ("");  -- TSP Major frame
         Ada_Runtime     : Unbounded_String;  --  when Platform = GNAT_Runtime
      end record;

   --  Helper function: find the partition where a function is bounded
   function Find_Partition (Node          : Taste_Node;
                            Function_Name : String)
                            return Partition_Holder;
                           --  Option_Partition.Option;

   package Node_Maps is new Indefinite_Ordered_Maps (String, Taste_Node);

   type Complete_Deployment_View is tagged
      record
         Nodes       : Node_Maps.Map;
         Connections : Bus_Connections.Vector;
         Busses      : Taste_Busses.Vector;
      end record;

   --  Helper function: find the node of a given function
   package Option_Node is new Option_Type (Taste_Node);
   function Find_Node (Deployment    : Complete_Deployment_View;
                       Function_Name : String) return Option_Node.Option;

   --  Function to build up the Ada AST by transforming the one from Ocarina
   function Parse_Deployment_View (System : Node_Id;
                                   IV     : Complete_Interface_View)
                                   return Complete_Deployment_View
     with Pre => System /= No_Node;

   procedure Dump_Nodes       (DV     : Complete_Deployment_View;
                               Output : File_Type);
   procedure Dump_Connections (DV     : Complete_Deployment_View;
                               Output : File_Type);
   procedure Dump_Busses      (DV     : Complete_Deployment_View;
                               Output : File_Type);
   procedure Debug_Dump       (DV     : Complete_Deployment_View;
                               Output : File_Type);

   --  Connect end-to-end functions when there are nested functions
   procedure Fix_Bus_Connections (DV : in out Complete_Deployment_View;
                                  IV : Complete_Interface_View);

   --  Define a holder type for the deployment view - to be used as an option
   --  type in the complete TASTE data model (Deployment view may be absent
   --  if the tool is only called to generate skeletons).
   --  Holder containers are a form of built-in option type in Ada
   package Deployment_View_Holders is new Indefinite_Holders
     (Complete_Deployment_View);

   subtype Deployment_View_Holder is Deployment_View_Holders.Holder;

end TASTE.Deployment_View;
