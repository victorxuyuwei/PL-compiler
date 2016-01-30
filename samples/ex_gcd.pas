program main;
var
  i,j,k,l:integer;

function exgcd(a,b:integer; var x,y:integer):integer;
  var t:integer;
begin
  if b = 0 then
  begin
    x := 1;
    y := 0;
    exgcd := a
  end
  else begin
    exgcd := exgcd(b, a mod b, x, y);
    t := x;
    x := y;
    y := t - a / b * y
  end
end;

begin
  while true do
  begin
    call read(i);
    call read(j);
    i := exgcd(i,j,k,l);
    call write(i);
    call write(k);
    call write(l)
  end
end.
