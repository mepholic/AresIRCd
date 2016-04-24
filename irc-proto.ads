generic
   First_Pass   : Boolean := True;
   Msg_Cursor_1 : Natural := 0;
   Msg_Cursor_2 : Natural := 0;
   Msg_Part_Len : Natural := 0;
package IRC.Proto is
   function Next_Index (Msg         : String;
						To_End      : Boolean := False) return Natural;
   function Next_Part  (Msg         : String;
					    Empty_Valid : Boolean := False;
					    Eat_Colon   : Boolean := False;
                        To_End      : Boolean := False) return String;
   Bad : exception;
end IRC.Proto;
