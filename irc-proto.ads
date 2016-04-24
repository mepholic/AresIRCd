generic
   Msg_Curs_1 : Natural := 0;
   Msg_Curs_2 : Natural := 0;
   Msg_P_Len  : Natural := 0;
package IRC.Proto is
   function Next_Part (Msg           : String;
                       New_Line_Only : Boolean := False) return String;
   Bad : exception;
end IRC.Proto;
