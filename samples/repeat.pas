program aa;
  var a,b,c:integer;

begin
  a:=1;
  b:=10;

  repeat
  begin
    call write(a);
    a:=a+1
  end
  until a=b
end.
