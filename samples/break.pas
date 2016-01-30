program main;
var i:integer;

begin
  while true do 
  begin
    call read(i);
    if i = 1 then begin
      call write(11);
      break
    end;
    if i = 2 then begin
      call write(22);
      break
    end;
    if i = 3 then begin
      call write(33);
      break
    end;
    if i = 4 then begin
      call write(44);
      continue
    end;
    if i = 5 then begin
      call write(55);
      continue
    end;
    call write(0)
  end
end.
