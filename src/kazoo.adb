--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2022 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

with Ada.Exceptions,
     GNAT.OS_Lib,
     GNAT.Traceback.Symbolic,
     TASTE,
     TASTE.AADL_Parser,
     TASTE.Parser_Utils,
     TASTE.Dump;
use TASTE.AADL_Parser,
    TASTE.Parser_Utils;

procedure Kazoo is
begin
   declare
      Model : TASTE_Model := Parse_Project;
   begin
      --  Call Template-based dump backends (convert to xml, graphviz...)
      TASTE.Dump.Dump_Input_Model (Model,
           Model.Configuration.Binary_Path.Element & "templates/dump");

      if Model.Configuration.Debug_Flag then
         --  Dump not based on templates (deprecated)
         Model.Dump;
      end if;

      if Model.Configuration.Glue then
         Model.Preprocessing;
         Model.Add_Concurrency_View;
         Model.Add_CV_Properties;
         Model.Generate_Concurrency_View;
      end if;

      --  Call template-based dump backends after preprocessing
      --  (some functions may have been created)
      TASTE.Dump.Dump_Input_Model (Model,
          Model.Configuration.Binary_Path.Element & "templates/dump_post");

      Model.Generate_Code;

      if Model.Configuration.Generate_Doc then
         Dump_Documentation
           (Output_Folder =>
              Model.Configuration.Output_Dir.Element & "/Dump/Doc");
      end if;
   end;
exception
   when TASTE.Quit_TASTE =>
      GNAT.OS_Lib.OS_Exit (1);
   when Error : others =>
      Put_Error ("Ending application because of the following error:");
      Put_Error (Ada.Exceptions.Exception_Message (Error));
      Put_Debug (Ada.Exceptions.Exception_Information (Error));
      Put_Debug ("Symbolic Traceback (use gdb for better output): "
                 & GNAT.Traceback.Symbolic.Symbolic_Traceback (Error));
      GNAT.OS_Lib.OS_Exit (1);
end Kazoo;
