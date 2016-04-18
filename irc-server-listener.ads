with GNAT.Sockets,
  IRC.Server.Worker;

package IRC.Server.Listener is
   
   task type Listener is
	  entry Start (Addr : GNAT.Sockets.Sock_Addr_Type);
	  --entry Stop;
   end Listener;
   
end IRC.Server.Listener;
