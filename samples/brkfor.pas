program main;
var i, j, k:integer;

begin
  for j:= 1 to 10 do 
  begin
    call write(j);
    call read(i);
    if i = 1 then begin
      call write(11);
      break
    end;
    
    if i = 2 then begin
      call write(22);
      break
    end;

    for k := 30 to 33 do
    begin
      if j = 2 then continue;
      call write(k)
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
