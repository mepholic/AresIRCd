with Ada.Strings.Fixed,
     Ada.Strings.Maps,
     Ada.Text_IO;

package body IRC.Proto is
   use Ada.Strings.Fixed,
       Ada.Strings.Maps;
   
   -- Parse a message
   procedure Parse_Message (Msg : String) Is
      Command   : String(1..80);                  -- IRC command
      Arguments : array(1..8) of String(1..32);   -- Array of arguments
      Arg_Ctr   : Natural := 0;                   -- Number of arguments
      Data      : String(1..250);                 -- Data or message
      
      Char_Set  : Character_Set;                  -- Characters we'll cut at
      
      Cmd_Only  : Boolean := False;               -- Only a command, no arguments or data
      No_Data   : Boolean := False;               -- Command and arguments, no data
   begin
      -- Set the charset to a space or newline
      Char_Set     := To_Set (" " & Ascii_L1.LF);
      
      -- Set the first marker after the command, or EOL
      Msg_Marker_1 := Index (Source => Msg, Set => Char_Set);
      Ada.Text_IO.Put_Line ("IRC.Proto: Marker 1: " & Natural'Image (Msg_Marker_1));
      
      -- Check if the message is valid
      if Msg (Msg_Marker_1) = Ascii_L1.LF then
         Cmd_Only := True;
         -- TODO: return gracefully
      elsif Msg (Msg_Marker_1) /= Ascii_L1.Space then
         Ada.Text_IO.Put_Line ("IRC.Proto: Invalid character at Marker 1");
         raise Bad;
      end if;
      
      -- Get the command
      -- First message character to character before the first marker
      Command (1..Msg_Marker_1 - 1) := Msg (Msg'First..(Msg_Marker_1 - 1));
      
      Ada.Text_IO.Put_Line ("IRC.Proto: Got command: " & Command);
      
      -- Set the charset to a colon or newline
      Char_Set     := To_Set (":" & Ascii_L1.LF);
      
      -- Set the second marker after the arguments
      -- We might want to increment the first marker by 1
      Msg_Marker_2 := Index (Source => Msg, Set=> Char_Set, From => Msg_Marker_1);
      
      -- Check if args are valid
      if Msg (Msg_Marker_2) = Ascii_L1.LF then
         No_Data := True;
         -- TODO: return gracefully after getting args
      elsif Msg (Msg_Marker_2) /= Ascii_L1.Colon then
         Ada.Text_IO.Put_Line ("IRC.Proto: Invalid character at Marker 2");
         raise Bad;
      end if;
      
      -- Get the arguments
      declare
         -- Begin the madness!
         Arg_Cursor_1 : Natural := Msg_Marker_1 + 1;  -- Should always point at the first character of the argument we are parsing
         Arg_Cursor_2 : Natural;                      -- Should always point at the character after the argument we're parsing
      begin
         -- Set the charset to all possibilities
         Char_Set     := To_Set (" :" & Ascii_L1.LF);
         
         -- Only grab 8 arguments
         while Arg_Ctr < 8 loop
            Arg_Cursor_2 := Index (Source => Msg, Set=> Char_Set, From => Arg_Cursor_1);
            
            -- Check if we need to continue looking for arguments
            if Msg (Arg_Cursor_2) = Ascii_L1.Space then
               
               -- Make sure we're not creeping into the data section or beyond
               if (Arg_Cursor_2 - 1) > Msg_Marker_2 then
                  Ada.Text_IO.Put_Line ( "IRC.Proto: The cursor went beyond the argument " &
                                           "section while parsing argument " &
                                           Natural'Image (Arg_Ctr + 1) );
                  raise Bad;
               end if;
            
               -- Suck up the argument
               Arguments (Arg_Ctr + 1) (1..Arg_Cursor_2 - Arg_Cursor_1) := Msg (Arg_Cursor_1..(Arg_Cursor_2 - 1));
               
               Ada.Text_IO.Put_Line ("IRC.Proto: Got argument: " & Arguments (Arg_Ctr + 1));
               
               -- Move the first argument cursor to the beginning of the next argument
               Arg_Cursor_1 := Arg_Cursor_2 + 1;
            else
               Ada.Text_IO.Put_Line ("IRC.Proto: Done searching for arguments.");
               exit;
            end if;
            
            -- Increment the argument counter
            Arg_Ctr := Arg_Ctr + 1;
         end loop;
      end;
      
      -- Get the data
      if (Msg (Msg_Marker_2) = Ascii_L1.Colon) and ((Msg_Marker_2 + 1) <= Msg_Len) then
         Data (1..Msg_Len - Msg_Marker_2) := Msg ((Msg_Marker_2 + 1)..Msg_Len);
         Ada.Text_IO.Put_Line ("IRC.Proto: Got data: " & Data);
      else
         Ada.Text_IO.Put_Line ("IRC.Proto: Message Marker 2 is not a :, or the length was somehow exceeded.");
         raise Bad;
      end if;
      
   end;
   
   -- Function to return the first part of the message
   procedure First_Part (Msg    : String) Is
      Char_Set : Character_Set;
   begin
      -- Set our charset
      Char_Set      := To_Set (" " & Ascii_L1.CR);
      
      -- Set the index of the first space in Cursor 1
      Msg_Marker_1 := Index(Source => Msg, Set => Char_Set);
      First_Pass   := False;
      
      Ada.Text_IO.Put_Line("IRC.Proto: " & Ascii_L1.LF &
                             "Index 1: " & Natural'Image(Msg_Marker_1) & Ascii_L1.LF &
                             "Index 2: " & Natural'Image(Msg_Marker_2)
                          );

      -- Get the part length
      Msg_Part_Len := Msg_Marker_1 - 1;
      
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
         Char_Set      := To_Set (Ascii_L1.CR);
      else
         -- Otherwise, find space or end of line
         Char_Set      := To_Set (" " & Ascii_L1.CR);
      end if;    
      
      -- Return the index
      return Index(Source => Msg, From => Msg_Marker_1, Set => Char_Set);
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
         Msg_Marker_1 := Msg_Marker_1 + 1;	-- Set Cursor 1 to the next index after it's current position
         Msg_Marker_2 := Msg_Marker_1;		-- Set Cursor 2 to the same position as Cursor 2
      end if;
      
      -- Set Cursor 2 to the position of the next space or newline
      Msg_Marker_2 := Next_Index (Msg, To_End);
      
      -- If there's a colon and we want to eat it, then eat it
      if Eat_Colon and ( Msg(Msg_Marker_1) = Ascii_L1.Colon ) then
         -- Skip the : in the message
         Msg_Marker_1 := Msg_Marker_1 + 1;
      end if;
      
      -- Calculate the length of the part we grabbed ()
      Msg_Part_Len := Msg_Marker_2 - Msg_Marker_1;
      
      -- Debug
        Ada.Text_IO.Put_Line("IRC.Proto : " & Ascii_L1.LF &
                               "Message : " & Msg & Ascii_L1.LF &
                               "Msg_Len : " & Natural'Image(Msg_Len) & Ascii_L1.LF &
                               "Cursor 1: " & Natural'Image(Msg_Marker_1) & Ascii_L1.LF &
                               "Cursor 2: " & Natural'Image(Msg_Marker_2) & Ascii_L1.LF &
                               "Part    : -" & Msg(Msg_Marker_1..Msg_Marker_1 + (Msg_Part_Len - 1)) & "-" & Ascii_L1.LF &
                               "Part_Len: " & Natural'Image(Msg_Part_Len)
                            );
      
      -- Check if cursor is out of bounds
      if Msg_Marker_2 > Msg_Len then
         raise Bad;
      end if;
      
      -- Set the part
      declare
         Part : String := Msg(Msg_Marker_1..Msg_Marker_1 + (Msg_Part_Len - 1));
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
