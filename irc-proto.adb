with Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Text_IO;

package body IRC.Proto is
   use Ada.Strings.Fixed,
       Ada.Strings.Maps;
   
   -- Function to return the first part of the message
   procedure First_Part (Msg    : String) Is
      Char_Set : Character_Set;
   begin
      -- Set our charset
      Char_Set      := To_Set (" " & Ascii.CR);
      
      -- Set the index of the first space in Cursor 1
      Msg_Cursor_1 := Index(Source => Msg, Set => Char_Set);
      First_Pass   := False;
      
      Ada.Text_IO.Put_Line("IRC.Proto: " & Ascii.LF &
                             "Index 1: " & Natural'Image(Msg_Cursor_1) & Ascii.LF &
                             "Index 2: " & Natural'Image(Msg_Cursor_2)
                          );

      -- Get the part length
      Msg_Part_Len := Msg_Cursor_1 - 1;
      
      -- Check if the part is less than the max size
      if Msg_Part_Len <= Part_Max_Len then
         Msg_Part_Str(1..Msg_Part_Len) := Msg (Msg'First .. Msg_Part_Len);
      else
         raise Bad;
      end if;
      
      Ada.Text_IO.Put_Line("IRC.Proto: First_Part: " & Msg_Part_Str);
      --return Msg_Part_Str;
   end First_Part;
   
   -- Function to return the next index of the message
   function Next_Index (Msg    : String;
                        To_End : Boolean := False) return Natural Is
      Char_Set : Character_Set;
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
   procedure Next_Part  (Msg         : String;
                         Empty_Valid : Boolean := False;
                         Eat_Colon   : Boolean := False;
                         To_End      : Boolean := False) Is
   begin
      -- Check if first pass
      if First_Pass then
         raise Bad;
      else
         Msg_Cursor_1 := Msg_Cursor_1 + 1;	-- Set Cursor 1 to the next index after it's current position
         Msg_Cursor_2 := Msg_Cursor_1;		-- Set Cursor 2 to the same position as Cursor 2
      end if;
      
      -- Set Cursor 2 to the position of the next space or newline
      Msg_Cursor_2 := Next_Index (Msg, To_End);
      
      -- If there's a colon and we want to eat it, then eat it
      if Eat_Colon and ( Msg(Msg_Cursor_1) = Ascii.Colon ) then
         -- Skip the : in the message
         Msg_Cursor_1 := Msg_Cursor_1 + 1;
      end if;
      
      -- Calculate the length of the part we grabbed ()
      Msg_Part_Len := Msg_Cursor_2 - Msg_Cursor_1;
      
      -- Debug
        Ada.Text_IO.Put_Line("IRC.Proto : " & Ascii.LF &
                               "Message : " & Msg & Ascii.LF &
                               "Msg_Len : " & Natural'Image(Msg_Len) & Ascii.LF &
                               "Cursor 1: " & Natural'Image(Msg_Cursor_1) & Ascii.LF &
                               "Cursor 2: " & Natural'Image(Msg_Cursor_2) & Ascii.LF &
                               "Part    : -" & Msg(Msg_Cursor_1..Msg_Cursor_1 + (Msg_Part_Len - 1)) & "-" & Ascii.LF &
                               "Part_Len: " & Natural'Image(Msg_Part_Len)
                            );
      
      -- Check if cursor is out of bounds
      if Msg_Cursor_2 > Msg_Len then
         raise Bad;
      end if;
      
      -- Set the part
      declare
         Part : String := Msg(Msg_Cursor_1..Msg_Cursor_1 + (Msg_Part_Len - 1));
      begin
         Msg_Part_Str(1..Msg_Part_Len) := Part;
      end;
      
      Ada.Text_IO.Put_Line("IRC.Proto: Next_Part: " & Msg_Part_Str);
      
      -- Check if the length exceeds out max
      if ( Msg_Part_Len <= Part_Max_Len ) then
         -- Return string depending on length constraints
         if Empty_Valid and ( Msg_Part_Len >= 0 ) then
            --return Msg_Part_Str;
            null;
         elsif Msg_Part_Len > 0 then
            --return Msg_Part_Str;
            null;
         else
            raise Bad;
         end if;
      else
         raise Bad;
      end if;
   end Next_Part;
   -- Function to return the last fetched part
   function Get_Part return String Is
   begin
      return Msg_Part_Str(1..Msg_Part_Len);
   end Get_Part;
end IRC.Proto;
