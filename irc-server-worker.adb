private with Ada.Streams,
     Ada.Strings.Fixed,
     Ada.Strings.Hash,
     Ada.Strings.Maps,
     Ada.Text_IO,
     GNAT.Sockets,
     Ada.Exceptions;

package body IRC.Server.Worker is
   use GNAT.Sockets,
       Ada.Strings.Fixed,
       Ada.Strings.Maps,
       Ada.Text_IO,
       Ada.Exceptions;
   
   -- We need a Hash function to make sure our Hashed_Maps.Map container can
   -- proeprly create the hash map. This function will just rely on the
   -- Ada.Strings.Hash function and pass in the string representation of the
   -- Task_Id
   function Hash (Key : Ada.Task_Identification.Task_Id) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Hash (Ada.Task_Identification.Image (Key));
   end Hash;

   -- Function to return debug.
   procedure Debug (Message : String) is
   begin
      Put_Line ("Worker: " & Message);
   end Debug;

   -- A worker task to handle an IRC client.
   task body Worker is
      use Ada.Streams;
      
      Client_Sock : Socket_Type;
   begin
      accept Serve (Sock : Socket_Type) do
         Debug ("Start called.");
         Client_Sock := Sock;
      end Serve;
      
      declare      
         Channel  : Stream_Access := Stream (Client_Sock);

         U        : User;
         ServPass : Boolean := False;
         NickSent : Boolean := False;
         NextChar : Character;
         
         Ctr      : Long_Long_Integer := 0;
      begin
         Event_Loop:
         while True loop
            declare
               Msg	       : String(1..50000);
               Msg_Len    : Natural := 0;
               Msg_Curs_1 : Natural := 0;
               Msg_Curs_2 : Natural := 0;
            begin
               
               -- Read in full lines before processing protocol commands
               declare
                  Loop_Index : Integer := 0;
               begin
                  Line_Loop :
                  loop
                     Loop_Index := Loop_Index + 1;
                     NextChar := Character'Input (Channel);
                     Msg(Loop_Index) := NextChar;
                     exit Line_Loop when NextChar = Ascii.LF;
                     Msg_Len := Msg_Len + 1;
                  end loop Line_Loop;
               end;
               
               -- Print line
               if Msg(1) /= Ascii.LF then
                  Debug ( "Client message: " & Msg(1..Msg_Len) );
               end if;
               
               -- Quit if the client qants to
               if Msg(1..4) = "QUIT" then
                  Debug ("Client quit.");
                  exit Event_Loop;
               end if;
               
               -- Start IRC processing
               if not U.ConnRegd then
                  -- Get Index of next space
                  Msg_Curs_1 := Index(Source => Msg, Pattern => " ");
                  
                  -- If user sent nothing, skip
                  if Msg_Curs_1 > 0 then
                     -- TODO: Check for password
                     if (ServPass = True) and ( Msg = "PASS" ) then
                        Debug ("Recieved PASS but we don't do anything with it yet.");
                     end if;
                     -- Check for nickname
                     if ( Msg (1 .. Msg_Curs_1 - 1) = "NICK" ) and ( not NickSent ) then
                        Debug ("Getting nickname.");
                        -- If there is a space, split at the space.
                        declare
                           LineFeed : String(1..1);
                           CharSet  : Character_Set;
                        begin
                           LineFeed(1) := Ascii.CR;
                           CharSet     := To_Set (" " & LineFeed);
                           Msg_Curs_1 := Msg_Curs_1 + 1;
                           Msg_Curs_2 := Index(Source => Msg, From => Msg_Curs_1, Set => CharSet) - 1;
                        
                           if Msg_Curs_2 = 0 then
                              Debug ("I don't know what you did, and you're probably about to segfault.");
                           end if;
                        end;
                        
                        Debug ("Positions: " & Ascii.LF & "1: " & Natural'Image(Msg_Curs_1) & Ascii.LF & "2: " & Natural'Image(Msg_Curs_2));
                        
                        U.Nickname(1..(Msg_Curs_2 - Msg_Curs_1 + 1)) := Msg(Msg_Curs_1..Msg_Curs_2);
                        Debug ("Got nickname: " & U.Nickname);
                        
                        NickSent := True;
                     end if;
                     -- Check for username
                     if ( NickSent = True ) and ( Msg (1 .. Msg_Curs_1 - 1) = "USER" ) then
                        -- If there is a space, split at the space.
                        Msg_Curs_2 := Index(Source => Msg, From => Msg_Curs_1, Pattern => " ");
                        
                        if Msg_Curs_2 = 0 then
                           Msg_Curs_2 := Msg'Last - 1;
                        end if;
                        
                        U.Username := Msg(Msg_Curs_1..Msg_Curs_2);
                        Debug ("Got username: " & U.Username);
                        
                        U.ConnRegd := True;
                     end if;
                  end if;
               else
                  -- No-op for now
                  null;
               end if;
               
               Ctr := Ctr + 1;
               Debug ("Client message number: " & Long_Long_Integer'Image(Ctr));
            end;
         end loop Event_Loop;
         Debug (".. closing connection");
         Close_Socket (Client_Sock);
      end;
   exception when E : others =>
         Debug ("Threw exception!" & Ascii.LF & Exception_Information (E));
   end Worker;
   
   
   protected body Coordinator is
      
      procedure Last_Wish (C : Ada.Task_Termination.Cause_Of_Termination;
                           T : Ada.Task_Identification.Task_Id;
                           X : Ada.Exceptions.Exception_Occurrence) is
         W : Worker_Ptr := Tasks.Element (T);
      begin
         
         -- First, let's make sure we remove the task object from our Tasks
         -- map
         Tasks.Delete (Key => T);
         -- Then we deallocate it
         Free_Worker (W);
         Ada.Text_IO.Put_Line ("Task (" & Ada.Task_Identification.Image (T) & ") deallocated");
         
      end Last_Wish;
      
      procedure Track (Ptr : in Worker_Ptr) is
      -- The Task_Id for a task can be found in the Identity attribute,
      -- but since we're receiving a Worker_Ptr type, we first need to
      -- dereference it into a Worker again
         Key : constant Ada.Task_Identification.Task_Id := Ptr.all'Identity;
      begin
         
         Ada.Text_IO.Put_Line ("Adding task (" & Ada.Task_Identification.Image (Key) & ") to Coordinator.Tasks");
         
         -- Add our Worker pointer into our hash map to hold onto it for
         -- later
         Tasks.Insert (Key      => Key,
                       New_Item => Ptr );
         
         -- We need to set a task termination handler (introduced in Ada
         -- 2005) in order to get called when the Worker (W) terminates
         Ada.Task_Termination.Set_Specific_Handler (Key, Last_Wish'Access);
         
      end Track;
   end Coordinator;
end IRC.Server.Worker;
