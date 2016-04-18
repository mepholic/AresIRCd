with Ada.Text_IO,
  GNAT.Sockets,
  IRC.Server.Worker,
  Ada.Exceptions;

package IRC.Server.Listener is
   
   task type Listener is
      entry Start (Addr : GNAT.Sockets.Sock_Addr_Type);
      --entry Stop;
   end Listener;
      
end IRC.Server.Listener;
