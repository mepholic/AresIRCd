with Ada.Strings.Fixed,
     Ada.Strings.Maps;

package body IRC.Proto is
   use Ada.Strings.Fixed,
       Ada.Strings.Maps;
   
   -- Function to return the next index of the message
   function Next_Index (Msg       : String;
                        To_End    : Boolean := False) return Natural Is
   begin
      if To_End then
         -- Check if we want to find the end of the line
         Char_Set      := To_Set (Ascii.CR);
      else
         -- Otherwise, find space or end of line
         Char_Set      := To_Set (" " & Ascii.CR);
      end if;    
      
      -- Return the index
      return Index(Source => Msg, From => Msg_Cursor_1, Set => Char_Set);
   end Next_Index;
   
   -- Function to return the next part of the message
   function Next_Part  (Msg   : String;
                        Empty_Valid : Boolean := False;
                        Eat_Colon   : Boolean := False;
                        To_End      : Boolean := False) return String Is
   begin
      declare
         Char_Set : Character_Set;
      begin
         
         -- Check if first pass
         if First_Pass then
            -- Set the index of the first space in Cursor 1
            Msg_Cursor_1 := Index(Source => Msg, Pattern => " ");
            First_Pass   := False;
         else
            -- Set Cursor 2 to the space after our last part
            Msg_Cursor_2 := Msg_Cursor_2 + 1;
            -- Set Cursor 1 to the position after Cursor 2
            Msg_Cursor_1 := Msg_Cursor_2 + 1;
         end if;
         
         -- Set Cursor 2 to the position of the next space
         Msg_Curors_2 := Next_Index (Msg, To_End);
         
         -- If there's a colon and we want to eat it, then eat it
         if Eat_Colon and ( Msg(Msg_Cursor_1) = Ascii.Colon ) then
            -- Skip the : in the message
            Msg_Cursor_1 := Msg_Cursor_1 + 1;
         end if;
         
         -- Calculate the length of the part we grabbed
         Msg_Part_Len := Msg_Cursor_2 - Msg_Cursor_1 + 1;
         
         -- Check if the length is allowed to be 0 or not
         if Empty_Valid and ( Msg_Part_Len >= 0 ) then
            return Msg(Msg_Cursor_1..Msg_Cursor_2);
         elsif Msg_Part_Len > 0 then
            return Msg(Msg_Cursor_1..Msg_Cursor_2);
         else
            return Bad;
         end if;
         
      end;
   end Next_Part;
end package IRC.Proto;
