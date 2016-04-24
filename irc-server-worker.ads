with Ada.Containers,
     Ada.Containers.Indefinite_Hashed_Maps,
     Ada.Exceptions,
     Ada.Task_Identification,
     Ada.Task_Termination,
     Ada.Unchecked_Deallocation,
     GNAT.Sockets,
     ADA.Streams;

package IRC.Server.Worker is
   
   -- A task to handle a Worker.
   task type Worker is
      -- Start a task to serve a worker.
      entry Serve (Sock : GNAT.Sockets.Socket_Type);
   end Worker;
   
   --- Declare a pointer type for pointers to Worker objects
   type Worker_Ptr is access all Worker;
   
   -- Declare records
   type User is tagged record
      ConnRegd : Boolean := False;
      Nickname : String(1..80);
      Username : String(1..80);
      Hostname : String(1..80);
      Servname : String(1..80);
      Realname : String(1..80);
   end record;
   
   -- Procedure to properly deallocate a heap-allocated Worker task
   procedure Free_Worker is new Ada.Unchecked_Deallocation (Object => Worker,
                                                            Name   => Worker_Ptr );
   -- Procedure to print Worker debug messages
   procedure Debug (Message : String);
   
   function Hash (Key : Ada.Task_Identification.Task_Id) return Ada.Containers.Hash_Type;
   
   package Worker_Containers is new Ada.Containers.Indefinite_Hashed_Maps (Key_Type        => Ada.Task_Identification.Task_Id,
                                                                           Element_Type    => Worker_Ptr,
                                                                           Hash            => Hash,
                                                                           Equivalent_Keys => Ada.Task_Identification."=" );
   
   protected Coordinator is
      procedure Track (Ptr : in Worker_Ptr);
   private
      Tasks : Worker_Containers.Map;
   end Coordinator;
   
end IRC.Server.Worker;
