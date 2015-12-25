program plcopiler;
uses dos;

const norw=25;       { no. of reserved words }
      txmax=100;     { length of identifier table }
      bmax=20;       { length of block inormation table }
      arrmax=30;     { length of array information table }
      nmax=6;        { max. no. of digits in numbers }
      al=10;         { length of identifiers }
      amax=2047;     { maxinum address }
      levmax=7;      { maxinum depth of block nesting }
      cxmax=1000;    { size of code array }

type symbol=
     (nul,ident,intcon,charcon,plus,minus,times,divsym,
      eql,neq,lss,leq,gtr,geq, ofsym,arraysym,programsym,modsym,
      andsym,orsym,notsym,lbrack,rbrack,lparen,rparen,comma,
      semicolon,period,becomes,colon,beginsym,endsym,ifsym,thensym,
      elsesym,whilesym,repeatsym,dosym,callsym,constsym,typesym,
      varsym,procsym,
      forsym, tosym, downtosym, casesym, untilsym); { add five new symple }
     alfa = string[al];
     index=-32767..+32767;
     oobject = (konstant,typel,variable,prosedure);
     types=(notyp,ints,chars,bool,arrays);
     symset = set of symbol;

     opcod = (lit,lod,ilod,loda,lodt,sto,lodb,cpyb,jmp,jpc,red,wrt,
            cal,retp,endp,udis,opac,entp,ands,ors,nots,imod,mus,add,
            sub,mult,idiv,eq,ne,ls,le,gt,ge,ctop);  { opration code }
     instruction = packed record
                     f:opcod;
                     l:0..levmax;
                     a:0..amax;
                   end;
     item=record
             typ:types;
             ref:integer
           end;

var ch:char;           { last character read }
    sym:symbol;        { last symbol read}
    id:alfa;           { last identifier read}
    num:integer;       { last number read }
    cc:integer;        { character count }
    ll:integer;        { line length }
    kk,err:integer;
    line:string[81];
    a:alfa;
    i:integer;
    word:array[1..norw] of alfa;
    wsym:array[1..norw] of symbol;
    ssym:array[char] of symbol;
    mnemonic:array[opcod] of string[5];
    declbegsys,statbegsys,facbegsys,constbegsys,typebegsys:symset;

    nametab:array[0..txmax] of          { name table }
               record
                 name:alfa;
                 kind:
                 oobject ;
                 typ: types;
                 lev: 0..levmax;
                 normal:boolean;
                 ref:index;
                 link:index;
                 case oobject of
                   variable,prosedure:(adr:integer);
                   konstant         :(val:integer);
                   typel            :(size:integer);

               end;
    tx:  integer;           { index of nametab}


    atab:array[1..amax] of             { array information table }
              record
                inxtyp,eltyp:types;
                elref,low,high,elsize,size:index;
              end;
    ax:integer;             {index of atab }

    btab: array[0..bmax] of            { block information table }
              record
                last,lastpar,psize,vsize:index
              end;
    bx:integer;                 { index of btab }
    display:array[0..levmax] of integer;


    code:array[0..cxmax] of instruction;
    cx:integer;          { code allocation index }

    labtab:array[0..100] of integer;
    lx:integer;

    sfile:text;         { source program file }
    sfilename:string; { source program file name }
    fcode:file of instruction;
    labfile:file of integer;

    listfile :text;
    listfilename:string;
    dir:dirstr;
    name:namestr;
    ext:extstr;
{*********************************************************}

