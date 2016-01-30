program main;

var i, j, k:integer;

function power(a:integer):integer;
begin
  if a > 1 then
    power := power(a - 1) * a
  else power := 1
end;

begin
  while 1=1 do
  begin
    call read(i);
    if i = 0 then break;
    j := power(i);
    call write(j)
  end
end.
