--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  **********************************************************************  --
with Text_IO; use Text_IO;
with Ada.Characters.Latin_1,
     Ada.Characters.Handling,
     Ada.Containers.Ordered_Sets,
     Ada.Exceptions,
     Ada.Directories,
     GNAT.Directory_Operations,  --  for Dir_Nme
     TASTE.Parser_Utils,
     TASTE.Deployment_View;

use Ada.Characters.Handling,
    Ada.Containers,
    Ada.Exceptions,
    Ada.Directories,
    GNAT.Directory_Operations,
    TASTE.Parser_Utils,
    TASTE.Deployment_View;

--  This package covers the generation of code for all supported languages
--  There is no code that is specific to one particular language. The package
--  looks for a sub-directory with the name of the language and checks that all
--  skeleton-related template files are present. Then it fills the Template
--  mappings and generate the corresponding code.

package body TASTE.Backend.Code_Generators is

   Newline : Character renames Ada.Characters.Latin_1.LF;
   package Sort_Set is new Ordered_Sets (Unbounded_String);

   procedure Generate (Model : TASTE_Model) is
      Set_of_CP        : Sort_Set.Set;
      All_CP_Files     : Tag;  --  List of Context Parameters ASN.1 files
      Template         : constant IV_As_Template :=
                                Interface_View_Template (Model.Interface_View);
      DV : constant Deployment_View_Holder :=
          Model.Deployment_View;
      --  Path to the input templates files
      Prefix           : constant String :=
        Model.Configuration.Binary_Path.Element & "/templates/";

      Prefix_Skeletons  : constant String := Prefix & "skeletons/";
      Prefix_Wrappers   : constant String := Prefix & "glue/language_wrappers";

      --  Helper function: find the CPU Plaform where a function is bound
      --  This is useful to have it in some wrapper backends (glue code)
      --  as well as in the Makefile.
      function Get_CPU_Platform (F : Taste_Terminal_Function) return String is
      begin
         for Each_Node of DV.Element.Nodes loop
            for Each_Partition of Each_Node.Partitions loop
               if Each_Partition.Bound_Functions.Contains (To_String (F.Name))
               then
                  return Each_Node.CPU_Platform'Img;
               end if;
            end loop;
         end loop;
         return "CPU_Platform_NOT_FOUND_For_Function_" & To_String (F.name);
      end Get_CPU_Platform;

      --  Generate a global Makefile (processing all functions)
      --  and a global project file (.pro) for Space Creator
      procedure Generate_Global_Makefile is
         package Languages_Set is new Ordered_Sets (Unbounded_String);
         use Languages_Set;
         Output_File      : File_Type;
         Languages        : Languages_Set.Set;
         Unique_Languages : Tag;
         Functions_Tag,
         Language_Tag,
         Has_Context_Param_Tag,
         Is_Type_Tag,
         Is_Shared_Type_Tag,
         Instance_Of_Tag,
         Is_FPGA_Tag,
         CPU_Platform_Tag : Vector_Tag;
         Content_Set      : Translate_Set;
         Tmplt1           : constant String := Prefix_Skeletons
                                               & "makefile.tmplt";
         Tmplt2           : constant String := Prefix_Skeletons
                                               & "project_file.tmplt";
      begin
         if not Exists (Tmplt1) or not Exists (Tmplt2) then
            raise ACG_Error with "Missing " & Tmplt1 & " or " & Tmplt2;
         end if;
         for Each of Model.Interface_View.Flat_Functions loop
            Languages := Languages or To_Set (US (Language_Spelling (Each)));
            Functions_Tag   := Functions_Tag & Each.Name;
            Language_Tag    := Language_Tag & Language_Spelling (Each);
            Is_Type_Tag     := Is_Type_Tag & Each.Is_Type;
            Instance_Of_Tag := Instance_Of_Tag & Each.Instance_Of;
            Has_Context_Param_Tag := Has_Context_Param_Tag
              & (not Each.Context_Params.Is_Empty);
            --  Determine if the function type is in the shared folder
            Is_Shared_Type_Tag := Is_Shared_Type_Tag
              & (Each.Instance_Of /= "" and then not
                  Model.Interface_View.Flat_Functions.Contains
                      (To_String (Each.Instance_Of)));

            if Each.User_Properties.Contains
                ("TASTE_IV_Properties::FPGA_Configurations")
            then
               Is_FPGA_Tag := Is_FPGA_Tag & True;
            else
               Is_FPGA_Tag := Is_FPGA_Tag & False;
            end if;

            if not DV.Is_Empty then
               CPU_Platform_Tag := CPU_Platform_Tag & Get_CPU_Platform (Each);
            end if;
         end loop;
         for Each of Languages loop
            Unique_Languages := Unique_Languages & To_String (Each);
         end loop;
         Content_Set := Model.Configuration.To_Template
           & Assoc ("Function_Names",    Functions_Tag)
           & Assoc ("Language",          Language_Tag)
           & Assoc ("Is_Type",           Is_Type_Tag)
           & Assoc ("Is_Shared_Type",    Is_Shared_Type_Tag)
           & Assoc ("Instance_Of",       Instance_Of_Tag)
           & Assoc ("CP_Files",          All_CP_Files)
           & Assoc ("Has_Context_Param", Has_Context_Param_Tag)
           & Assoc ("Is_FPGA",           Is_FPGA_Tag)
           & Assoc ("CPU_Platform",      CPU_Platform_Tag)
           & Assoc ("Unique_Languages",  Unique_Languages)
           & Assoc ("ASN1_Files",        Model.Data_View.Get_ASN1_File_List)
           & Assoc ("ACN_Files",         Model.Data_View.Get_ACN_File_List)
           & Assoc ("ASN1_Modules",      Model.Data_View.Get_Module_List);

         Put_Debug ("Generating global Makefile");
         Create (File => Output_File,
                 Mode => Out_File,
                 Name => Model.Configuration.Output_Dir.Element & "/Makefile");
         Document_Template (Templates_Skeletons_Makefile, Content_Set);
         Put_Line (Output_File, Parse (Tmplt1, Content_Set));
         Close (Output_File);
         Put_Debug ("Generating global project file");
         Create (File => Output_File,
                 Mode => Out_File,
                 Name => Model.Configuration.Output_Dir.Element
                         & "/taste.pro");
         Put_Line (Output_File, Parse (Tmplt2, Content_Set));
         Close (Output_File);
      end Generate_Global_Makefile;

      --  Render a set of interfaces by applying a template
      --  Result is an unbounded string, allowing each interface to use
      --  multiple lines (combined with 'Indent)
      --  Optionally contains a CPU_Platform argument, added to the template
      --  in case a deployment view is present (e.g. for glue code generation)
      function Process_Interfaces (Interfaces : Template_Vectors.Vector;
                                   Template   : String;
                                   Path       : String;
                                   CPU_Platform : String := "")
      return Unbounded_String
      is
         Result      : Unbounded_String := Null_Unbounded_String;
         Tmplt_Sign  : constant String := Path & Template;
         Doc_Done    : Boolean := False;
      begin
         for Each of Interfaces loop
            declare
               Tmplt :  constant Translate_Set :=
                  Join_Sets (Model.Configuration.To_Template, Each)
                  & Assoc ("CPU_Platform", CPU_Platform);
            begin
               if Exists (Tmplt_Sign) then
                  if not Doc_Done then
                     --  Template documentation (done once)
                     Document_Template (Templates_Skeletons_Sub_Interface,
                     Tmplt);
                     Doc_Done := True;
                  end if;
                  Result := Result & US (String'(Parse (Tmplt_Sign, Tmplt)))
                  & Newline & Newline;
               end if;
            end;
         end loop;
         return Strip_String (Result);
      end Process_Interfaces;

      --  Generate the ASN.1 files translating Context Parameters
      procedure Process_Context_Parameters
                               (F           : Taste_Terminal_Function;
                                Output_Lang : String)
      is
         Output_File : File_Type;
         CP_Tmpl     : constant Translate_Set := CP_Template (F => F);
         CP_Text     : constant String :=
            (Parse (Prefix_Skeletons & "context_parameters.tmplt", CP_Tmpl));
         CP_File     : constant String :=
           "Context-" & To_Lower (To_String (F.Name)) & ".asn";
         CP_File_Dash : Unbounded_String;

      begin
         Document_Template (Templates_Skeletons_Context_Parameters, CP_Tmpl);
         --  To keep backward compatibility, file name uses dash
         for C of CP_File loop
            CP_File_Dash := CP_File_Dash & (if C = '_' then '-' else C);
         end loop;

         if not F.Context_Params.Is_Empty then
            Create_Path (Output_Lang);
            Put_Debug ("Generating " & To_String (CP_File_Dash));
            Create (File => Output_File,
                    Mode => Out_File,
                    Name => Output_Lang & To_String (CP_File_Dash));
            Put_Line (Output_File, CP_Text);
            Close (Output_File);
            declare
               CP_To_Add : constant String :=
                   "../" & Output_Lang & To_String (CP_File_Dash);
            begin
               if not Set_of_CP.Contains (US (CP_To_Add)) then
                  Set_of_CP.Insert (US (CP_To_Add));
                  All_CP_Files :=  All_CP_Files & CP_To_Add;
               end if;
            end;
            --  If the function is an instance of a function that is in the
            --  library of shared types, we must add its CP here, using the
            --  path to the installed library (known from Model.Configuration)
            if F.Instance_Of /= ""
              and then not Model.Interface_View.Flat_Functions.Contains
                (To_String (F.Instance_Of))
            then
               declare
                  Parent      : constant String := To_String (F.Instance_Of);
                  Parent_Dash : Unbounded_String;
               begin
                  for C of Parent loop
                     Parent_Dash := Parent_Dash & (if C = '_'
                                                   then '-'
                                                   else C);
                  end loop;
                  declare
                     CP_To_Add : constant String :=
                        "$(TASTE_SHARED_TYPES)/" & Parent & "/work/"
                        & To_Lower (Parent) & "/" & Language_Spelling (F)
                        & "/" & "Context-"
                        & To_Lower (To_String (Parent_Dash))
                        & ".asn";
                  begin
                     --  Ensure the CP are not duplicated
                     if not Set_of_CP.Contains (US (CP_To_Add)) then
                        Set_of_CP.Insert (US (CP_To_Add));
                        All_CP_Files :=  All_CP_Files & CP_To_Add;
                     end if;
                  end;
               end;
            end if;
         end if;
      exception
         when E : End_Error
         | Text_IO.Use_Error =>
            if Is_Open (Output_File) then
               Close (Output_File);
            end if;
            raise ACG_Error with "Generation of code for function "
                                 & To_String (F.Name) & " failed : "
                                 & Exception_Message (E);
      end Process_Context_Parameters;

      --  Write a header or body file for a function, a corresponding
      --  Makefile, and/or context parameters
      procedure Process_Template (F           : Taste_Terminal_Function;
                                  File_Name   : String := "";
                                  Make_File   : String := "";
                                  Path        : String;
                                  Output_Lang : String;
                                  Output_Sub  : String := "src/") is
         Output_File : File_Type;

         --  some Makefiles may need the list of PIs (e.g. Qgen)
         function List_Of_PIs return Tag is
            Result : Tag;
         begin
            for PI of F.Provided loop
               Result := Result & PI.Name;
            end loop;
            return Result;
         end List_Of_PIs;

         Make_Tmpl   : constant Translate_Set :=
           Join_Sets (Model.Configuration.To_Template,
                      Function_Makefile_Template
                         (Model   => Model,
                          F       => F,
                          Modules => Model.Data_View.Get_Module_List,
                          Files   => Model.Data_View.Get_ASN1_File_List))
           & Assoc ("List_Of_PIs", List_Of_PIs);

         Make_Path   : constant String := Path & "makefile.tmplt";
         Make_Text   : constant String :=
            (if Make_File /= "" and then Exists (Make_Path)
             then Parse (Make_Path, Make_Tmpl) else "");

         Func_Tmpl   : constant Func_As_Template :=
                                Template.Funcs.Element (To_String (F.Name));

         CPU_Platform : constant String :=
            (if not DV.Is_Empty then Get_CPU_Platform (F) else "");

         Func_Map    : constant Translate_Set :=
                         Join_Sets (Model.Configuration.To_Template,
                                    Func_Tmpl.Header)
                         & Assoc ("Provided_Interfaces",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "interface.tmplt", Path, CPU_Platform))
                         & Assoc ("Required_Interfaces",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "interface.tmplt", Path, CPU_Platform))
                         & Assoc ("Send_Events",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "send_events.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Event_Filters",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "event_filters.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Send_Messages_Init",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "send_messages_init.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Send_Messages_Init_Call",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "send_messages_init_call.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Send_Messages_Functions",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "send_messages_functions.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Receive_Messages_Init",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "send_messages_init.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Receive_Messages_Init_Call",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "send_messages_init_call.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Receive_Messages_Process",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "receive_messages_process.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Receive_Messages_Functions",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "send_messages_functions.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("Component_Management_Functions",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "component_management_functions.tmplt",
                                     Path,
                                     CPU_Platform))
                         & Assoc ("Component_Management_Init",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "component_management_init.tmplt",
                                     Path,
                                     CPU_Platform))
                         & Assoc ("QGen_Wrapper_Req",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "qgen_wrapper.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("QGen_Wrapper_Pro",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "qgen_wrapper.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("QGen_Wrapper_Params_Req",
                                  Process_Interfaces
                                     (Func_Tmpl.Required,
                                     "qgen_wrapper_params.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("QGen_Wrapper_Params_Pro",
                                  Process_Interfaces
                                     (Func_Tmpl.Provided,
                                     "qgen_wrapper_params.tmplt", Path,
                                     CPU_Platform))
                         & Assoc ("CPU_Platform", CPU_Platform)
                         & Assoc ("ASN1_Files",
                                  Model.Data_View.Get_ASN1_File_List);

         Content     : constant String :=
                                    Parse (Path & "function.tmplt", Func_Map);

         Output_Dir  : constant String := Output_Lang & Output_Sub;
      begin
         Document_Template (Templates_Skeletons_Sub_Function, Func_Map);
         Document_Template (Templates_Skeletons_Sub_Makefile, Make_Tmpl);
         --  Create directory tree (output/function/language/src)
         Create_Path (Output_Dir);
         if File_Name /= "" then
            Put_Debug ("Generating " & Output_Dir & File_Name);
            Create (File => Output_File,
                    Mode => Out_File,
                    Name => Output_Dir & File_Name);
            Put_Line (Output_File, Content);
            Close (Output_File);
         end if;
         if Make_File /= "" then
            Put_Debug ("Generating " & Make_File & " for function "
                      & To_String (F.Name));
            Create (File => Output_File,
                    Mode => Out_File,
                    Name => Output_Lang & Make_File);
            Put_Line (Output_File, Make_Text);
            Close (Output_File);
         end if;
      exception
         when E : End_Error
         | Text_IO.Use_Error =>
            if Is_Open (Output_File) then
               Close (Output_File);
            end if;
            raise ACG_Error with "Generation of code for function "
                                 & To_String (F.Name) & " failed : "
                                 & Exception_Message (E);
      end Process_Template;

      --  Main loop generating output for each function
      --  Prefix is where the templates are located
      --  Output_Base is the output folder defined in the command line
      --  Output_Sub is where the code shall be generated (e.g. "src")
      procedure Generate_From_Templates (Prefix      : String;
                                         Output_Base : String;
                                         Output_Sub  : String := "src/") is
      begin
         Put_Debug ("== Generate code with templates from " & Prefix & " ==");
         for Each of Model.Interface_View.Flat_Functions loop
            --  There can be multiple folders containing templates, iterate
            declare
               Language   : constant String := Language_Spelling (Each);
               ST         : Search_Type;
               Current    : Directory_Entry_Type;
               Filter     : constant Filter_Type := (Directory => True,
                                                     others    => False);
               --  File_Tmpl: to get the output filename from user template
               File_Tmpl  : constant Translate_Set :=
                  Model.Configuration.To_Template
                  & Assoc  ("Name", Each.Name)
                  & Assoc ("Language", Language);
               --  Base output folder where code is generated
               --  e.g. output/Ada/src/
               Output_Lang : constant String := Output_Base
                  & To_Lower (To_String (Each.Name))
                  & "/" & Language & "/";
               Output_Dir  : constant String := Output_Lang & Output_Sub;
            begin
               Start_Search (Search    => ST,
                             Pattern   => "",
                             Directory => Prefix,
                             Filter    => Filter);

               if not More_Entries (ST) then
                  Put_Error ("No folders with templates were found");
               end if;

               --  Iterate over the folders and process templates. Each folder
               --  shall contain a template named "trigger.tmplt" allowing
               --  the engine to decide if code should be generated or not
               --  based on user-defined critera (e.g. language)
               while More_Entries (ST) loop
                  Get_Next_Entry (ST, Current);
                  declare
                     --  Path is where the template files are located
                     Path      : constant String := Full_Name (Current);

                     --  Do_Func is true if there is a template for the
                     --  generation of a function template
                     Do_Func   : constant Boolean :=
                        Exists (Path & "/function-filename.tmplt");

                     --  Do_Make is true if there is a template for the
                     --  generation of a build script/Makefile template
                     Do_Make   : constant Boolean :=
                        Exists (Path & "/makefile-filename.tmplt");

                     --  File_Name is the output file to generate,
                     --  as parsed from the template file
                     File_Name : constant String :=
                        (if Do_Func
                         then
                            Strip_String (Parse
                               (Path & "/function-filename.tmplt", File_Tmpl))
                         else "");

                     --  User can define the name of the build script
                     --  to generate (typically, for a function, "Makefile")
                     Make_Name : constant String :=
                        (if Do_Make
                         then
                            Strip_String (Parse
                               (Path & "/makefile-filename.tmplt", File_Tmpl))
                         else "");

                     --  Present_F is True if the function file already exists
                     Present_F : constant Boolean :=
                        (File_Name /= "" and Exists (Output_Dir & File_Name));

                     --  Present_M is True if the Makefile already exists
                     Present_M : constant Boolean :=
                        (Make_Name /= "" and Exists (Output_Dir & Make_Name));

                     --  Data needed to process trigger.tmplt
                     --  Includes function attributes (name, zip file, etc)
                     --  and the command line configuration (Use_POHIC, etc.)
                     Trig_Tmpl  : constant Translate_Set :=
                       Join_Sets (Model.Configuration.To_Template,
                                  Template.Funcs.Element
                                    (To_String (Each.Name)).Header)
                       & Assoc ("Filename_Is_Present", Present_F)
                       & Assoc ("Makefile_Is_Present", Present_M);

                     --  Trigger is set to True by the template
                     Trigger    : constant Boolean :=
                        (Exists (Path & "/trigger.tmplt")
                         and then Strip_String (Parse
                           (Path & "/trigger.tmplt", Trig_Tmpl)) =
                           String'("TRUE"));
                  begin
                     Document_Template
                       (Templates_Skeletons_Sub_Function_Filename, File_Tmpl);
                     Document_Template
                       (Templates_Skeletons_Sub_Makefile_Filename, File_Tmpl);
                     Document_Template
                       (Templates_Skeletons_Sub_Trigger, Trig_Tmpl);
                     if Trigger then
                        --  Possibly create folder to generate the file
                        if File_Name /= "" then
                           Create_Path (Output_Dir & Dir_Separator
                                        & Dir_Name (File_Name));
                        end if;
                        --  Output code and Makefile from this template folder
                        Process_Template (F           => Each,
                                          File_Name   => File_Name,
                                          Make_File   => Make_Name,
                                          Path        => Path & "/",
                                          Output_Lang => Output_Lang,
                                          Output_Sub  => Output_Sub);
                     end if;
                  end;
               end loop;
               End_Search (ST);
               Process_Context_Parameters (F           => Each,
                                           Output_Lang => Output_Lang);
            end;
         end loop;
      end Generate_From_Templates;

   begin
      Generate_From_Templates (Prefix      => Prefix_Skeletons,
                               Output_Base =>
                                  Model.Configuration.Output_Dir.Element & "/",
                               Output_Sub  => "src/");
      Generate_Global_Makefile;
      if Model.Configuration.Glue then
         Generate_From_Templates (Prefix     => Prefix_Wrappers,
                                  Output_Base =>
                                    Model.Configuration.Output_Dir.Element
                                       & "/",
                                  Output_Sub => "wrappers/");
      end if;
   end Generate;

   --  Functions that transform the AST into Templates:
   --  * Context Parameters
   --  * Makefile (per function)
   --  * A single interface
   --  * A single taste function
   --  * The complete interface view

   --  Context Parameters
   function CP_Template (F : Taste_Terminal_Function) return Translate_Set is
      use Sort_Set;
      Sorts_Set    : Set;
      Unique_Sorts : Vector_Tag;
      Corr_Module  : Vector_Tag;
      Names        : Vector_Tag;
      Sorts        : Vector_Tag;
      ASN1_Modules : Vector_Tag;
      Values       : Vector_Tag;
   begin
      for Each of F.Context_Params loop
         if not Sorts_Set.Contains (Each.Sort) then
            --  Build up a set of unique types, needed for the IMPORTS section
            --  in the ASN.1 module
            Sorts_Set.Insert (Each.Sort);
            Unique_Sorts := Unique_Sorts & Each.Sort;
            Corr_Module  := Corr_Module & Each.ASN1_Module;
         end if;
         Names        := Names        & Each.Name;
         Sorts        := Sorts        & Each.Sort;
         ASN1_Modules := ASN1_Modules & Each.ASN1_Module;
         Values       := Values       & Each.Default_Value;
      end loop;
      return Result : constant Translate_Set :=
        +Assoc ("Name",            F.Name)
        & Assoc ("Is_Type",        F.Is_Type)
        & Assoc ("Instance_Of",    F.Instance_Of)
        & Assoc ("Sort_Set",       Unique_Sorts)
        & Assoc ("Module_Set",     Corr_Module)
        & Assoc ("CP_Name",        Names)
        & Assoc ("CP_Sort",        Sorts)
        & Assoc ("CP_ASN1_Module", ASN1_Modules)
        & Assoc ("CP_Value",       Values);
   end CP_Template;

   --  A Makefile can be generated for each function
   --  with a rule to edit the function using an IDE, model editor, etc.
   --  (this is defined in the template)
   function Function_Makefile_Template (Model   : TASTE_Model;
                                        F       : Taste_Terminal_Function;
                                        Modules : Tag;
                                        Files   : Tag) return Translate_Set
   is (Translate_Set'(Properties_To_Template (F.User_Properties)
                      & Assoc ("Name",           F.Name)
                      & Assoc ("ASN1_Files",     Files)
                      & Assoc ("ASN1_Modules",   Modules)
                      & Assoc ("Language",       Language_Spelling (F))
                      & Assoc ("Has_CP",         not F.Context_Params.Is_Empty)
                      & Assoc ("Is_Type",        F.Is_Type)
                      & Assoc ("Shared_Lib_Dir",
                               Model.Configuration.Shared_Lib_Dir)
                      & Assoc ("Is_Shared_Type",
                               F.Instance_Of /= "" and then not
                                 Model.Interface_View.Flat_Functions.Contains
                                   (To_String (F.Instance_Of)))
                      & Assoc ("Instance_Of", F.Instance_Of)));

   function Interface_View_Template (IV : Complete_Interface_View)
                                     return IV_As_Template is
      Result : IV_As_Template;
   begin
      for Each of IV.Flat_Functions loop
         Result.Funcs.Insert (Key      => To_String (Each.Name),
                              New_Item => Each.Function_To_Template);
      end loop;
      for C of IV.Connections loop
         Result.Callers  := Result.Callers  & C.Caller;
         Result.Callees  := Result.Callees  & C.Callee;
         Result.RI_Names := Result.RI_Names & C.RI_Name;
         Result.PI_Names := Result.PI_Names & C.PI_Name;
      end loop;
      return Result;
   end Interface_View_Template;

end TASTE.Backend.Code_Generators;
