program main;
  var i, j:integer;
      a:array[1..5] of integer;

begin
  j := 10;
  for a[4] := 1 to 2 * j do
  begin
    call write(a[4])
  end
end.
