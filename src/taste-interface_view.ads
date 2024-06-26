--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

--  Interface View parser

with Ada.Containers.Indefinite_Ordered_Maps,
     Ada.Containers.Indefinite_Vectors,
     Ada.Strings.Unbounded,
     Ada.Strings.Equal_Case_Insensitive,
     Ada.Strings.Less_Case_Insensitive,
     Text_IO,
     Templates_Parser,
     Ocarina,
     Ocarina.Types,
     Option_Type,
     TASTE.Parser_Utils;

use Ada.Containers,
    Ada.Strings.Unbounded,
    Text_IO,
    Templates_Parser,
    Ocarina,
    Ocarina.Types,
    TASTE.Parser_Utils;

package TASTE.Interface_View is

   use Option_UString,
       Option_ULL,
       String_Vectors;

   --  Exceptions specific to the Interface View
   No_RCM_Error      : exception;   -- Missing Periodic, Sporadic... property
   Interface_Error   : exception;   -- Any kind of interface parsing error
   Function_Error    : exception;   -- Any kind of function parsing error

   --  List of Ocarina AADL models needed to parse the interface view
   Interface_AADL_Lib : String_Vectors.Vector :=
     Empty_Vector
     & "TASTE_IV_Properties.aadl"
     & "taste_properties.aadl";
