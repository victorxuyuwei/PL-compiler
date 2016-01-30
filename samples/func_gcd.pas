program main;

var i,j,k,l:integer;

function gcd(a,b:integer):integer;
begin
  if b = 0 then
    gcd := a
  else
    gcd := gcd(b, a mod b)
end;

begin
  while true do
  begin
    call read(i);
    call read(j);
    k := gcd(i,j);
    call write(k)
  end
end.
