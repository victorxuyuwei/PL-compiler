program interpret(input,output,fcode);
     const stacksize=1023;
           cxmax=200;
           levmax=10;
           amax=2047;
     type
     types=(notyp,ints,chars,arrays);
     opcod = (lit,lod,ilod,loda,lodt,sto,lodb,cpyb,jmp,jpc,red,wrt,
            cal,retp,endp,udis,opac,entp,ands,ors,nots,imod,mus,add,
            sub,mult,idiv,eq,ne,ls,le,gt,ge);  { opration code }
     instruction = packed record
                     f:opcod;
                     l:0..levmax;
                     a:0..amax;
                   end;
     var pc,base,top:integer;  { program-,base-,topstack-register }
         oldtop:integer;
         i:instruction;          { instruction register }

         s:array[0..stacksize] of integer;                   { data store }

         display:array[0..levmax] of integer;
         code:array[0..cxmax] of instruction;
         fcode:file of instruction;
         filecode:string;            { name of code file }
         stop:boolean;
         h1,h2,h3:integer;
         ch:char;
     procedure load;
      var
        i:integer;
     begin
       writeln('plese input code file:');
       read(filecode);
       assign(fcode,filecode);
       reset(fcode);
       i:=0;
       while not eof(fcode) do
         begin
           read(fcode,code[i]);
           i:=i+1
         end;
       close(fcode)
     end;
  begin  { main }
    load;
    writeln('START PL/0');
    oldtop:=0;
    stop:=false;
    top:=0; base:=0; pc:=0;
    display[1]:=0;
    s[1]:=0; s[2]:=0; s[3]:=0;
    repeat
      i:=code[pc]; pc:=pc+1;
      with i do
        case f of
          lit: begin top:=top+1; s[top]:=a end;
          lod: begin top:=top+1; s[top]:=s[display[l]+a]  end;
          loda:begin top:=top+1; s[top]:=display[l]+a     end;
          ilod:begin top:=top+1; s[top]:=s[s[display[l]+a]] end;
          lodt:begin s[top]:=s[s[top]]                  end;
          lodb:begin
                   h1:=s[top];top:=top-1;  h2:=a+top;
                   while top < h2 do
                     begin
                       top:=top+1;
                       s[top]:=s[h1];
                       h1:=h1+1
                     end;
               end;
          cpyb:begin
                   h1:=s[top-1];h2:=s[top];h3:=h1+a;
                   while h1 < h3 do
                     begin
                       s[h1]:=s[h2];
                       h1:=h1+1 ;h2:=h2+1
                     end;
                     top:=top-2
                   end;
          sto: begin s[s[top-1]]:=s[top];  top:=top-2;       end;
          opac:begin
                 oldtop:=top;
                 top:=top+3
               end;
          cal: begin  { generate new block mark }
                 s[oldtop+1]:=pc;
                 s[oldtop+2]:=display[l]; s[oldtop+3]:=base;
                 pc:=a;
               end;
          entp:begin
                 base:=oldtop+1; display[l]:=base;
                 top:=oldtop+a
               end;
          udis:begin
                 h1:=a;h2:=l;h3:=base;
                 repeat
                   display[h1]:=h3;h1:=h1-1;
                   h3:=s[h3+2]
                 until h1=h2
               end;
          jmp: pc:=a;
          jpc: begin if s[top]=0 then pc:=a; top:=top-1 end;
          retp:begin {return}
                 top:=base-1; pc:=s[top+1]; base:=s[top+3];
               end;
          endp:begin
                    stop:=true
               end;
          red: begin write(' ??:');
                    if a=0 then readln(s[s[top]])
                    else begin
                           readln(ch);s[s[top]]:=ord(ch);
                         end;
                    top:=top-1
               end;
          wrt: begin if a=0 then writeln(s[top])
                    else begin
                           ch:=chr(s[top]); writeln(ch)
                         end;
                    top:=top-1
               end;
          mus :s[top]:=-s[top];
          add :begin top:=top-1; s[top]:=s[top]+s[top+1] end;
          sub :begin top:=top-1; s[top]:=s[top]-s[top+1] end;
          mult:begin top:=top-1; s[top]:=s[top]*s[top+1] end;
          idiv:begin top:=top-1; s[top]:=s[top] div s[top+1] end;
          imod:begin top:=top-1; s[top]:=s[top] mod s[top+1] end;
          ands:begin top:=top-1; s[top]:=s[top] and s[top+1] end;
          ors :begin top:=top-1; s[top]:=s[top] or  s[top+1] end;
          nots:s[top]:=not s[top];
          eq  :begin top:=top-1; s[top]:=ord(s[top]=s[top+1]) end;
          ne  :begin top:=top-1; s[top]:=ord(s[top]<>s[top+1]) end;
          ls  :begin top:=top-1; s[top]:=ord(s[top]<s[top+1]) end;
          ge  :begin top:=top-1; s[top]:=ord(s[top]>=s[top+1]) end;
          gt  :begin top:=top-1; s[top]:=ord(s[top]>s[top+1]) end;
          le  :begin top:=top-1; s[top]:=ord(s[top]<=s[top+1]) end;
        end  { case,with }
    until stop=true;
    writeln(' END PL/0 ');
  end.   { interpret }
