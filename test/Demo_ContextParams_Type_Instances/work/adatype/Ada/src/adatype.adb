with Text_IO; use Text_IO;

package body Adatype is

   procedure Pulse (Self : in out Context) is
   begin
      Put_Line("Ada value: " & Self.foo'Img);
   end Pulse;

end Adatype;