--     & "arinc653.aadl";

   type Synchronism is (Sync, Async);

   function Get_Language (E : Node_Id) return String;

   type Supported_RCM_Operation_Kind is (Unprotected_Operation,
                                         Protected_Operation,
                                         Cyclic_Operation,
                                         Sporadic_Operation,
                                         Event_Operation,
                                         Message_Operation,
                                         Component_Management_Operation,
                                         Any_Operation);

   function Get_RCM_Operation_Kind (E : Node_Id)
     return Supported_RCM_Operation_Kind;

   function Get_RCM_Operation (E : Node_Id) return Node_Id;

   function Get_Event_ID (D : Node_Id) return String;
   function Get_Event_Info (D : Node_Id) return String;
   function Get_Event_Type (D : Node_Id) return String;
   function Get_Message_ID (D : Node_Id) return String;
   function Get_Message_Content (D : Node_Id) return String;
   function Get_Message_Size (D : Node_Id) return String;
   function Get_WCET (D : Node_Id) return String;
   function Get_Deadline (D : Node_Id) return String;
   function Get_Store_Message (D : Node_Id) return String;
   function Get_Target_Component (D : Node_Id) return String;

   function Get_RCM_Period (D : Node_Id) return Unsigned_Long_Long;

   type Supported_ASN1_Encoding is (Default, Native, UPER, ACN);

   function Get_ASN1_Encoding (E : Node_Id) return Supported_ASN1_Encoding;

   type Supported_ASN1_Basic_Type is (ASN1_Sequence,
                                      ASN1_SequenceOf,
                                      ASN1_Enumerated,
                                      ASN1_Set,
                                      ASN1_SetOf,
                                      ASN1_Integer,
                                      ASN1_Boolean,
                                      ASN1_Real,
                                      ASN1_OctetString,
                                      ASN1_Choice,
                                      ASN1_String,
                                      ASN1_Unknown);

   function Get_ASN1_Basic_Type (E : Node_Id) return Supported_ASN1_Basic_Type;

   function Get_Ada_Package_Name (D : Node_Id) return Name_Id;

   function Get_Ellidiss_Tool_Version (D : Node_Id) return Name_Id;

   function Get_ASN1_Module_Name (D : Node_Id) return String;

   type Parameter_Direction is (param_in, param_out);

   type ASN1_Parameter is
      record
         Name,
         Sort,
         ASN1_Module     : Unbounded_String;
         ASN1_Basic_Type : Supported_ASN1_Basic_Type;
         ASN1_File_Name  : Unbounded_String;
         Encoding        : Supported_ASN1_Encoding;
         Direction       : Parameter_Direction;
      end record;

   package Parameters is new Indefinite_Vectors (Natural, ASN1_Parameter);

   --  Remote entities reference to the other ends of an interface, when it
   --  is connected. There can be several, but connections are optional.
   type Remote_Entity is
      record
         Function_Name,
         Interface_Name,
         Instance_Of,
         Language        : Unbounded_String;
      end record;

   package Remote_Entities is new Indefinite_Vectors (Natural, Remote_Entity);

   type Taste_Interface is tagged
      record
         Name,
         Parent_Function,
         Language          : Unbounded_String;
         Remote_Interfaces : Remote_Entities.Vector;
         Params            : Parameters.Vector;
         RCM               : Supported_RCM_Operation_Kind;
         Period_Or_MIAT    : Unsigned_Long_Long;
         WCET_ms           : Unbounded_String;
         Send_WCET_ms           : Unbounded_String;
         Receive_WCET_ms           : Unbounded_String;
         Queue_WCET_ms           : Unbounded_String;
         Jitter           : Unbounded_String;
         Deadline           : Unbounded_String;
         Queue_Size        : Option_ULL.Option := Option_ULL.Nothing;
         Event_Name        : Unbounded_String;
         Event_Info        : Unbounded_String;
         Event_Type        : Unbounded_String;
         Event_ID          : Unbounded_String;
         Message_ID        : Unbounded_String;
         Message_Content   : Unbounded_String;
         Message_Size      : Unbounded_String;
         Store_Message     : Unbounded_String;
         Target_Name       : Unbounded_String;
         User_Properties   : Property_Maps.Map;
         Is_Timer          : Boolean := False;
         --  Following attributes are set in SpaceCreator at IV level
         --  and are used to set task attributes in Concurrency View
         Priority          : Integer := 1;
         Stack_Size        : Integer := 4096; --  in bytes
         Dispatch_Offset   : Integer := 0;  --  in ms
      end record;

   function Interface_To_Template (TI : Taste_Interface) return Translate_Set;

   package Interfaces_Maps is new Indefinite_Ordered_Maps (String,
                                                           Taste_Interface);

   type Context_Parameter is
      record
         Name           : Unbounded_String;
         Sort           : Unbounded_String;
         Default_Value  : Unbounded_String;
         ASN1_Module    : Unbounded_String;
         ASN1_File_Name : Option_UString.Option := Option_UString.Nothing;
      end record;

   package Ctxt_Params is new Indefinite_Vectors (Natural, Context_Parameter);

   --  Type representing a function in the form of a template (for backends)
   package Template_Vectors is new Indefinite_Vectors (Natural, Translate_Set);
   type Func_As_Template is
      record
         --  Header includes all function attributes (name, language, etc.)
         Header   : Translate_Set;
         Provided,
         Required : Template_Vectors.Vector;
      end record;

   package Func_Maps is new Indefinite_Ordered_Maps (String, Func_As_Template);

   type Taste_Terminal_Function is tagged
      record
         Name            : Unbounded_String;
         DataStore       : Unbounded_String;
         DataStoreSize   : Unbounded_String;
         FDIR            : Unbounded_String;
         Function_Priority : Option_ULL.Option := Option_ULL.Nothing;
         F_Priority      : Option_ULL.Option := Option_ULL.Nothing;
         Context         : Unbounded_String      := Null_Unbounded_String;
         Full_Prefix     : Option_UString.Option := Option_UString.Nothing;
         Language        : Unbounded_String;
         Zip_File        : Option_UString.Option := Option_UString.Nothing;
         Context_Params  : Ctxt_Params.Vector;
         Directives      : Ctxt_Params.Vector;  --  TASTE Directives
         Simulink        : Ctxt_Params.Vector;  --  Simulink Tuneable Params
         Implems         : Ctxt_Params.Vector;  --  Implementatations
         User_Properties : Property_Maps.Map;
         Timers          : String_Vectors.Vector;
         Provided        : Interfaces_Maps.Map;
         Required        : Interfaces_Maps.Map;
         Is_Type         : Boolean := False;
         Instance_Of     : Unbounded_String := US ("");
         Min_Instances   : Integer := 1;        -- Min and Max number of
         Max_Instances   : Integer := 1;        -- instances (1 by default)
         Instance_Number : Integer := 1;
         Instance_Name   : Unbounded_String;    -- Name before renaming
      end record;

   function Function_To_Template (F : Taste_Terminal_Function)
                           return Func_As_Template;

   --  Key for the function map is case insensitive
   function "="(Left, Right : Case_Insensitive_String) return Boolean
       renames Ada.Strings.Equal_Case_Insensitive;
   function "<"(Left, Right : Case_Insensitive_String) return Boolean
       renames Ada.Strings.Less_Case_Insensitive;
   package Function_Maps is new Indefinite_Ordered_Maps
     (Case_Insensitive_String, Taste_Terminal_Function);

   type Connection is
      record
         Caller,
         Callee,
         RI_Name,
         PI_Name : Unbounded_String;
         --  Channels: list of channels needed to go from RI to PI
         Channels : String_Vectors.Vector;
      end record;

   package Option_Connection is new Option_Type (Connection);
   subtype Optional_Connection is Option_Connection.Option;

   package Channels is new Indefinite_Vectors (Natural, Connection);
   package Connection_Maps is new Indefinite_Ordered_Maps (String,
                                                          Channels.Vector,
                                                          "=" => Channels."=");

   type Complete_Interface_View is tagged
      record
         Flat_Functions  : Function_Maps.Map;
         Connections     : Channels.Vector;
      end record;

   --  Function to build up the Ada AST by transforming the one from Ocarina
   function Parse_Interface_View (Interface_Root : Node_Id)
                                  return Complete_Interface_View
     with Pre => Interface_Root /= No_Node;

   procedure Rename_Provided_Interface (IV    : in out Complete_Interface_View;
                                        Func  : String;
                                        Iface : String;
                                        To    : String);

   procedure Rename_Required_Interface (IV    : in out Complete_Interface_View;
                                        Func  : String;
                                        Iface : String;
                                        To    : String);

   procedure Debug_Dump (IV : Complete_Interface_View; Output : File_Type);

end TASTE.Interface_View;
