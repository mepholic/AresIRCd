private with Ada.Text_IO,
	  GNAT.Sockets,
	  Ada.Exceptions;

-- Ada.Containers,
-- Ada.Streams,
-- Ada.Strings.Hash,
-- Ada.Unchecked_Deallocation,
-- Ada.Containers.Indefinite_Hashed_Maps,

with IRC.Server.Worker;

package body IRC.Server.Listener is
   use Ada.Text_IO,
     GNAT.Sockets,
     Ada.Exceptions;

   task body Listener is
      Server_Addr  : Sock_Addr_Type;
      Server_Sock  : Socket_Type;
   begin
      -- Accept address to bind to as a parameter
      accept Start (Addr : Sock_Addr_Type) do
	 Server_Addr := Addr;
      end Start;
      
      --   Initialize (Process_Blocking_IO => False);
      
      --  Create the socket
      Create_Socket (Server_Sock);

      --  Allow reuse of local addresses.
      Set_Socket_Option (Server_Sock, Socket_Level, (Reuse_Address, True));

      -- Bind the socket
      Bind_Socket (Server_Sock, Server_Addr);

      --  A server marks a socket as willing to receive connect events.
      Listen_Socket (Server_Sock);
      Put_Line ("Listener: Listening on port" &
		  Port_Type'Image(Server_Addr.Port));

      loop
	 -- Wait for clients
	 declare
	    use IRC.Server.Worker;
	    
	    Client_Sock : Socket_Type;
	    W : Worker_Ptr := new Worker.Worker;
	 begin
	    -- Accept connection
	    Accept_Socket (Server_Sock, Client_Sock, Server_Addr);
	    Put_Line ("Listener: Accepted connection from port" & 
			Port_Type'Image(Server_Addr.Port));
	    -- Serve client and add thread to coordinator.
	    W.all.Serve (Client_Sock);
	    Coordinator.Track (W);
	 end;
      end loop;
      
      --accept Stop;
      --Close_Socket (Server_Sock);
      
   exception when E : others =>
      Put_Line ("Listener: " & Exception_Name (E) & ": " & Exception_Message (E));
   end Listener;
end IRC.Server.Listener;
