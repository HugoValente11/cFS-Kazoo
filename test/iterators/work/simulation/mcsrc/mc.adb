with Text_IO; use Text_IO;

with Simulator_Interface;

with Properties; -- user-defined properties

procedure MC is
    use Properties;

    package Simulator_Pkg is new Simulator_Interface
        (State_With_Observers => State_With_Observers,
         Application_State    => Application_State,
         Update_State         => Update_State,
         Full_State_Init      => Full_State_Init,
         State_As_String      => State_To_String,
         Run_Observers        => Properties.My_Properties'Access);
    use Simulator_Pkg;

--   procedure Encode_And_md5 (State: asn1SccSystem_State) is
--       uPER_Encoded : asn1SccSystem_State_uPER_Stream;
--       uPER_Result  : adaasn1rtl.ASN1_RESULT;
--   begin
--       uPER_Result := asn1SccSystem_State_IsConstraintValid (State);
--       Put_Line ("IsConstraintValid: " &  uPER_Result.Success'Img & uPER_Result.ErrorCode'Img);
--       asn1SccSystem_State_Encode (State, uPER_Encoded, uPER_Result);
--       Put_Line (uPER_Result.Success'Img & uPER_Result.ErrorCode'Img);
--       Put_Line (adaasn1rtl.encoding.BitStream_Current_Length_In_Bytes(uPER_Encoded)'img);
--   end Encode_And_md5;

begin
    Simulator_Pkg.Simulation_Startup;
    Put_Line ("Now exhausting all interfaces...");
    Simulator_Pkg.Run_Exhaustive_Simulation;
end MC;
