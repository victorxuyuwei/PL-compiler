program main;
var
   a, b: integer;
begin
   a := 100;
   b := 200;
   case (a) of
      1: call write(1);
      2: call write(2);
      3: call write(3);
      100: begin
              call write(100);
              case (b) of
                 200: call write(200);
              end;
              case a of
                 200: call write(101);
              else 
                 call write(111);
              end
           end;
       100: call write('f');
       100: call write('f');
       100: call write('f');
   end;
   call write(-1)
end.