procedure initial;
begin  {init}
  word[ 1]:='and       '; word[ 2]:='array     ';
  word[ 3]:='begin     '; word[ 4]:='call      ';
  word[ 5]:='case      '; word[ 6]:='const     ';
  word[ 7]:='do        '; word[ 8]:='downto    ';
  word[ 9]:='else      '; word[10]:='end       ';
  word[11]:='for       '; word[12]:='if        ';
  word[13]:='mod       '; word[14]:='not       ';
  word[15]:='of        '; word[16]:='or        ';
  word[17]:='procedure '; word[18]:='program   ';
  word[19]:='repeat    '; word[20]:='then      '; 
  word[21]:='to        '; word[22]:='type      ';
  word[23]:='until     '; word[24]:='var       ';
  word[25]:='while     ';

  wsym[ 1]:=andsym;       wsym[ 2]:=arraysym;
  wsym[ 3]:=beginsym;     wsym[ 4]:=callsym;
  wsym[ 5]:=casesym;      wsym[ 6]:=constsym;
  wsym[ 7]:=dosym;        wsym[ 8]:=downtosym;
  wsym[ 9]:=elsesym;      wsym[10]:=endsym;
  wsym[11]:=forsym;       wsym[12]:=ifsym;
  wsym[13]:=modsym;       wsym[14]:=notsym;
  wsym[15]:=ofsym;        wsym[16]:=orsym;
  wsym[17]:=procsym;      wsym[18]:=programsym;
  wsym[19]:=repeatsym;    wsym[20]:=thensym;
  wsym[21]:=tosym;        wsym[22]:=typesym;
  wsym[23]:=untilsym;     wsym[24]:=varsym;
  wsym[25]:=whilesym;

  ssym['+']:=plus;        ssym['-']:=minus;
  ssym['*']:=times;       ssym['/']:=divsym;
  ssym['[']:=lbrack;      ssym[']']:=rbrack;
  ssym['(']:=lparen;      ssym[')']:=rparen;
  ssym['=']:=eql;         ssym[',']:=comma;
  ssym['.']:=period;
  ssym['<']:=lss;         ssym['>']:=gtr;
  ssym[';']:=semicolon;

  mnemonic[lit]:='LIT  ';   mnemonic[lod]:='LOD  ';
  mnemonic[sto]:='STO  ';   mnemonic[cal]:='CAL  ';
  mnemonic[jmp]:='JMP  ';   mnemonic[jpc]:='JPC  ';
  mnemonic[red]:='RED  ';   mnemonic[wrt]:='WRT  ';
  mnemonic[ilod]:='ILOD  '; mnemonic[loda]:='LODA ';
  mnemonic[lodt]:='LODt  '; mnemonic[lodb]:='LODB ';
  mnemonic[cpyb]:='COPYB '; mnemonic[endp]:='ENDP ';
  mnemonic[retp]:='RETP  '; mnemonic[udis]:='ADIS ';
  mnemonic[mus]:='MUS  ';   mnemonic[add]:='ADD ';
  mnemonic[sub]:='SUB  ';   mnemonic[mult]:='MULT ';
  mnemonic[idiv]:='DDIV  '; mnemonic[eq]:='EQ  ';
  mnemonic[ne]:='NE ';      mnemonic[ls]:='LS  ';
  mnemonic[le]:='LE ';      mnemonic[gt]:='GT  ';
  mnemonic[ge]:='GE ';      mnemonic[opac]:='OPAC ';
  mnemonic[entp]:='ENTP';   mnemonic[imod]:='IMOD ';
  mnemonic[ands]:='ANDS';   mnemonic[ors]:='ORS ';
  mnemonic[nots]:='NOTS';   mnemonic[ctop]:='CTOP';

  declbegsys:=[constsym,varsym,typesym,procsym];
  statbegsys:=[beginsym,callsym,ifsym,whilesym,repeatsym,forsym];
  facbegsys :=[ident,intcon,lparen,notsym,charcon];
  typebegsys:=[ident,arraysym];
  constbegsys:=[plus,minus,intcon,charcon,ident];
  err:=0; a[0]:=#10;
  display[0]:=0;
  cc:=0; cx:=0; ll:=0; ch:=' '; kk:=al; bx:=1;  tx:=-1;
  lx:=0
end;   {init}

procedure enterpreid;

  procedure enter(x0:alfa;x1:oobject;
                x2:types;x3:integer);
  begin
    tx:=tx+1;
    with nametab[tx] do
    begin
      name:=x0;link:=tx-1;kind:=x1;
      typ:=x2;ref:=0;normal:=true;
      lev:=0;
      case kind of
        variable,prosedure: adr:=x3;
        konstant:           val:=x3;
        typel:              size:=x3
      end
    end
  end;

begin  { enterprid }
  enter('          ',variable,notyp,0);       { sentinel }
  enter('char      ',typel, chars,1);
  enter('integer   ',typel,ints,  1);
  enter('boolean   ',typel,bool,  1);
  enter('false     ',konstant,bool,  0);
  enter('true      ',konstant,bool,  1);
  enter('read      ',prosedure,notyp,1);
  enter('write     ',prosedure,notyp,2);
  btab[0].last:=tx; btab[0].lastpar:=1;
  btab[0].psize:=0; btab[0].vsize:=0
end;   { enterprid }

procedure error (n:integer);
begin { error }
  writeln(listfile,'****',' ':cc-1,'^',n:2);
  err:=err+1
end;  { error }


procedure getsym;
  label 1;
  var i,k,j:integer;

  procedure getch;
  begin  { getch }
    if cc=ll then   { get character to end of line }
    { read next line }
    begin
      if eof(sfile) then
        begin
          writeln('program incomplete');
          close(sfile);
          exit;
        end;
      ll:=0; cc:=0; write(listfile,cx:4,' ');    {print code address }
      while not eoln(sfile) do
        begin
          ll:=ll+1; read(sfile,ch); write(listfile,ch);
          line[ll]:=ch
        end;
      writeln(listfile); readln(sfile);
      ll:=ll+1; line[ll]:=' '  {process end-line}
    end;
    cc:=cc+1; ch:=line[cc]
  end;   { getch }

