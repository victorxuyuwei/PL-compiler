program prime;

const pmax=50;
var cnt:integer;
    nop: array[1..pmax] of boolean;

function getp:integer;
  var i,j:integer;
begin
  for i := 2 to pmax do
    begin
      if nop[i] then continue;
      call write(i);
      getp := getp + 1;
      j := i * 2;
      while j <= pmax do
        begin
          nop[j] := true;
          j := j + i
        end
    end
end;

begin
  cnt := getp();
  call write(cnt)
end.
