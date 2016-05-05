with Ada.Characters.Latin_1;

generic
package IRC.Proto is
   Part_Max_Len : Natural := 5000;
   First_Pass   : Boolean := True;

   Msg_Len      : Natural := 0;
   Msg_Marker_1 : Natural := 0;
   Msg_Marker_2 : Natural := 0;
   Msg_Part_Str : String(1..Part_Max_Len);
   Msg_Part_Len : Natural := 0;

   -- Procedure to parse a message
   procedure Parse_Message (Msg : String);

   -- Procedure to set the first part of the IRC message
   procedure First_Part (Msg : String);

   -- Function to get the index of the next space or newline in a string
   function Next_Index (Msg         : String;
                        To_End      : Boolean := False) return Natural;

   -- Procedure to set the next part of an IRC message
   procedure Next_Part  (Msg         : String;
                         Empty_Valid : Boolean := False;
                         Eat_Colon   : Boolean := False;
                         To_End      : Boolean := False);

   -- Function to get the last fetched part
   function Get_Part return String;
   Bad : exception;

private
   package Ascii_L1 renames Ada.Characters.Latin_1;
end IRC.Proto;
