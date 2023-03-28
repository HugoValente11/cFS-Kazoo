--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

with Ada.Strings.Unbounded,
     Ocarina.Types,
     TASTE.Parser_Utils,
     TASTE.Interface_View,
     TASTE.Deployment_View,
     TASTE.Concurrency_View,
     TASTE.Data_View;

use Ada.Strings.Unbounded,
    Ocarina.Types,
    TASTE.Parser_Utils,
    TASTE.Interface_View,
    TASTE.Deployment_View,
    TASTE.Concurrency_View,
    TASTE.Data_View;

package TASTE.AADL_Parser is
   Interface_Root,
   Deployment_Root,
   Dataview_Root : Node_Id := No_Node;

   --  ConcurrencyView_Properties.aadl is parsed but not analyzed,
   --  as it contains reference to the system threads which have not
   --  been created yet. The backend templates get access to the values.
   Concurrency_Properties_Root : Node_Id := No_Node;

   --  Definition of the data model of a TASTE system
   type TASTE_Model is tagged
      record
         Interface_View   : Complete_Interface_View;
         Deployment_View  : aliased Deployment_View_Holder;
         Data_View        : aliased Taste_Data_View;
         Concurrency_View : Taste_Concurrency_View;
         Configuration    : Taste_Configuration;
      end record;

   function Parse_Project return TASTE_Model;

   --  Transform: add Poll cyclic in GUIs, manage timers and taste api
   --  This function can be called if there is a deployment view
   procedure Preprocessing (Model : in out TASTE_Model)
     with Pre => not Model.Deployment_View.Is_Empty;

   --  Create the concurrency view and apply the templates for code generation
   procedure Add_Concurrency_View (Model : in out TASTE_Model)
     with Pre => not Model.Deployment_View.Is_Empty;

   --  Parse the ConcurrencyView_Properties.aadl file to extract user-defined
   --  thread priorities, dispatch offset, stack sizes. Parsing is done at
   --  AST level only, the model is not semantically checked because at this
   --  point in the parsing the actual set of thread has not been computed,
   --  so the AADL file references non-existing artefacts. There can be
   --  reference to threads that will not be created at all, in which case
   --  they can be ignored or reported to the user for information.
   --  NOTE: with Space Creator this is actually deprecated, as these
   --  properties are now part of the interface view directly.
   procedure Add_CV_Properties (Model : in out TASTE_Model);

   function Find_Binding (Model : TASTE_Model;
                          F     : Unbounded_String)
                          return Partition_Holder;

   --  Copy a function and bind it to the same partition as the original
   --  This is used to support multiple instances of a function type.
   --  Each instance is a duplicate of the user-defined instance, but with
   --  a different name.
   procedure Duplicate_Function (Model           : in out TASTE_Model;
                                 From            : String;
                                 Instance_Number : Integer);

   --  Rename a function: useful after duplicating to rename the original
   --  function with an index suffix.
   procedure Rename_Function (Model    : in out TASTE_Model;
                              From, To : String);

   procedure Dump                  (Model : TASTE_Model);
   procedure Generate_Code         (Model : TASTE_Model);

   --  Process Templates from the templates/concurrency_view subfolder
   procedure Generate_Concurrency_View (Model : TASTE_Model);

private
   procedure Build_TASTE_AST (Model : out TASTE_Model);
   procedure Find_Shared_Libraries (Model : out TASTE_Model);
end TASTE.AADL_Parser;
