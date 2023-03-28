--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2022 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --

with TASTE.AADL_Parser;
use  TASTE.AADL_Parser;

package TASTE.Dump is

   Dump_Error : exception;

   --  Dump input files (interface, data, deployment)
   --  using by default the templates in the templates/dump/* subfolders
   procedure Dump_Input_Model
       (Model  : TASTE_Model;
        Prefix : String);

end TASTE.Dump;
