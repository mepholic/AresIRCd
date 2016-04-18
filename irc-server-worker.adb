private with Ada.Streams,
		  Ada.Strings.Fixed,
		  Ada.Strings.Hash,
		  Ada.Text_IO,
		  GNAT.Sockets;

package body IRC.Server.Worker is
   use Ada.Text_IO,
	 GNAT.Sockets,
	 Ada.Strings.Fixed;
   
   -- We need a Hash function to make sure our Hashed_Maps.Map container can
   -- proeprly create the hash map. This function will just rely on the
   -- Ada.Strings.Hash function and pass in the string representation of the
   -- Task_Id
   function Hash (Key : Ada.Task_Identification.Task_Id) return Ada.Containers.Hash_Type is
   begin
	  return Ada.Strings.Hash (Ada.Task_Identification.Image (Key));
   end Hash;
   
   
   -- I'm trying to convert the Stream_Element_Array to a String,
   -- but it seems like something is getting angry and the thread is dying???
   function Stream_To_String (S : Ada.Streams.Stream_Element_Array) return String is
	  String_View : String (0 .. S'Size);
	  for String_View'Address use S'Address; 
   begin 
	  return String_View; 
   end Stream_To_String; 
   
   task body Worker is
	  use Ada.Streams;
	  
	  Client_Sock : Socket_Type;
   begin
	  accept Serve (Sock : Socket_Type) do
		 Client_Sock := Sock;
	  end Serve;
	  
	  declare
		 Channel  : Stream_Access := Stream (Client_Sock);
		 Data	  : Ada.Streams.Stream_Element_Array (1 .. 1);
		 Offset	  : Ada.Streams.Stream_Element_Count;
		 
		 U		  : User;
		 ServPass : Boolean := False;
		 NickSent : Boolean := False;
		 
		 Msg	  : String (1 .. 4096);
		 Msg_Pos  : Natural := 0;
	  begin
		 while True loop
			Ada.Streams.Read (Channel.all, Data, Offset);
			-- exit when Offset = 0;

			-- Print recieved message
			Msg := Stream_To_String(Data);
			Put_Line (Msg);
			
			-- Start IRC processing
			while not U.ConnRegd loop
			   -- Get Index of next space
			   Msg_Pos := Index(Source => Msg, Pattern => " ");
			   
			   Put_Line (Msg);
			   -- If user sent nothing, skip
			   if Msg_Pos > 0 then
				  -- TODO: Check for password
				  if (ServPass = True) and ( Msg (1 .. Msg_Pos - 1) = "PASS" ) then
					 Put_Line ("Recieved PASS but we don't do anything with it yet.");
				  end if;
				  -- Check for nickname
				  if Msg (1 .. Msg_Pos - 1) = "NICK" then
					 --Msg_Pos := Index(Source => Msg (StrPos, Msg'Last, Pattern => " ");
					 --U.Nickname := Msg()
					 Put_Line ("Got nickname:" & Msg);
					 
					 NickSent := True;
				  end if;
				  -- Check for username
				  if (NickSent = True) and ( Msg (1 .. Msg_Pos - 1) = "" ) then
					 Put_Line ("Got username:" & Msg);
				  end if;
			   end if;
			end loop;
		 end loop;
		 Put_Line (".. closing connection");
		 Close_Socket (Client_Sock);
	  end;
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
		 Put_Line ("Task (" & Ada.Task_Identification.Image (T) & ") deallocated");
		 
	  end Last_Wish;
	  
	  procedure Track (Ptr : in Worker_Ptr) is
		 -- THe Task_Id for a task can be found in the Identity attribute,
		 -- but since we're receiving a Worker_Ptr type, we first need to
		 -- dereference it into a Worker again
		 Key : constant Ada.Task_Identification.Task_Id := Ptr.all'Identity;
	  begin
		 
		 Put_Line ("Adding task (" & Ada.Task_Identification.Image (Key) & ") to Coordinator.Tasks");
		 
		 -- Add our Worker pointer into our hash map to hold onto it for
		 -- later
		 Tasks.Insert (Key		=> Key,
					   New_Item => Ptr);
		 
		 -- We need to set a task termination handler (introduced in Ada
		 -- 2005) in order to get called when the Worker (W) terminates
		 Ada.Task_Termination.Set_Specific_Handler (Key, Last_Wish'Access);
		 
	  end Track;
   end Coordinator;
end IRC.Server.Worker;
