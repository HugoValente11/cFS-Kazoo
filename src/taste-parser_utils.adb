--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

with Ada.Characters.Latin_1,
     Ada.Strings.Maps,
     Ada.Strings.Fixed,
     Ada.Strings,
     Ada.Characters.Handling,
     Ada.Directories,
     Ada.Command_Line,
     Ada.Environment_Variables,
     GNAT.OS_Lib,
     GNAT.Strings,
     GNAT.Command_Line,
     Templates_Parser.Utils,
     Templates_Parser.Query,
     Ocarina.AADL_Values,
     Ocarina.Configuration,
     Ocarina.FE_AADL.Parser,
     Ocarina.Instances.Queries,
     Ocarina.ME_AADL.AADL_Tree.Entities.Properties,
     TASTE.Parser_Version;

package body TASTE.Parser_Utils is

   use Ada.Characters.Handling,
       GNAT.OS_Lib,
       GNAT.Command_Line,
       Ada.Directories,
       Templates_Parser.Utils,
       Ocarina.ME_AADL.AADL_Tree.Entities.Properties,
       Ocarina.Instances.Queries;

   procedure Put_Info (Info : String) is
   begin
      Put_Line (Yellow_Bold & "[INFO] " & No_Color & Info & No_Color);
   end Put_Info;

   procedure Put_Error (Error : String) is
   begin
      Put_Line (Red_Bold & "[ERROR] " & White_Bold & Error & No_Color);
   end Put_Error;

   procedure Put_Debug (Debug : String) is
   begin
      if Debug_Mode then
         Put_Line (White_Bold & "[DEBUG] " & No_Color & Debug & No_Color);
      end if;
   end Put_Debug;

   procedure Banner is
      The_Banner : constant String :=
        Yellow_Bold & "TASTE/Kazoo" & No_Color & " (Version "
        & TASTE.Parser_Version.Parser_Release & ")"
        & ASCII.LF & ASCII.CR & White_Bold
        & "Copyright (C) Maxime Perrotin / European Space Agency"
        & ASCII.LF & ASCII.CR & No_Color
        & "Based on " & TASTE.Parser_Version.Ocarina_Version;
   begin
      Put_Line (The_Banner);
      New_Line;
   end Banner;

   --  Generate documentation for a translate set
   procedure Document_Template (Category : Template_Category;
                                Tags     : Translate_Set)
   is
      Result : Unbounded_String :=
        "{| class=""wikitable""" & ASCII.LF
        & "!Parameter name" & ASCII.LF
        & "!Description" & ASCII.LF
        & US ("|-");

      procedure Action (Item : Association; Quit : in out Boolean) is
      begin
         Result :=
           Result & ASCII.LF
           & "|" & US (Templates_Parser.Query.Variable (Item)) & ASCII.LF
           & "|@@ADD DESCRIPTION@@" & ASCII.LF
           & "|-";
         --          & Templates_Parser.Query.Kind (Item)'Img);
         Quit := False;
      end Action;
      procedure Iterate is new For_Every_Association (Action);
   begin
      if Doc_Map.Contains (Category) then
         --  Already documented from a previous call - ignore
         --  (Skeleton and Glue folders share the same template structures)
         return;
      end if;
      Put_Debug ("Documenting template category: " & Category'Img);
      Iterate (Tags);
      Result :=
        Result & ASCII.LF
        & "|}";
      Doc_Map.Insert (Key => Category, New_Item => To_String (Result));
   end Document_Template;

   procedure Dump_Documentation (Output_Folder : String) is
      use Template_Doc_Maps;
      Output_File   : File_Type;
   begin
      Create_Path (Output_Folder);
      for Each in Doc_Map.Iterate loop
         Put_Debug ("Dump documentation of " & Key (Each)'Img);
         Create (File => Output_File,
                 Mode => Out_File,
                 Name => Output_Folder & "/" & To_Lower (Key (Each)'Img));
         Put_Line (Output_File, Element (Each));
         Close (Output_File);
      end loop;
   end Dump_Documentation;

   --  Strip function as in Python
   function Strip_String (Input_String : String) return String is
      use Ada.Characters.Latin_1;
      Strip_Set : constant Ada.Strings.Maps.Character_Set :=
           Ada.Strings.Maps.To_Set
              (" " & HT & VT & NUL & LF & CR & BS & EOT & FF);
   begin
      return Ada.Strings.Fixed.Trim (Input_String, Strip_Set, Strip_Set);
   end Strip_String;

   function Strip_String (Input_US : Unbounded_String) return Unbounded_String
   is (US (Strip_String (To_String (Input_US))));

   --  str.join as in Python - join string arrays with a separator
   function Join_Strings (Str_Set : String_Sets.Set;
                          Sep     : String             := ", ";
                          C       : String_Sets.Cursor :=
                            String_Sets.No_Element)
                          return String
   is
      use String_Sets;
   begin
      return
       (if C = String_Sets.No_Element then "" else
       (if C /= Str_Set.First then Sep else "")
        & String_Sets.Element (C)
        & Join_Strings
          (Str_Set => Str_Set,
           C => String_Sets.Next (C),
           Sep => Sep));
   end Join_Strings;

   function Filter_First_Elem
     (unused_Value, Parameters : String;
      Context           : Filter_Context) return String
   is
      Assoc : Association;
      Table : Tag;
   begin
      Assoc := Get (Context.Translations, Parameters);

      if Assoc = Null_Association then
         return "";
      end if;
      Table := Get (Assoc);
      return Item (Table, 1);
   exception
      when Constraint_Error =>
         --  If Association is not a Tag (table) or if zero elements
         return "";
   end Filter_First_Elem;

   function Filter_Uniq
     (Value, Parameters : String;
      unused_Context    : Filter_Context) return String
   --  Value is the tag name (list), and Parameter must be a separator
   is
      use String_Sets, Ada.Strings.Fixed;
      Unique_Set : String_Sets.Set;
      Nb         : constant Natural :=
        Ada.Strings.Fixed.Count (Value, Parameters);
      From : Natural := Value'First;
      To   : Natural;
   begin
      if Nb = 0 then
         Unique_Set.Insert (Value);
      else
         for I in 0 .. Nb loop
            To := Index (Value, Parameters, From => From);
            if To = 0 then
               To := Value'Last + 1;
            end if;
            Unique_Set.Union (To_Set (Strip_String (Value (From .. To - 1))));
            From := To + 1;
         end loop;
      end if;
      return Join_Strings
        (Unique_Set, Sep => Parameters, C => Unique_Set.First);
   end Filter_Uniq;

   procedure Parse_Command_Line (Result : out Taste_Configuration) is
      Config  : Command_Line_Configuration;
      Version : aliased Boolean := False;
      Command : constant String := Ada.Command_Line.Command_Name;
      use String_Holders;

      IV,
      DeplV,
      DataV,
      OutDir,
      DeplDir,
      Target : aliased GNAT.Strings.String_Access := null;
   begin
      --  Retrieve the path of the kazoo binary, to have a base prefix
      --  to find the templates folder
      if Command /= "kazoo" then
         --  Command used a explicit path to call kazoo - use it
         Result.Binary_Path := To_Holder (Get_Program_Directory);
      else
         --  We must find kazoo in the PATH
         --  This will work only on Linux because the PATH separator is ":"
         --  while on Windows it is ";"
         declare
            Path : constant String := Ada.Environment_Variables.Value ("PATH");
            Nb   : constant Natural := Ada.Strings.Fixed.Count (Path, ":");
            From : Natural := Path'First;
            To   : Natural;
         begin
            if Nb = 0 then
               To   := Path'Last;
            end if;
            for I in 0 .. Nb loop
               To := Ada.Strings.Fixed.Index (Path, ":", From => From);
               if To = 0 then
                  To := Path'Last + 1;
               end if;
               if Ada.Directories.Exists
                 (Path (From .. To - 1) & "/" & "kazoo")
               then
                  --  Found the folder containing the kazoo binary
                  Result.Binary_Path := To_Holder
                    (Path (From .. To - 1) & "/");
                  exit;
               end if;
               From := To + 1;
            end loop;
         end;
      end if;

      Define_Switch (Config, Output => IV'Access,
                     Switch         => "-i:",
                     Long_Switch    => "--interfaceview=",
                     Help           => "Mandatory interface view (AADL model)",
                     Argument       => "InterfaceView.aadl");
      Define_Switch (Config, Output => DeplV'Access,
                     Switch         => "-c:",
                     Long_Switch    => "--deploymentview=",
                     Help           => "Optional deployment view (AADL model)",
                     Argument       => "DeploymentView.aadl");
      Define_Switch (Config, Output => DataV'Access,
                     Switch         => "-d:",
                     Long_Switch    => "--dataview=",
                     Help           => "Optional data view (AADL model)",
                     Argument       => "DataView.aadl");
      Define_Switch (Config, Output => Result.Check_Data_View'Access,
                     Switch         => "-y",
                     Long_Switch    => "--check-dataview",
                     Help           => "Check Data View");
      Define_Switch (Config, Output => OutDir'Access,
                     Switch         => "-o:",
                     Long_Switch    => "--output=",
                     Help           => "Output directory (created if absent)",
                     Argument       => "Folder");
      Define_Switch (Config, Output => Target'Access,
                     Switch         => "-t:",
                     Long_Switch    => "--target=",
                     Help           => "User-defined target (default pohic)",
                     Argument       => "pohic");
      Define_Switch (Config, Output => Result.Skeletons'Access,
                     Switch         => "-w",
                     Long_Switch    => "--gw",
                     Help           => "Generate models and code skeletons");
      Define_Switch (Config, Output => Result.Glue'Access,
                     Switch         => "-l",
                     Long_Switch    => "--glue",
                     Help           => "Generate glue code");
      Define_Switch (Config, Output => Result.Use_POHIC'Access,
                     Switch         => "-p",
                     Long_Switch    => "--polyorb-hi-c",
                     Help           => "Use PolyORB-HI-C runtime");
      Define_Switch (Config, Output => Result.Timer_Resolution'Access,
                     Switch         => "-x:",
                     Long_Switch    => "--timer=",
                     Initial        => 10,
                     Help           => "Timer resolution (default 10 ms)");
      Define_Switch (Config, Output => Result.Debug_Flag'Access,
                     Switch         => "-g",
                     Long_Switch    => "--debug",
                     Help           => "Set debug mode");
      Define_Switch (Config, Output => Result.No_Stdlib'Access,
                     Switch         => "-s",
                     Long_Switch    => "--no-stdlib",
                     Help           => "Don't use ocarina_components.aadl");
      Define_Switch (Config, Output => Result.Generate_Doc'Access,
                     Switch         => "-k",
                     Long_Switch    => "--doc",
                     Help           => "Generate templates documentation");
      Define_Switch (Config, Output => Version'Access,
                     Switch         => "-v",
                     Long_Switch    => "--version",
                     Help           => "Display tool version");
      Define_Switch (Config, Output => DeplDir'Access,
                     Switch         => "-e:",
                     Long_Switch    => "--cv_template_dir=",
                     Help           => "Concurrency View templates dir name",
                     Argument       => "concurrency_view");
      Getopt (Config);

      loop
         declare
            S : constant String := Get_Argument;
         begin
            exit when S'Length = 0;
            Result.Other_Files.Append (S);
         end;
      end loop;

      --  We must set the values in the holders based on the parsed strings
      Result.Interface_View :=
        (if IV /= null and then IV.all'Length > 0
         then To_Holder (IV.all) else To_Holder (Default_Interface_View));

      Result.Deployment_View :=
        (if DeplV /= null and then DeplV.all'Length > 0
         then To_Holder (DeplV.all) else
             (if Ada.Directories.Exists (Default_Deployment_View) then
             To_Holder (Default_Deployment_View) else Empty_Holder));

      Result.Data_View :=
        (if DataV /= null and then DataV.all'Length > 0
         then To_Holder (DataV.all) else To_Holder (Default_Data_View));

      Result.Output_Dir :=
        (if OutDir /= null and then OutDir.all'Length > 0
         then To_Holder (OutDir.all)
         else To_Holder ("work"));

      Result.CV_Templates_Dir :=
        (if DeplDir /= null and then DeplDir.all'Length > 0
         then To_Holder (DeplDir.all)
         else To_Holder ("concurrency_view"));

      Result.Target :=
        (if Target /= null and then Target.all'Length > 0
         then To_Holder (Target.all)
         else To_Holder ("pohic"));

      if Version then
         raise Exit_From_Command_Line;
      end if;
      Debug_Mode := Result.Debug_Flag;

   end Parse_Command_Line;

   function Properties_To_Template (Properties : Property_Maps.Map;
                                    Prefix     : String := "")
                                    return Translate_Set
   is
      Names,
      Values : Vector_Tag;
   begin
      for P of Properties loop
         Names  := Names  & P.Name;
         Values := Values & P.Value;
      end loop;

      return (+Assoc  (Prefix & "Property_Names", Names)
              & Assoc (Prefix & "Property_Values", Values));
   end Properties_To_Template;

   function To_Template_Tag (SV : String_Vectors.Vector) return Tag is
      Result : Tag;
   begin
      for Each of SV loop
         Result := Result & Each;
      end loop;
      return Result;
   end To_Template_Tag;

   function To_Template (Config : Taste_Configuration) return Translate_Set is
      Vec,
      Shared_Libs : Tag;
   begin
      for Each of Config.Other_Files loop
         Vec := Vec & Each;
      end loop;

      for Each of Config.Shared_Types loop
         Shared_Libs := Shared_Libs & Each;
      end loop;

      return (+Assoc  ("Interface_View", Config.Interface_View.Element)
              & Assoc ("Deployment_View",
                (if Config.Deployment_View.Is_Empty
                 then "<none>"
                 else Config.Deployment_View.Element))
              & Assoc ("Data_View",        Config.Data_View.Element)
              & Assoc ("Binary_Path",      Config.Binary_Path.Element)
              & Assoc ("Check_Data_View",  Config.Check_Data_View)
              & Assoc ("Output_Dir",       Config.Output_Dir.Element)
              & Assoc ("Target",           Config.Target.Element)
              & Assoc ("Skeletons",        Config.Skeletons)
              & Assoc ("Glue",             Config.Glue)
              & Assoc ("Use_POHIC",        Config.Use_POHIC)
              & Assoc ("Timer_Resolution", Config.Timer_Resolution)
              & Assoc ("Debug_Flag",       Config.Debug_Flag)
              & Assoc ("No_Stdlib_Flag",   Config.No_Stdlib)
              & Assoc ("Timer_Resolution", Config.Timer_Resolution)
              & Assoc ("Shared_Lib_Dir",   Config.Shared_Lib_Dir)
              & Assoc ("Shared_Types",     Shared_Libs)
              & Assoc ("Other_Files",      Vec));
   end To_Template;

   procedure Debug_Dump (Config : Taste_Configuration; Output : File_Type) is
      Template : constant Translate_Set := Config.To_Template;
   begin
      Put_Line (Output,
        Parse (Config.Binary_Path.Element & "templates/configuration.tmplt",
         Template));
   end Debug_Dump;

   -----------------------
   -- Get_APLC_Binding --
   -----------------------

   function Get_APLC_Binding (E : Node_Id) return List_Id is
      APLC_Binding : constant Name_Id :=
        Get_String_Name ("taste::aplc_binding");
   begin
      return (if Is_Defined_Property (E, APLC_Binding)
              then Get_List_Property (E, APLC_Binding)
              else No_List);
   end Get_APLC_Binding;

   ------------------------
   -- Get_Interface_Name --
   ------------------------

   function Get_Interface_Name (D : Node_Id) return Name_Id is
     (Get_String_Property (D, Get_String_Name ("taste::interfacename")));

   --------------------------------------------
   -- Get all properties as a Map Key/String --
   -- Input parameter is an AADL instance    --
   --------------------------------------------
   function Numeric_Term_As_String (Node : Node_Id) return String is
      function Signed_Number (Value, Unit : Node_Id) return String
      is
         Result : Unbounded_String;
      begin
         if ATN.Kind (Value) = K_Literal then
            --  aadlinteger or aadlreal
            Result := US (Ocarina.AADL_Values.Image (ATN.Value (Value)));
         else
            --  If this is ever needed, relevant code to adapt is in
            --   ocarina-be_aadl-properties-values.adb
            Result := US ("UNSUPPORTED CONSTANTS");
         end if;
         if Present (Unit) then
            Result := Result & US (Get_Name_String (ATN.Display_Name (Unit)));
         end if;
         return To_String (Result);
      end Signed_Number;
   begin
      return (case ATN.Kind (Node) is
         when K_Minus_Numeric_Term =>
            "-" & Numeric_Term_As_String (ATN.Numeric_Term (Node)),
         when K_Signed_AADLNumber =>
            Signed_Number (Number_Value (Node), Unit_Identifier (Node)),
         when K_Entity_Reference =>
             -- This comes from ocarina-be_aadl-identifiers.adb, function
             --  Print_Entity_Reference
             (if ATN.Namespace_Identifier (Node) /= No_Node
              then Get_Name_String
                  (ATN.Display_Name (ATN.Namespace_Identifier (Node))) & "::"
              else "")
              & Get_Name_String (ATN.Display_Name (Node)),
         when K_Property_Term                 |
           K_Unique_Property_Const_Identifier =>
             -- This comes from ocarina-be_aadl-identifiers.adb, function
             --  Print_Entity_Reference
             (if ATN.Property_Set_Identifier (Node) /= No_Node
              then Get_Name_String
                  (ATN.Display_Name (ATN.Property_Set_Identifier (Node)))
                   & "::"
              else "")
             & Get_Name_String (ATN.Display_Name (Node)),
         when others =>
            "ERROR WITH NUMERIC TERM");
   end Numeric_Term_As_String;

   function Record_As_String (Node : Node_Id) return String;
   function Property_Value_As_String (Single_Val : Node_Id;
                                      Array_Value : Node_Id := No_Node)
      return String
   is
      --  return the sting corresponding to a property value
   begin
      return (case ATN.Kind (Single_Val) is
          when ATN.K_Signed_AADLNumber =>
             Ocarina.AADL_Values.Image
                 (ATN.Value (ATN.Number_Value (single_val)))
                  & (if Present (ATN.Unit_Identifier (single_val))
                     then " "
                         & Get_Name_String
                             (ATN.Display_Name
                                 (ATN.Unit_Identifier (single_val)))
                        else ""),
          when ATN.K_Literal =>
             Ocarina.AADL_Values.Image
                        (ATN.Value (single_val),
                         Quoted => False),
          when ATN.K_Reference_Term =>
              Get_Name_String
                  (ATN.Display_Name (ATN.First_Node --  XXX must iterate
                      (ATN.List_Items (ATN.Reference_Term (single_val))))),
          when ATN.K_Enumeration_Term =>
              Get_Name_String
                  (ATN.Display_Name (ATN.Identifier (Single_Val))),
          when ATN.K_Number_Range_Term =>
              Numeric_Term_As_String (Lower_Bound (Single_Val))
              & ".."
              & Numeric_Term_As_String (Upper_Bound (Single_Val)),
          when ATN.K_Component_Classifier_Term =>
             --  When property is "classifier (...)" the following
             --  returns the name of the component (e.g. foo.other)
             (if Array_Value /= No_Node then
              Get_Name_String (AIN.Display_Name
                 (AIN.Identifier
                     (Get_Classifier_Of_Property_Value
                         (ATN.Expanded_Single_Value (Array_Value)))))
              else "UNSUPPORTED CLASSIFIER HERE"),
          when ATN.K_Record_Term =>
              Record_As_String (single_val),
          when others => "ERROR! Kazoo does not support Kind: "
                         & ATN.Kind (single_val)'Img);
   end Property_Value_As_String;

   function Record_As_String (Node : Node_Id) return String is
      --  Get the string of a complex record property
      --  We have to form this string as Ocarina does not have an API for that
      --  (the closest is found in ocarina-be_aadl-properties-values.adb but
      --  it only prints to screen)
      List_Node : Node_Id := ATN.First_Node (ATN.List_Items (Node));
      Result : Unbounded_String := US ("[ ");
   begin
      while Present (List_Node) loop
         if Kind (List_Node) = K_Record_Term_Element then
            Result := Result
            & US (Get_Name_String
                (ATN.Display_Name (ATN.Identifier (List_Node))))
            & " => "
            & Property_Value_As_String (Property_Expression (List_Node));
         else
            Result := Result & "ERROR - UNIDENTIFIED RECORD FIELD";
         end if;
         Result := Result & "; ";
         List_Node := ATN.Next_Node (List_Node);
      end loop;
      return To_String (Result & " ]");
   end Record_As_String;

   function Get_Properties_Map (D : Node_Id) return Property_Maps.Map is
      Properties : constant List_Id  := AIN.Properties (D);
      Result     : Property_Maps.Map := Property_Maps.Empty_Map;
      Property   : Node_Id;
      Prop_Value,
      Single_Val : Node_Id;
   begin
      if not Present (Properties) then
         return Result;
      end if;
      Property := AIN.First_Node (Properties);
      while Present (Property) loop
         Prop_Value := AIN.Property_Association_Value (property);
         Single_Val := ATN.Single_Value (Prop_Value);
         if Present (ATN.Single_Value (prop_value)) then
            Result.Insert
              (Key      => AIN_Case (property),
               New_Item =>
                 (Name => US (AIN_Case (property)),
                  Value => US (Property_Value_As_String
                                 (Single_Val, Prop_Value))));
         end if;
         Property := AIN.Next_Node (Property);
      end loop;
      return Result;
   end Get_Properties_Map;

   --  Initialization step: we look for ocarina on path to define
   --  OCARINA_PATH env. variable. This will indicate Ocarina librrary
   --  where to find AADL default property sets, and Ocarina specific
   --  packages and property sets.
   procedure Initialize_Ocarina is
      S : constant GNAT.OS_Lib.String_Access :=
        GNAT.OS_Lib.Locate_Exec_On_Path ("ocarina");
   begin
      if S = null then
         raise AADL_Parser_Error with "Ocarina is not in your PATH";
      end if;
      GNAT.OS_Lib.Setenv ("OCARINA_PATH", S.all (S'First .. S'Last - 12));
      Ocarina.Initialize;
      Ocarina.AADL_Version := Ocarina.AADL_V2;
      Ocarina.Configuration.Init_Modules;
      --  Following is needed to parse the interface view
      Ocarina.FE_AADL.Parser.Add_Pre_Prop_Sets := False;
   end Initialize_Ocarina;

   --  There is no "&" operator for Translate sets...
   function Join_Sets (S1, S2 : Translate_Set) return Translate_Set is
      Result : Translate_Set := S1;
   begin
      Insert (Result, S2);
      return Result;
   end Join_Sets;
begin
   Register_Filter ("UNIQ", Filter_Uniq'Access);
   Register_Filter ("FIRST_ELEM", Filter_First_Elem'Access);
end TASTE.Parser_Utils;
