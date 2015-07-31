{Sample of how to create a very basic assembler tool, using the unit pic16utils.}
unit Unit1;
{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  pic16utils;

type
  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    pic: TPIC16;
    function CaptureComma(var lin: string): boolean;
    function ExtractNumber(var lin: string; var num: word): boolean;
    function ExtractString(var lin: string; var str: string): boolean;
  end;

var
  Form1: TForm1;

implementation
{$R *.lfm}
{ TForm1 }

function TForm1.ExtractString(var lin: string; var str: string): boolean;
var
  tmp: String;
  i: Integer;
begin
  Result := true;
  lin := trim(lin);    //trim
  tmp := '';
  i:=1;
  while lin[i] in ['a'..'z','A'..'Z'] do begin
    tmp += lin[i];
    inc(i);
  end;
  lin := copy(lin,i,100);
  lin := trim(lin);    //trim
  str := tmp;
end;

function TForm1.ExtractNumber(var lin: string; var num: word): boolean;
var
  tmp: String;
  i: Integer;
begin
  Result := true;
  lin := trim(lin);    //trim
  tmp := '';
  i:=1;
  while lin[i] in ['0'..'9','x','X'] do begin
    tmp += lin[i];
    inc(i);
  end;
  lin := copy(lin,i,100);
  lin := trim(lin);    //trim
  if LowerCase( copy(tmp,1,2)) = '0x' then
     num := StrToInt('$' + copy(tmp,3,100))
  else
     num := StrToInt(tmp);
end;
function TForm1.CaptureComma(var lin: string): boolean;
begin
  Result := true;
  lin := trim(lin);    //trim
  if lin='' then begin
    Application.MessageBox('Expected comma.','');
    Result := false;
    exit;
  end;
  if lin[1]<>',' then begin
    Application.MessageBox('Expected comma.','');
    Result := false;
    exit;
  end;
  lin := copy(lin,2,100);
  lin := trim(lin);    //trim
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  l: String;
  idInst: TPIC16Inst;
  Inst: String;
  found: Boolean;
  stx: String;
  f, k, b: word;
begin
  pic.CleanMemFlash;
  pic.iFlash:=0;      //for start to code at $0000
  for l in Memo1.Lines do begin
    if not ExtractString(l, Inst) then begin  //extract mnemonic
      Application.MessageBox('Syntax Error','');
      exit;
    end;
    //find mnemonic
    found := false;
    for idInst := low(TPIC16Inst) to high(TPIC16Inst) do begin
      if PIC16InstName[idInst] = UpperCase(Inst) then begin
        found := true;
        break;
      end;
    end;
    if not found then begin
      Application.MessageBox(PChar('Invalid Opcode: '+ Inst),'');
      exit;
    end;
    //Found. Load syntax
    stx := PIC16InstSyntax[idInst];
    case stx of
    'fd': begin
       if not ExtractNumber(l,f) then exit;
       if not CaptureComma(l) then exit;
       if (l <> 'f') and (l<>'d') then begin
         Application.MessageBox('Syntax Error','');
         exit;
       end;
       if l='f' then
          pic.codAsm(idInst, f, toF)
       else
          pic.codAsm(idInst, f, toW);
    end;
    'f':begin
       if not ExtractNumber(l,f) then exit;
       if l <> '' then begin
         Application.MessageBox('Syntax Error','');
         exit;
       end;
       pic.codAsm(idInst, f, toW);  //"toW" no used.
    end;
    'fb':begin
       if not ExtractNumber(l,f) then exit;
       if not CaptureComma(l) then exit;
       if not ExtractNumber(l,b) then exit;
       if l <> '' then begin
         Application.MessageBox('Syntax Error','');
         exit;
       end;
       pic.codAsm(idInst, f, b);  //"b" no used.
    end;
    'k': begin
       if not ExtractNumber(l,k) then exit;
       if l <> '' then begin
         Application.MessageBox('Syntax Error','');
         exit;
       end;
       pic.codAsm(idInst, k);  //"toW" no used.
    end;
    '': begin
      if l <> '' then begin
        Application.MessageBox('Syntax Error','');
        exit;
      end;
      pic.codAsm(idInst);  //"toW" no used.
    end;
    end;
  end;
  pic.GenHex(Application.ExeName + '.hex');
  Memo2.Lines.LoadFromFile(Application.ExeName + '.hex');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  pic := TPIC16.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  pic.Destroy;
end;

end.
