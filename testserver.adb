with IRC.Server.Listener,
     Ada.Text_IO,
     GNAT.Sockets,
     Ada.Exceptions;

procedure TestServer is
   use IRC.Server.Listener,
       Ada.Text_IO,
       GNAT.Sockets,
       Ada.Exceptions;
   
   Addr : Sock_Addr_Type;
   L : Listener;
begin
   Addr.Addr := Inet_Addr ("0.0.0.0");
   Addr.Port := Port_Type (6667);
   
   Put_Line ("testserver: Starting server.");
   L.Start (Addr);
   
exception when E : others =>
      Put_Line ("testserver: Threw exception!" & Ascii.LF &
                  Exception_Information (E));
end TestServer;
