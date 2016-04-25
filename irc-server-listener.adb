private with Ada.Text_IO,
     GNAT.Sockets,
     Ada.Exceptions;

with IRC.Server.Worker;

package body IRC.Server.Listener is
   use Ada.Text_IO,
       GNAT.Sockets,
       Ada.Exceptions;
   
   -- Function to return debug.
   procedure Debug (Message : String) is
   begin
      Put_Line ("Listener: " & Message);
   end Debug;
   
   task body Listener is
      Server_Addr  : Sock_Addr_Type;
      Server_Sock  : Socket_Type;
   begin
      -- Accept address to bind to as a parameter
      accept Start (Addr : Sock_Addr_Type) do
         Debug ("Start called.");
         Server_Addr := Addr;
      end Start;
      
      Debug ("Initializing socket.");
      Initialize (Process_Blocking_IO => False);
      
      --  Create the socket
      Debug ("Creating socket.");
      Create_Socket (Server_Sock);
      
      --  Allow reuse of local addresses.
      Debug ("Setting socket options.");
      Set_Socket_Option (Server_Sock, Socket_Level, (Reuse_Address, True));
      
      -- Bind the socket
      Debug ("Binding socket.");
      Bind_Socket (Server_Sock, Server_Addr);
      
      --  A server marks a socket as willing to receive connect events.
      Debug ("About to listen.");
      Listen_Socket (Server_Sock);
      Debug ("Listening on port" &
               Port_Type'Image(Server_Addr.Port));
      
      loop
         -- Wait for clients
         declare
            use IRC.Server.Worker;
            
            Client_Sock : Socket_Type;
            W : Worker_Ptr := new Worker.Worker;
         begin
            -- Accept connection
            IRC.Server.Listener.Debug ("Waiting for new client connection.");
            Accept_Socket (Server_Sock, Client_Sock, Server_Addr);
            IRC.Server.Listener.Debug ("Accepted connection from port" & 
                                         Port_Type'Image(Server_Addr.Port));
            -- Serve client and add thread to coordinator.
            W.all.Serve (Client_Sock);
            Coordinator.Track (W);
         end;
         
         accept Stop do
            Close_Socket (Server_Sock);
         end Stop;
      end loop;
      
      
   exception when E : others =>
         Debug ("Threw exception!" & Ascii.LF & Exception_Information (E));
   end Listener;
end IRC.Server.Listener;
