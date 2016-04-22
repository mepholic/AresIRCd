with GNAT.Sockets,
  IRC.Server.Worker;

package IRC.Server.Listener is
   
   -- Procedure to print Listener debug messages
   procedure Debug (Message : String);
   
   -- A server listener task.
   task type Listener is
      -- Start a listener task to listen for connections from IRC clients or servers.
      entry Start (Addr : GNAT.Sockets.Sock_Addr_Type);
   end Listener;
   
end IRC.Server.Listener;