begin  { getsym }
  1:
  while ch=' ' do getch;
  case ch of
  'a','b','c','d','e','f','g','h','i','j','k','l','m','n',
  'o','p','q','r','s','t','u','v','w','x','y','z':
    begin   { identifier or reserved word }
      k:=0;
      repeat
        if k<al then
          begin k:=k+1; a[k]:=ch  end;
        getch
      until not (ch in ['a'..'z','0'..'9']);
      if k>=kk then kk:=k      { kk: last identifier length }
      else
        repeat
          a[kk]:=' '; kk:=kk-1
        until kk=k;
      id:=a; i:=1; j:=norw; { binary search reserved word table }
      repeat
        k:=(i+j) div 2;
        if id<=word[k] then j:=k-1;
        if id>=word[k] then i:=k+1;
      until i>j;
      if i-1>j then sym:=wsym[k]
      else sym:=ident
    end;
  '0','1','2','3','4','5','6','7','8','9':
    begin { number }
      k:=0; num:=0; sym:=intcon;
      repeat
        num:=10*num+(ord(ch)-ord('0'));
        k:=k+1; getch
      until not (ch in ['0'..'9']);
      if k>nmax then error(47)
    end;
  ':':
    begin
      getch;
      if ch='=' then
        begin sym:=becomes; getch end
      else sym:=colon
    end ;
  '<':
    begin
      getch;
      if ch='=' then
        begin sym:=leq; getch end
      else
        if ch='>' then
          begin sym:=neq; getch end
        else sym:=lss
    end ;
  '>':
    begin
      getch;
      if ch='=' then
        begin sym:=geq; getch end
      else sym:=gtr
    end;
  '.':
    begin
      getch;
      if ch='.' then
        begin sym:=colon; getch end
      else sym:=period
    end;
  '''':
    begin
      getch;
      sym:=charcon;num:=ord(ch);
      getch;
      if ch='''' then getch
                 else error(48)
    end;
  '+','-','*','/','(',')','=','[',']',';',',':
    begin
      sym:=ssym[ch];
      getch
    end;
  else
    begin
      error(0); getch;
      goto 1
    end
  end  { case }
end;   { getsym }

procedure enterarray (tp:types; l,h:integer);
begin  { enterarray }
  if l>h then error(14);
  if ax=amax then
    begin
      error(2);
      writeln('too many arrays in program ');
      close(sfile);
      close(listfile);
      exit
    end
    else begin
      ax:=ax+1;
      with atab[ax] do
      begin
        inxtyp:=tp; low:=l; high:=h
      end
    end
end;   { enterarray }

procedure enterblock;
begin  { enterblock }
  if bx=bmax  then
    begin
      error(3);
      writeln('too many procedure in program ');
      close(sfile);
      close(listfile);
      exit
    end
  else begin
    bx:=bx+1; btab[bx].last:=0; btab[bx].lastpar:=0
  end
end;   { enterblock }

procedure gen (x:opcod; y,z:integer);
begin  { gen }
  if cx>cxmax then
    begin
      error(49);
      writeln('program too long');
      close(sfile);
      close(listfile);
      exit
    end;
  with code[cx] do
    begin
      f:=x; l:=y; a:=z
    end;
  cx:=cx+1
end;   { gen }

procedure test (s1,s2:symset; n:integer);
begin  { test }
  if not (sym in s1) then
    begin
      error(n); s1:=s1+s2;
      while not (sym in s1) do getsym
    end
end;   { test }

