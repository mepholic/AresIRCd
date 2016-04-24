with Ada.Strings.Fixed,
     Ada.Strings.Maps;

package body IRC.Proto is
   use Ada.Strings.Fixed,
       Ada.Strings.Maps;

   -- Function to return the next part of the message
   function Next_Part (Msg         : String;
                       To_New_Line : Boolean := False) return String is
      declare
         Char_Set : Character_Set;
      begin
         -- Check if newline only, otherwise, split at space too.
         if New_Line_Only then
            Char_Set      := To_Set (Ascii.CR);
         else
            Char_Set      := To_Set (" " & Ascii.CR);
         end if;

         Msg_Cursor_2 := Index(Source => Msg, From => Msg_Cursor, Set => Char_Set);



      end;
   end Next_Part;
end package IRC.Proto;
