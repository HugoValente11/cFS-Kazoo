--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

--  Interface View parser

with Ada.Directories,
     GNAT.Directory_Operations,
     Ocarina.Instances.Queries,
     Ocarina.Analyzer,
     Ocarina.Backends.Properties,
     Ocarina.Options,
     Ocarina.Instances,
     Ocarina.ME_AADL.AADL_Instances.Nodes,
     Ocarina.Namet,
     Ocarina.ME_AADL.AADL_Instances.Entities;

package body TASTE.Data_View is

   use GNAT.Directory_Operations,
       Ocarina.Instances.Queries,
       Ocarina.Namet,
       Ocarina.Backends.Properties,
       Ocarina.Options,
       Ocarina.Instances,
       Ocarina.ME_AADL.AADL_Instances.Nodes,
       Ocarina.ME_AADL.AADL_Instances.Entities,
       Ocarina.ME_AADL;

   ----------------------------
   --  AST Builder Functions --
   ----------------------------

   function Parse_Data_View (Dataview_Root : Node_Id) return Taste_Data_View
   is
      use ASN1_File_Maps;
      System            : Node_Id;
      Files             : ASN1_File_Maps.Map;
      ACN_Files         : String_Sets.Set;
      Current_Type      : Node_Id;
   begin
      if not Ocarina.Analyzer.Analyze (AADL_Language, Dataview_Root) then
         raise Data_View_Error with "Could not analyse Data View";
      end if;

      Ocarina.Options.Root_System_Name :=
        Get_String_Name ("taste_dataview.others");

      if Dataview_Root /= No_Node then
         declare
            Inst : constant Node_Id :=
              Instantiate_Model (Root          => Dataview_Root,
                                 Exit_If_Error => False);
         begin
            if Inst /= No_Node then
               System := Root_System
                 (Instantiate_Model (Root => Dataview_Root));
            else
               System := No_Node;
            end if;
         end;
      end if;

      if No (System) then
         raise Data_View_Error with
           "Could not instantiate Data View - Try taste-update-data-view";
      end if;

      Current_Type := AIN.First_Node (AIN.Subcomponents (System));
      while Present (Current_Type) loop
         if Get_Category_Of_Component (Current_Type) /= CC_Data then
            raise Data_View_Error with "Component is not a data type!";
         end if;
         declare
            Asntype  : constant Node_Id :=
              Corresponding_Instance (Current_Type);
            Sort     : constant String  := Get_Name_String
                             (Get_Type_Source_Name (Asntype));
            Module   : constant String  := Get_Name_String
              (Get_String_Property (Asntype,
               Get_String_Name ("taste::ada_package_name")));
            ACN_Ref  : constant Node_Id := Get_Classifier_Property
              (Asntype, "taste::encodingdefinitionfile");
            Raw_Name : constant String  := Get_Name_String
              (Get_Source_Text (Asntype) (1));
            Filename : constant String :=
              (if Base_Name (Raw_Name) = "taste-types.asn"
               then "taste-types.asn" else Raw_Name);
            File_Ref : constant ASN1_File_Maps.Cursor := Files.Find (Filename);
         begin
            --  If there are ACN files, add them to the list
            --  Transform absolute paths to relative paths
            if ACN_Ref /= No_Node then
               declare
                  ACN : constant Name_Array := Get_Source_Text (ACN_Ref);
                  use String_Sets;
               begin
                  for F of ACN loop
                     declare
                        ACN_F    : constant String := Get_Name_String (F);
                        Rel_Path : constant String :=
                           (if ACN_F (ACN_F'First) /= '/'
                            then "../" & ACN_F
                            else ACN_F);
                     begin
                        ACN_Files.Union (To_Set (Rel_Path));
                     end;
                  end loop;
               end;
            end if;

            --  Transform absolute paths to ASN.1 files to relative paths
            if File_Ref = ASN1_File_Maps.No_Element then
               declare
                  New_File      : ASN1_File;
                  New_Module    : ASN1_Module;
                  Relative_Path : Unbounded_String := US (Filename);
               begin
                  New_Module.Name  := US (Module);
                  New_Module.Types := (Empty_Vector & Sort);
                  if Filename = "taste-types.asn" then
                     Relative_Path := US ("${TOOL_INST}"
                                      & "/share/taste-types/taste-types.asn");
                  elsif Filename (Filename'First) /= '/' then
                     Relative_Path := "../" & Relative_Path;
                  end if;
                  New_File.Path    := Relative_Path;
                  New_File.Modules.Insert (Module, New_Module);
                  Files.Insert (Filename, New_File);
               end;
            else
               declare
                  Curr_File   : ASN1_File := Files.Element (Filename);
                  Curr_Module : ASN1_Module;
               begin
                  if Curr_File.Modules.Contains (Module) then
                     Curr_Module := Curr_File.Modules.Element (Module);
                     Curr_Module.Types.Append (Sort);
                     Curr_File.Modules.Replace (Module, Curr_Module);
                  else
                     Curr_Module.Name := US (Module);
                     Curr_Module.Types := (Empty_Vector & Sort);
                     Curr_File.Modules.Insert (Module, Curr_Module);
                  end if;
                  Files.Replace (Filename, Curr_File);
               end;
            end if;
         end;
         Current_Type := AIN.Next_Node (Current_Type);
      end loop;
      return Data_AST : constant Taste_Data_View := (ASN1_Files => Files,
                                                     ACN_Files  => ACN_Files);
   end Parse_Data_View;

   --  Function checking the actual file presence of the ASN.1 models that
   --  are referenced in the input file DataView.aadl. Raise an exception
   --  if any file is missing.
   --  Ignore taste-types.asn, because it is provided by taste and its actual
   --  location depends on the current installation path (user name)
   procedure Check_Files (DV : Taste_Data_View) is
      Success : Boolean := True;
   begin
      for Idx in DV.ASN1_Files.Iterate loop
         --  The Key of the map contains the path as found in the dataview
         if not Ada.Directories.Exists (ASN1_File_Maps.Key (Idx))
             and ASN1_File_Maps.Key (Idx) /= "taste-types.asn"
         then
            Put_Error ("ASN.1 File not found: " & ASN1_File_Maps.Key (Idx));
            Success := False;
         elsif ASN1_File_Maps.Key (Idx) /= "taste-types.asn" then
            Put_Info ("Using ASN.1 File: " & ASN1_File_Maps.Key (Idx));
         end if;
      end loop;
      if not Success then
         raise Data_View_Error with
           "ASN.1 files missing (wrong path in DataView.aadl). "
           & "Run taste-update-data-view [list of ASN.1 files]";
      end if;
   end Check_Files;

   procedure Debug_Dump (DV : Taste_Data_View; Output : File_Type) is
   begin
      for Each of DV.ASN1_Files loop
         Put_Line (Output, "ASN.1 File : " & To_String (Each.Path));
         for Module of Each.Modules loop
            Put_Line (Output, "  |_Module : " &  To_String (Module.Name));
            for Sort of Module.Types loop
               Put_Line (Output, "    |_Type : " & Sort);
            end loop;
         end loop;
      end loop;
      for Each of DV.ACN_Files loop
         Put_Line (Output, "ACN File : " & Each);
      end loop;
   end Debug_Dump;

   function Get_Module_List (DV : Taste_Data_View) return Tag is
      Result : Tag;
   begin
      for Each of DV.ASN1_Files loop
         for Module of Each.Modules loop
            Result := Result & Module.Name;
         end loop;
      end loop;
      return Result;
   end Get_Module_List;

   function Get_ASN1_File_List (DV : Taste_Data_View) return Tag is
      Result : Tag;
   begin
      for Each of DV.ASN1_Files loop
         Result := Result & Each.Path;
      end loop;
      return Result;
   end Get_ASN1_File_List;

   function Get_ACN_File_List  (DV : Taste_Data_View) return Tag is
      Result : Tag;
   begin
      for Each of DV.ACN_Files loop
         Result := Result & Each;
      end loop;
      return Result;
   end Get_ACN_File_List;

   procedure Export_ASN1_Files (DV : Taste_Data_View; Output_Path : String) is
   begin
      for Idx in DV.ASN1_Files.Iterate loop
         if ASN1_File_Maps.Key (Idx) /= "taste-types.asn" then
            Ada.Directories.Copy_File
              (Source_Name => ASN1_File_Maps.Key (Idx),
               Target_Name => Output_Path
               & Ada.Directories.Simple_Name (ASN1_File_Maps.Key (Idx)));
         end if;
      end loop;
   end Export_ASN1_Files;
end TASTE.Data_View;