procedure block (fsys:symset; level:integer);
  type
    constrec=record
              tp:types;
              i:integer
            end;
  var dx:integer;  { data allocation index }
      tx0:integer; { initial table index }
      cx0:integer; { initial code  index }
      prt,prb:integer;

  procedure enter (k:oobject);
    var j,l:integer;
  begin  { enter }
    if tx=txmax
    then  
      begin
        error(1);
        writeln('program too long');
        close(sfile);
        close(listfile);
        exit
      end
    else begin
      nametab[0].name:=id;
      j:=btab[display[level]].last; l:=j;
      while nametab[j].name<>id do j:=nametab[j].link;
      if j<>0
      then error(l)
      else begin
        tx:=tx+1;
        with nametab[tx] do
        begin
          name:=id; link:=l;
          kind:=k;   typ:=notyp;    ref:=0;
          lev:=level;  normal:=false;
          case kind of
            variable,prosedure: adr:=0;
            konstant:           val:=0;
            typel:              size:=0
          end  { initial value }
        end;
        btab[display[level]].last:=tx
      end
    end
  end;   { enter }

  function position (id:alfa):integer;
    var i,j:integer;
  begin  { position }
    nametab[0].name:=id; j:=level;
    repeat
      i:=btab[display[j]].last;
      while nametab[i].name<>id do
        i:=nametab[i].link;
      j:=j-1
    until (j<0) or (i<>0);
    if (i=0) then error(10);
    position:=i
  end;   { position }

  procedure constant (fsys:symset; var c:constrec);
    var x,sign:integer;
  begin  { constant }
    c.tp:=notyp; c.i:=0;
    test(constbegsys,fsys,50);
    if sym in constbegsys
    then begin
      if sym=charcon then
        begin
          c.tp:=chars; c.i:=num;
          getsym
        end else
        begin
          sign:=1;
          if sym in [plus,minus] then
            begin
              if sym=minus then sign:=-1;
              getsym
            end;
          if sym=ident then
            begin
              x:=position(id);
              if x<>0
              then if nametab[x].kind<>konstant
                  then error(12)
                  else begin
                    c.tp:=nametab[x].typ;
                    c.i:=sign*nametab[x].val
                  end;
              getsym
            end 
          else if sym=intcon then
                  begin
                    c.tp:=ints; c.i:=sign*num;
                    getsym
                  end
        end;
      test(fsys,[],6)
    end
  end;   { constant }

  procedure typ (fsys:symset; var tp:types; var rf,sz:integer);
    var eltp:types;
        elrf,x:integer;
        elsz,offset,t0,t1:integer;

    procedure arraytyp (var aref,arsz:integer);
      var eltp:types;
          low,high:constrec;
          elrf,elsz:integer;

    begin  { arraytyp }
      constant([colon,rbrack,rparen,ofsym]+fsys,low);
      if (low.tp<>ints)  and (low.tp<>chars)
      then  error(50);
      if sym=colon then getsym else error(38);
      constant([rbrack,comma,rparen,ofsym]+fsys,high);
      if high.tp<>low.tp
      then begin
        error(40); high.i:=low.i;
      end;
      enterarray(low.tp,low.i,high.i);
      aref:=ax;
      if sym=comma
      then begin
        getsym;
        eltp:=arrays;
        arraytyp(elrf,elsz)
      end else begin
        if sym=rbrack
        then getsym
        else begin
          error(28);
          if sym=rparen then getsym
        end;
        if sym=ofsym then getsym else error(17);
        typ(fsys,eltp,elrf,elsz)
      end;
      with atab[aref] do
      begin
        arsz:=(high-low+1)*elsz; size:=arsz;
        eltyp:=eltp; elref:=elrf; elsize:=elsz
      end;
    end;   { arraytyp }

  begin  { typ }
    tp:=notyp; rf:=0; sz:=0;
    test(typebegsys,fsys,10);
    if sym in typebegsys
    then begin
      if sym=ident
      then begin
          x:=position(id);
          if x<>0
          then with nametab[x] do
                if kind<>typel
                then error(19)
                else begin
                  tp:=typ;rf:=ref;sz:=size;
                  if tp=notyp then error(18);
                end;
          getsym;
      end
      else if sym=arraysym
                  then  begin
                    getsym;
                    if sym=lbrack
                    then getsym
                    else begin
                      error(16);
                      if sym=lparen
                      then getsym
                    end;
                    tp:=arrays;
                    arraytyp(rf,sz)
                  end ;
        test(fsys,[],13)
    end
  end;   { typ }

  procedure paramenterlist;   {formal parameter list}
    var
      tp:types;
      valpar:boolean;
      rf,sz,x,t0:integer;

  begin  { parameterlist }
    getsym;
    tp:=notyp;rf:=0;sz:=0;
    test([ident,varsym],fsys+[rparen],7);
    while sym in [ident,varsym] do
    begin
      if sym <> varsym
        then valpar:=true
        else begin
          getsym;
          valpar:=false
        end;
        t0:=tx;
        if sym=ident
        then begin
          enter(variable);
          getsym
        end  else error(22);
        while sym=comma do
        begin
          getsym;
          if sym=ident
          then begin
            enter(variable);
            getsym
          end  else error(22);
        end;
        if sym=colon
        then begin
          getsym;
          if sym <> ident
          then error(22)
          else begin
            x :=position(id); getsym;
            if x<>0
            then with nametab[x] do
              if kind <> typel
              then error(19)
              else begin
                tp:= typ; rf:=ref;
                if valpar then sz:=size else sz:=1
              end;
          end;
          test ([semicolon,rparen],[comma,ident]+fsys,14)
        end else error(24);
        while t0 < tx do
        begin
          t0 :=t0+1;
          with nametab[t0] do
          begin
            typ :=tp;ref :=rf;
            adr :=dx;lev :=level;
            normal :=valpar;
            dx :=dx+sz
          end
        end;
        if sym <> rparen
        then begin
          if sym=semicolon
          then getsym
          else begin
            error(23);
          if sym=comma then getsym
        end;
        test([ident,varsym],[rparen]+fsys,13)
      end
    end {while};
    if sym=rparen
     then begin
       getsym;
       test([semicolon],fsys,13)
     end else error(25)
  end;   { parameterlist }


  procedure constdeclaration;
    var c:constrec;
  begin  { constdeclaration }
    if sym=ident then
      begin
        enter(konstant);
        getsym;
        if sym = eql
          then getsym
          else
            begin
              error(26);
              if sym=becomes then getsym
            end;
        constant([semicolon,comma,ident]+fsys,c);
        nametab[tx].typ:=c.tp;
        nametab[tx].ref:=0;
        nametab[tx].val:=c.i;
        if sym=semicolon then getsym else error(23)
      end
      else error(22);
    test(fsys+[ident],[],13)
  end;   { constdeclaration }

  procedure typedeclaration;
    var
      tp:types;
      rf,sz,t1:integer;

  begin  { typedeclaration }
    if sym=ident then
      begin
        enter(typel);
        t1:=tx;
        getsym;
        if sym = eql then  getsym
        else begin
            error(26);
            if sym=becomes then   getsym;
        end;
        typ ([semicolon,comma,ident]+fsys,tp,rf,sz);
        nametab[tx].typ:=tp;
        nametab[tx].ref:=rf;
        nametab[tx].size:=sz;
        if sym=semicolon then getsym else error(23)
      end
      else error(22);
    test(fsys+[ident],[],13)
  end;   { typedeclaration }


  procedure vardeclaration;
    var tp:types;
        t0,t1,rf,sz:integer;

  begin  { vardeclaration }
    if sym=ident then
      begin
        t0:=tx;
        enter(variable); getsym;
        while sym = comma do
        begin
          getsym;
          if sym =ident
          then begin
            enter(variable);getsym;
          end else error(22);
        end;
        if sym = colon then getsym else error(24);
        t1:=tx;
        typ ([semicolon,comma,ident]+fsys,tp,rf,sz);
        while t0 < t1 do
        begin
          t0:=t0+1;
          with nametab[t0] do
          begin
            typ:=tp;  ref:=rf;
            lev:=level; adr:=dx;
            normal:=true;
            dx:=dx+sz
          end
        end;
        if sym=semicolon then getsym else error(23)
      end
      else error(22);
    test(fsys+[ident],[],13)
  end;   { vardeclaration }

  procedure procdeclaration;
  begin  { procdeclaration }
    getsym;
    if sym <> ident then 
      begin
        error(22); id:=' '
      end;
    enter(prosedure);
    nametab[tx].normal:=true;
    getsym;
    block([semicolon]+fsys,level+1);
    if sym = semicolon then getsym else error(23);
  end;   { procdeclaration }

  procedure listcode;
    var i:integer;
  begin  { listcode }
    for i:=cx0 to cx-1 do
      with code[i] do
        writeln(listfile,i:4,mnemonic[f]:7,l:3,a:5)
  end;   { listcode }

  procedure statement(fsys:symset);
    var i,cx1,cx2,cx3:integer;
        x:item;
    
    procedure arrayelement(fsys:symset;var x:item); forward;
    
    procedure expression(fsys:symset;var x: item);
      var relop:symbol;
          y:item;
      procedure simpleexpression(fsys:symset;var x:item);
        var addop:symbol;
            y:item;
        procedure term(fsys:symset;var x: item);
          var mulop:symbol;
              y:item;
          
          procedure factor(fsys:symset;var x:item);
            var i:integer;
          begin  { factor }
            x.typ:=notyp;
            x.ref:=0;
            test(facbegsys,fsys,13);
            if sym in facbegsys then
            begin
              case sym of
              ident :
              begin
                i:=position(id);
                getsym;
                if i=0 then error(10)
                else
                  with nametab[i] do
                    case kind of
                      konstant: begin
                                  x.typ:=typ;
                                  x.ref:=0;
                                  gen(lit,0,val);
                                end;
                      variable:
                        begin
                          x.typ:=typ;
                          x.ref:=ref;
                          if (typ = ints) or (typ = bool) or(typ=chars)

                          then  if normal  then gen(lod,lev,adr)
                                           else gen(ilod,lev,adr)
                          else  if typ=arrays then
                               begin
                                 if normal then gen(loda,lev,adr)
                                           else gen(lod,lev,adr);
                                 if sym = lbrack
                                   then arrayelement(fsys,x);
                                 if x.typ <> arrays
                                   then gen(lodt,0,0)
                               end
                        end;
                      prosedure,typel:error(41)
                    end;
                  end ;
              intcon,charcon :
                begin
                  if sym = intcon then x.typ:=ints
                                else x.typ:=chars;
                  x.ref:=0;
                  gen(lit,0,num);
                  getsym
                end;
              lparen :
                  begin
                    getsym;
                    expression([rparen]+fsys,x);
                    if sym=rparen then getsym
                    else error(25)
                  end;
              notsym :
                  begin
                    getsym;
                    factor(fsys,x);
                    if x.typ = bool
                      then gen(nots ,0,0)
                      else error(43)
                  end;
              end ;{ case }
              test(fsys+[rbrack,rparen],facbegsys,23)
            end  { of if }
          end;   { factor }

        begin  { term }
          factor(fsys+[times,divsym,modsym,andsym],x);
          while sym in [times,divsym,modsym,andsym] do
            begin
              mulop:=sym; getsym;
              factor(fsys+[times,divsym,modsym,andsym],y);
              if x.typ<>y.typ
                then begin
                       error(40);
                       x.typ:=notyp;
                       x.ref:=0
                     end
                else
                  begin
                    if mulop=times then
                        if x.typ = ints
                          then gen(mult,0,0)
                          else error(43);
                    if  mulop=divsym then
                        if x.typ = ints
                          then gen(idiv,0,0)
                          else error(43);
                    if  mulop=modsym then
                        if x.typ = ints
                          then gen(imod,0,0)
                          else error(43);
                    if  mulop=andsym then
                      if x.typ = bool
                          then gen(ands,0,0)
                          else error(43)
            end
          end
        end;   { term }

      begin  { simpleexpression }
        if sym in [plus,minus] then
          begin
            addop:=sym; getsym;
            term(fsys+[plus,minus,orsym],x);
            if addop=minus then gen(mus,0,0)
          end  else term(fsys+[plus,minus,orsym],x);
        while sym in [plus,minus,orsym] do
          begin addop:=sym; getsym;
                term(fsys+[plus,minus,orsym],y);
                if x.typ<>y.typ
                then begin
                       error(40);
                       x.typ:=notyp;
                       x.ref:=0
                     end
                else
                  begin
                    if addop=plus then
                        if x.typ = ints
                          then gen(add,0,0)
                          else error(43);
                    if  addop=minus then
                        if x.typ = ints
                          then gen(sub,0,0)
                          else error(43);
                    if  addop=orsym then
                      if x.typ = bool
                          then gen(ors,0,0)
                          else error(43)
                 end
            end
      end;   { simpleexpression }

    begin  { expression }
      simpleexpression([eql,neq,lss,gtr,leq,geq]+fsys,x);
      while (sym in [eql,neq,lss,leq,gtr,geq]) do
        begin
          relop:=sym; getsym; simpleexpression(fsys,y);
          if x.typ<> y.typ
            then error(40);
          case relop of
            eql:gen(eq,0,0);
            neq:gen(ne,0,0);
            lss:gen(ls,0,0);
            geq:gen(ge,0,0);
            gtr:gen(gt,0,0);
            leq:gen(le,0,0)
          end;
          x.typ:=bool
        end
    end;   { expression }

    procedure arrayelement(fsys:symset;var x:item);
      var cc:integer;
          addr,p:index;
          y:item;

    begin  { arrayelement }
      p:=x.ref;
      if sym=lbrack then
        begin
          repeat
            getsym;
            expression(fsys+[comma],y);
            if x.typ <> arrays then error(40)
            else
              begin
                if y.typ <> atab[p].inxtyp then error(44);
                gen(lit,0,atab[p].low);
                gen(sub,0,0);
                gen(lit,1,atab[p].elsize);
                gen(mult,0,0);
                gen(add,0,0);
                x.typ:=atab[p].eltyp;
                x.ref:=atab[p].elref;
                p:=atab[p].elref;
              end
          until sym <> comma;

          if sym=rbrack then getsym else error(28);
        end else error(16);
      test(fsys,[],13);
    end;   { arrayelement }

    procedure assignment;
      var x,y:item;
    begin  { assignment }
      i:=position(id);
      if i=0 then error(10)
      else
        if nametab[i].kind<>variable then
          begin  { giving value to non-variation }
            error(30);  i:=0
          end;
      getsym;
      x.typ:=nametab[i].typ;
      x.ref:=nametab[i].ref;
      with nametab[i] do
        if normal
          then gen(loda,lev,adr)
          else gen(lod,lev,adr);
      if sym = lbrack
          then arrayelement(fsys+[becomes],x);
      if sym=becomes then getsym
            else begin
                   error(33);
                   if sym=eql then getsym
                 end;
       expression(fsys,y);
       if x.typ <> y.typ then error(40)
       else
         if x.typ = arrays
           then if x.ref = y.ref
                   then gen(cpyb,0,atab[x.ref].size)
                else error(40)
         else gen(sto,0,0);
    end;   { assignment }

    procedure copycode(s,e:integer);
      var ptr:integer;
    begin
        for ptr:= s to e do
            with code[ptr] do
                gen(f,l,a)
    end;

    procedure forstatement;
      var x,y:item;
          adval,cx4: integer;
          judgecod: opcod;
    begin  { forstatement }
      cx1 := cx; { calculate address start }
      getsym;
      i:=position(id);
      if i=0 then error(10)
      else if nametab[i].kind <> variable then 
             begin
               error(30); i := 0
             end;
      getsym;
      x.typ:=nametab[i].typ; x.ref:=nametab[i].ref;
      with nametab[i] do
        if normal then gen(loda, lev, adr)
        else gen(lod, lev, adr);
      if sym = lbrack then
        arrayelement(fsys+[becomes],x);

      if x.typ <> ints then error(78); { var should be ints }
      
      if sym = becomes then getsym
      else begin
        error(33);
        if sym=eql then getsym
      end;


      cx2 := cx-1; { calculate address end }

      expression(fsys + [tosym, downtosym], y); { var := expression }
      if x.typ <> y.typ then error(40)
      else gen(sto, 0, 0);
      

      copycode(cx1, cx2);
      gen(lodt, 0, 0);
      
      cx3 := cx; { for code start here  }

      adval := 1;
      judgecod := le;
      if sym <> tosym then
        if sym <> downtosym then
          error(79)
        else begin
          adval := -1;
          judgecod := ge
        end;
      
      getsym;
      expression(fsys + [dosym], y);
      if x.typ <> y.typ then error(40);
      
      gen(judgecod, 0, 0);
      cx4 := cx;
      gen(jpc, 0, 0);

      if sym <> dosym then error (79);
      
      getsym;
      statement(fsys);

      copycode(cx1, cx2);
      gen(ctop, 0, 0);
      gen(ctop, 0, 0);
      gen(lodt, 0, 0);
      gen(lit, 0, adval);
      gen(add, 0, 0);
      gen(sto, 0, 0);
      gen(lodt, 0, 0);
      
      gen(jmp, 0, cx3);
      code[cx4].a := cx;
    end;   { forstatement } 

    procedure ifstatement;
      var x:item;
    begin  { ifstatement }
      getsym; expression([thensym,dosym]+fsys,x);
      if x.typ <> bool then error(34);
      if sym=thensym then getsym else error(35);
      cx1:=cx; gen(jpc,0,0);
      statement(fsys+[elsesym]);
      if sym = elsesym
        then  begin
          getsym;
          cx2:=cx; gen(jmp,0,0);
          code[cx1].a:=cx;
          labtab[lx]:=cx;lx:=lx+1;
          statement(fsys);
          code[cx2].a:=cx;
          labtab[lx]:=cx;lx:=lx+1;
        end
        else
          begin
            code[cx1].a:=cx;
            labtab[lx]:=cx;lx:=lx+1;
          end
    end;   { ifstatement }

    procedure compound;
    begin  { compound }
      getsym; statement([semicolon,endsym]+fsys);
      while sym in ([semicolon]+statbegsys) do
      begin
        if sym=semicolon then getsym else error(23);
        statement([semicolon,endsym]+fsys)
      end;
      if sym=endsym then getsym else error(36)
    end;   { compound }

    procedure whilestatement;
      var x:item;
    begin
      getsym;
      labtab[lx]:=cx;lx:=lx+1;
      cx1:=cx; expression([dosym]+fsys,x);
      if x.typ <> bool then error(34);
      cx2:=cx; gen(jpc,0,0);
      if sym=dosym then getsym else error(37);
      statement(fsys); gen(jmp,0,cx1); code[cx2].a:=cx;
      labtab[lx]:=cx;lx:=lx+1
    end;

    { add repeat until }
    procedure repeatstatement;
      var x:item;
    begin  { repeatstatement }
      getsym;
      labtab[lx]:=cx;lx:=lx+1;
      cx1:=cx;
      statement(fsys + [untilsym]);
      
      if sym=untilsym then getsym else error(77);

      expression(fsys, x);
      if x.typ <> bool then error(34);
      gen(jpc,0,cx1);
      labtab[lx]:=cx;lx:=lx+1;
    end;  { repeatstatement }
      

    procedure call;
      var x:  item;
          lastp,cp,i,j,k:integer;

      procedure stanproc(i:integer);
        var n:integer;
      begin  { standproc }
        if i =6  then
          begin    { read }
            getsym;
            if sym=lparen then
            begin
              repeat
                getsym;
                if sym=ident then
                  begin
                    n:=position(id); getsym;
                    if n=0 then error(10)
                      else
                        if nametab[n].kind<>variable then
                          begin error(30); n:=0 end
                        else
                          begin
                            x.typ:=nametab[n].typ;
                            x.ref:=nametab[n].ref;
                            if nametab[n].normal
                              then gen(loda,nametab[n].lev,nametab[n].adr)
                              else gen(lod,nametab[n].lev,nametab[n].adr);
                            if sym = lbrack
                              then arrayelement(fsys+[comma],x);
                            if x.typ = ints
                              then gen(red,0,0)
                              else if x.typ = chars
                                     then gen(red,0,1)
                                     else error(43)
                          end
                  end
                  else error(22)
                until sym<>comma;
                if sym<>rparen then error(25)
                                 else  getsym
              end
              else error(32)
            end
            else
              if i = 7 then
                begin        { write }
                  getsym;
                  if sym=lparen then
                    begin
                      repeat
                        getsym;
                        expression([rparen,comma]+fsys,x);
                        if x.typ = ints
                          then gen(wrt,0,0)
                          else if x.typ = chars
                                 then gen(wrt,0,1)
                                 else error(43)
                      until sym<>comma;
                      if sym<>rparen then error(25);
                      getsym
                    end
                  else error(32)
               end
      end;   { standproc }

    begin  { call }
      getsym;
      if sym = ident  then
      begin
        i:=position(id);
        if nametab[i].kind = prosedure then
        begin
          if nametab[i].lev = 0 then stanproc(i)
          else begin
            getsym;
            gen(opac,0,0);  {open active record}
            lastp :=btab[nametab[i].ref].lastpar;
            cp :=i;
            if sym=lparen
            then begin {actual parameter list}
              repeat
                getsym;
                if cp>=lastp
                then error(29)
                else begin
                  cp :=cp+1;
                  if nametab[cp].normal  then
                  begin {value parameter}
                    expression(fsys+[comma,colon,rparen],x);
                    if x.typ = nametab[cp].typ then
                      begin
                        if x.ref <> nametab[cp].ref
                          then error(31)
                          else if x.typ = arrays
                                 then gen(lodb,0,atab[x.ref].size)
                      end
                    else error(31)
                  end else begin {variable parameter}
                    if sym <> ident
                    then error(22)
                    else begin
                      k:=position(id);
                      getsym;
                      if k<>0
                      then begin
                        if nametab[k].kind<>variable then error (30);
                        x.typ :=nametab[k].typ;
                        x.ref :=nametab[k].ref;
                        if nametab[k].normal
                        then gen(loda,nametab[k].lev,nametab[k].adr)
                        else gen(lod,nametab[k].lev,nametab[k].adr);
                        if sym = lbrack
                          then  arrayelement(fsys+[comma,rparen],x);
                        if    (nametab[cp].typ<>x.typ)
                          or (nametab[cp].ref<>x.ref)
                           then error(31);
                      end
                    end
                  end {variable parameter}
                end;
                test([comma,rparen],fsys,13)
              until sym <> comma;
              if sym=rparen then getsym  else error(25)
            end;
            if cp < lastp then error(39);{too few actual parameters}
            gen(cal,nametab[i].lev,nametab[i].adr);
            if nametab[i].lev<level then gen(udis,nametab[i].lev,level)
          end
        end else error(51)
      end else error(22);
      test(fsys+[ident],[],13)
    end;   { call }

  begin  { statement }
    test(statbegsys+[ident],fsys,13);
    if sym=ident then  assignment
    else if sym=callsym then call
    else   if sym=ifsym then  ifstatement
    else   if sym=beginsym then compound
    else    if sym=whilesym then whilestatement
    else    if sym=repeatsym then repeatstatement
    else    if sym=forsym then forstatement;
    test(fsys+[elsesym],[],13)
  end;   { statement }

