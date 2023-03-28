--  ******************************* KAZOO  *******************************  --
--  (c) 2017-2021 European Space Agency - maxime.perrotin@esa.int
--  See LICENSE file
--  *********************************************************************** --
with --  TASTE.Interface_View,
     TASTE.AADL_Parser;

use -- TASTE.Interface_View,
    TASTE.AADL_Parser;

package TASTE.Semantic_Check is
   procedure Check_Model (Model : TASTE_Model);
   Semantic_Error : exception;

end TASTE.Semantic_Check;