begin  { block }
  prt:=tx;
  dx:=3; tx0:=tx; nametab[tx].adr:=cx;
  if level > levmax then error(4);
  enterblock ;
  prb:=bx;  display[level]:=bx;
  nametab[prt].typ:=notyp;  nametab[prt].ref:=prb;

  if(sym=lparen) and (level>1)
    then
      begin
        paramenterlist;
        if sym=semicolon then getsym
                         else error(23)
      end
    else  if level>1 then
            if sym=semicolon then getsym
                          else error(23);
  btab[prb].lastpar:=tx;
  btab[prb].psize:=dx;

  gen(jmp,0,0);  { jump from declaration part to statement part }
  repeat
    if sym=constsym then
      begin
        getsym;
        repeat
          constdeclaration;
        until sym<>ident
      end;
    if sym=typesym then
      begin
        getsym;
        repeat
          typedeclaration;
        until sym<>ident
      end;
    if sym=varsym then
      begin
        getsym;
        repeat
          vardeclaration;
        until sym<>ident;
      end;
    while sym=procsym do   procdeclaration;
    test(statbegsys+[ident],declbegsys,13)
  until not (sym in declbegsys);
  code[nametab[tx0].adr].a:=cx;  {back enter statement code's start adr. }
  labtab[lx]:=cx;lx:=lx+1;
  with nametab[tx0] do
    begin
      adr:=cx;  {code's start address }
    end;
  cx0:=cx;
  gen(entp,level,dx);  { block entry }
  statement([semicolon,endsym]+fsys);
  if level>1 then gen(retp,0,0)  {return}
             else gen(endp,0,0);  { end prograam }
  test(fsys,[],13);
  listcode;
end;   { block }

{************************************************************************}
begin  { main }
  writeln('Please input source program file name:');
  readln(sfilename);
  assign(sfile,sfilename);
  reset(sfile);

  fsplit(sfilename,dir, name,ext);
  listfilename:=dir +name+'.LST';
  assign(listfile,listfilename);
  rewrite(listfile);

  initial;
  enterpreid;
  getsym;
  if sym = programsym then
    begin
      getsym;
      if sym = ident then
        begin
          getsym;
          if sym = semicolon then getsym
          else error(23)
        end
        else error(22)
    end
    else error(15);
    test(declbegsys+[beginsym],[],13);
  block([period]+declbegsys+statbegsys,1);
  if sym<>period then error(38);
  if err=0 then
      begin
       write('SUCCESS');
       assign(fcode,dir+name+'.pld');
       rewrite(fcode);
       for i:=0 to cx do
         write(fcode,code[i]);
       close(fcode);
       assign(labfile,dir+name+'.lab');
       rewrite(labfile);
       for i:=0 to lx do
         write(labfile,labtab[i]);
       close(labfile)
      end
  else write(err,'ERRORS IN PROGRAM');
  writeln;
  close(sfile);
  close(listfile)
end.   { of whole program  }
