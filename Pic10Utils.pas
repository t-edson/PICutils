{
Description
===========
Utilities for programming Baseline PIC microcontrollers with 12 bits instructions.
Include most of the PIC10 devices.
This unit works with 512 words pages and 32 bytes RAM banks.
The main class TPIC16 must model all devices of this serie.

}

unit Pic10Utils;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, LCLProc, PicCore;
const
  PIC_BANK_SIZE = 32;  //Tamaño del banco de RAM
  PIC_MAX_RAM   = PIC_BANK_SIZE * 8;  //Máx RAM memory (8 banks)
  PIC_PAGE_SIZE = 512;
  PIC_MAX_FLASH = PIC_PAGE_SIZE * 4; //Máx Flash memeory (4 pages)
  PIC_MAX_PINES = 28;   //Máxima cantidad de pines para el encapsulado
type  //Baseline PIC instructions
  TPIC10Inst = (
    //BYTE-ORIENTED FILE REGISTER OPERATIONS
    i_ADDWF,
    i_ANDWF,
    i_CLRF,
    i_CLRW,
    i_COMF ,
    i_DECF ,
    i_DECFSZ,
    i_INCF,
    i_INCFSZ,
    i_IORWF,
    i_MOVF,
    i_MOVWF,
    i_NOP,
    i_RLF,
    i_RRF,
    i_SUBWF,
    i_SWAPF,
    i_XORWF,
    //BIT-ORIENTED FILE REGISTER OPERATIONS
    i_BCF,
    i_BSF,
    i_BTFSC,
    i_BTFSS,
    //LITERAL AND CONTROL OPERATIONS
    //i_ADDLW,
    i_ANDLW,
    i_CALL,
    i_CLRWDT,
    i_GOTO,
    i_IORLW,
    i_MOVLW,
    i_RETLW,
    i_SLEEP,
    //i_SUBLW,
    i_XORLW,
    i_OPTION,
    i_TRIS,
    //EXTENDED INSTRCUTIONS (Only for some Models)
    i_MOVLB,
    i_RETURN,
    i_RETFIE,
    //INVALID INSTRUCTION
    i_Inval
  );
  //Indica el destino de la instrucción
  TPICBaseDestin = (
    toW = %000000,    //al acumulador
    toF = %100000     //a memoria
  );


type //Modelo de la memoria RAM
  TPICBaseRam = array[0..PIC_MAX_RAM-1] of TPICRamCell;
  TPICBaseRamPtr = ^TPICBaseRam;
  TPICBaseRutExplorRAM = procedure(offs, bnk: byte; regPtr: TPICRamCellPtr) of object;
  {Representa a un banco de memoria del PIC. En un banco las direcciones de memoria
   se mapean siempre desde $00 hasta $7F. No almacenan datos, solo usan referencias.}
  { TPICRAMBank }
  TPICRAMBank = object
  public
    numBank   : integer;       //Número de banco
    ramPtr    : TPICBaseRamPtr;  //Puntero a memoria RAM
    AddrStart : word;          //dirección de inicio en la memoria RAM total
  public
    procedure Init(num: byte; AddrStart0: word; ram0: TPICBaseRamPtr);  //inicia objeto
  end;

type  //Models for Flash memory
  TPICBaseFlash = array[0..PIC_MAX_FLASH-1] of TPICFlashCell;
  TPICBaseFlashPtr = ^TPICBaseFlash;

  {Representa a una página de memoria del PIC. En una página las direcciones de memoria
   se mapean siempre desde $000 hasta $800. No almacenan datos, solo usan referencias.}
  TPICBaseFlashPagePtr = ^TPICBaseFlashPage;
  { TPICBaseFlashPage }
  TPICBaseFlashPage = object
  private
    flash    : TPICBaseFlashPtr;  //puntero a memoria Flash
    AddrStart: word;           //dirección de inicio en la memoria flash total
  private
    function Getmem(i : word): TPICFlashCell;
    procedure Setmem(i : word; AValue: TPICFlashCell);
  public
    procedure Init(AddrStart0: word; flash0: TPICBaseFlashPtr);  //inicia objeto
    property mem[i : word] : TPICFlashCell read Getmem write Setmem;
    //funciones para administración de la memoria
    function Total: word; //total de bytes que contiene
  end;

type
  {Objeto que representa al hardware de un PIC de la serie 16}
  { TPICBase }
  TPICBase = class(TPicCore)
  private  //Creación de archivo *.hex
    minUsed  : word;         //Dirección menor de la ROM usada
    maxUsed  : word;         //Dirección mayor de la ROM usdas
    function StrHexFlash(i1, i2: integer): string;
  public  //Campos para procesar instrucciones
    idIns: TPIC10Inst;    //ID de Instrucción.
    d_   : TPICBaseDestin;  //Destino de operación. Válido solo en algunas instrucciones.
    f_   : byte;          //Registro destino. Válido solo en algunas instrucciones.
    b_   : byte;          //Bit destino. Válido solo en algunas instrucciones.
    k_   : word;          //Parámetro Literal. Válido solo en algunas instrucciones.
  private //Campos para procesar instrucciones
    FMaxFlash: integer;
    function GetBank(i : Longint): TPICRAMBank;
    function GetINTCON: byte;
    function GetINTCON_GIE: boolean;
    function GetPage(i : Longint): TPICBaseFlashPage;
    function GetSTATUS: byte;
    function GetSTATUS_C: boolean;
    function GetSTATUS_DC: boolean;
    function GetSTATUS_IRP: boolean;
    function GetSTATUS_Z: boolean;
    procedure SetINTCON_GIE(AValue: boolean);
    procedure SetSTATUS_C(AValue: boolean);
    procedure SetSTATUS_DC(AValue: boolean);
    procedure SetSTATUS_IRP(AValue: boolean);
    procedure SetSTATUS_Z(AValue: boolean);
    procedure SetMaxFlash(AValue: integer);
    procedure SetFRAM(value: byte);
    function GetFRAM: byte;
  public   //Campos que modelan a los registros internos
    W        : byte;   //Registro de trabajo
    PCL      : byte;   //Contador de Programa L
    PCH      : byte;   //Contador de Programa H
    //pc     : word absolute PCL. //Se debería optimziar así, viendo compatib. en el hardware
    PCLATH   : byte;   //Contador de Programa H
    STKPTR   : 0..7;   //Puntero de pila
    STACK    : array[0..7] of word;
    OPTION   : byte;   //In Baseline PICs, this register is internal
    TRISA    : byte;   //In Baseline PICs, this register is internal
    TRISB    : byte;   //In Baseline PICs, this register is internal (Only exists for some devices)
    TRISC    : byte;   //In Baseline PICs, this register is internal (Only exists for some devices)
    BSR      : byte;   //In Baseline PICs, this register is internal (Only exists for some devices)
    pines    : array[1..PIC_MAX_PINES] of TPICPin;
    property STATUS: byte read GetSTATUS;
    property STATUS_Z: boolean read GetSTATUS_Z write SetSTATUS_Z;
    property STATUS_C: boolean read GetSTATUS_C write SetSTATUS_C;
    property STATUS_DC: boolean read GetSTATUS_DC write SetSTATUS_DC;
    property STATUS_IRP: boolean read GetSTATUS_IRP write SetSTATUS_IRP;
    property INTCON: byte read GetINTCON;
    property INTCON_GIE: boolean read GetINTCON_GIE write SetINTCON_GIE;
    property FRAM: byte read GetFRAM write SetFRAM;
  public   //Control de ejecución
    nClck : Int64;  //Contador de ciclos de reloj
    CommStop: boolean;  //Bandera para detener la ejecución
    OnExecutionMsg: procedure(message: string) of object;  //Genera mensaje en ejecución
    function CurInstruction: TPIC10Inst;
    procedure Exec(pc: word);  //Ejecuta la instrucción en la dirección indicada.
    procedure Exec();  //Ejecuta instrucción actual
    procedure ExecTo(endAdd: word);  //Ejecuta hasta cierta dirección
    procedure ExecNCycles(nCyc: integer; out stopped: boolean);  //Ejecuta hasta cierta dirección
    procedure Reset;
    procedure AddBreakopint(pc: word);
    procedure ToggleBreakopint(pc: word);
  public   //Memorias
    flash    : TPICBaseFlash;   //memoria Flash
    ram      : TPICBaseRam;     //memoria RAM
    //Propiedades que definen la arquitectura del PIC destino.
    NumBanks: byte;      //Número de bancos de RAM.
    NumPages: byte;      //Número de páginas de memoria Flash.
    bank0, bank1, bank2, bank3: TPICRAMBank;  //bancos de memoria RAM
    page0, page1, page2, page3: TPICBaseFlashPage;  //páginas de memoria Flash
    iFlash: integer;   //puntero a la memoria Flash, para escribir
    MsjError: string;
    procedure Decode(const opCode: word);  //decodifica instrucción
    function Disassembler(const opCode: word; bankNum: byte = 255;
      useVarName: boolean = false): string;  //Desensambla la instrucción actual
    property banks[i : Longint]: TPICRAMBank Read GetBank;
    property pages[i : Longint]: TPICBaseFlashPage Read GetPage;
    property MaxFlash: integer read FMaxFlash write SetMaxFlash;   {Máximo número de celdas de flash implementadas (solo en los casos de
                         implementación parcial de la Flash). Solo es aplicable cuando es mayor que 0}
  public  //Funciones para la memoria RAM
    function HaveConsecGPR(const i, n: word; maxRam: word): boolean; //Indica si hay "n" bytes libres
    procedure UseConsecGPR(const i, n: word);  //Ocupa "n" bytes en la posición "i"
    function GetFreeBit(out addr: word; out bit: byte; shared: boolean): boolean;
    function GetFreeByte(out addr: word; shared: boolean): boolean;
    function GetFreeBytes(const size: integer; var addr: word): boolean;  //obtiene una dirección libre
    function TotalMemRAM: word; //devuelve el total de memoria RAM
    function UsedMemRAM: word;  //devuelve el total de memoria RAM usada
    procedure ExploreUsed(rutExplorRAM: TPICBaseRutExplorRAM);    //devuelve un reporte del uso de la RAM
    function ValidRAMaddr(addr: word): boolean;  //indica si una posición de memoria es válida
    procedure ClearMemRAM;
    procedure DisableAllRAM;
    procedure SetStatRAM(i1, i2: word; status0: TPICCellState);
    procedure SetMappRAM(i1, i2: word; MappedTo: word);
    function SetStatRAMCom(strDef: string): boolean;
    function SetMappRAMCom(strDef: string): boolean;
    function MapRAMtoPIN(strDef: string): boolean;
    procedure SetPin(pNumber: integer; pLabel: string; pType: TPICPinType);
    function SetUnimpBITS(strDef: string): boolean;
    function BankToAbsRAM(const offset, bank: byte): word; //devuelve dirección absoluta
    procedure AbsToBankRAM(const AbsAddr: word; var offset, bank: byte); //convierte dirección absoluta
    //funciones para manejo de nombres
    function NameRAM(const addr: word; const bnk: byte): string;
    function NameRAMbit(const addr: word; const bnk,bit: byte): string;
    procedure SetNameRAM(const addr: word; const nam: string);  //Fija nombre a una celda de RAM
    procedure AddNameRAM(const addr: word; const bnk: byte; const nam: string);  //Agrega nombre a una celda de RAM
    procedure SetNameRAMbit(const addr: word; const bit: byte; const nam: string);  //Fija nombre a un bitde RAM
  public  //Funciones para la memoria Flash
    function UsedMemFlash: word;  //devuelve el total de memoria Flash usada
    procedure ClearMemFlash;
    procedure SetSharedUnused;
    procedure SetSharedUsed;
  public  //Métodos para codificar instrucciones de acuerdo a la sintaxis
    procedure useFlash;
    procedure codAsmFD(const inst: TPIC10Inst; const f: word; d: TPICBaseDestin);
    procedure codAsmF(const inst: TPIC10Inst; const f: word);
    procedure codAsmFB(const inst: TPIC10Inst; const f: word; b: byte);
    procedure codAsmK(const inst: TPIC10Inst; const k: byte);
    procedure codAsmA(const inst: TPIC10Inst; const a: word);
    procedure codAsm(const inst: TPIC10Inst);
    procedure codGotoAt(iflash0: integer; const k: word);
    procedure codCallAt(iflash0: integer; const k: word);
    function codInsert(iflash0, nInsert, nWords: integer): boolean;
  public  //Métodos adicionales
    function FindOpcode(Op: string; var syntax: string): TPIC10Inst;  //busca Opcode
    procedure addTopLabel(lbl: string);  //Add a comment to the ASM code
    procedure addTopComm(comm: string; replace: boolean = true);  //Add a comment to the ASM code
    procedure addSideComm(comm: string; before: boolean); //Add lateral comment to the ASM code
    procedure addPosInformation(rowSrc, colSrc: word; idFile: byte);
    procedure GenHex(hexFile: string; ConfigWord: integer = - 1);  //genera un archivo hex
    procedure DumpCode(lOut: TStrings; incAdrr, incCom, incVarNam: boolean);  //vuelva en código que contiene
  public  //Initialization
    constructor Create; override;
    destructor Destroy; override;
  end;

var  //variables globales
  //mnemónico de las instrucciones
  PIC16InstName: array[low(TPIC10Inst)..high(TPIC10Inst)] of string[7];
  //sintaxis en ensamblador de las instrucciones
  PIC16InstSyntax: array[low(TPIC10Inst)..high(TPIC10Inst)] of string[5];

implementation

{ TPICRAMBank }
//procedure TPICRAMBank.Setmem(i: byte; AValue: TPICRamCellPtr);
////Escribe en un banco de memoria
//begin
//  //Se asume que i debe ser menor que $7F
//  if ram^[i+AddrStart].state = cs_mapToBnk then begin
//    //estas direcciones están mapeadas en otro banco
//    BankMapped^.mem[i] := AValue;
//  end else begin  //caso normal
//    ram^[i+AddrStart] := AValue;
//  end;
//end;
procedure TPICRAMBank.Init(num: byte; AddrStart0: word;
  ram0: TPICBaseRamPtr);
begin
  numBank := num;
  AddrStart :=AddrStart0;
  ramPtr       :=ram0;
end;
{ TPICBaseFlashPage }
function TPICBaseFlashPage.Getmem(i: word): TPICFlashCell;
begin
  //Se asume que i debe ser menor que $800
  Result := flash^[i+AddrStart];
end;
procedure TPICBaseFlashPage.Setmem(i: word; AValue: TPICFlashCell);
begin
  flash^[i+AddrStart] := AValue;
end;
procedure TPICBaseFlashPage.Init(AddrStart0: word; flash0: TPICBaseFlashPtr);
begin
  AddrStart :=AddrStart0;
  flash     :=flash0;
end;
function TPICBaseFlashPage.Total: word;
begin
  Result := PIC_PAGE_SIZE;  //tamaño fijo
end;

{ TPICBase }
procedure TPICBase.useFlash;
{Marca la posición actual, como usada, e incrementa el puntero iFlash. S ihay error,
actualiza el campo "MsjError"}
begin
  //Protección de desborde
  if iFlash > MaxFlash then begin
    MsjError := 'FLASH Memory limit exceeded.';
    exit;
  end;
  flash[iFlash].used := true;  //marca como usado
  inc(iFlash);
end;
procedure TPICBase.codAsmFD(const inst: TPIC10Inst; const f: word; d: TPICBaseDestin);
{Codifica las instrucciones orientadas a registro, con sinatxis: NEMÓNICO f,d}
begin
  case inst of
  i_ADDWF : flash[iFlash].value := %000111000000 + ord(d) + (f and %11111);
  i_ANDWF : flash[iFlash].value := %000101000000 + ord(d) + (f and %11111);
  i_COMF  : flash[iFlash].value := %001001000000 + ord(d) + (f and %11111);
  i_DECF  : flash[iFlash].value := %000011000000 + ord(d) + (f and %11111);
  i_DECFSZ: flash[iFlash].value := %001011000000 + ord(d) + (f and %11111);
  i_INCF  : flash[iFlash].value := %001010000000 + ord(d) + (f and %11111);
  i_INCFSZ: flash[iFlash].value := %001111000000 + ord(d) + (f and %11111);
  i_IORWF : flash[iFlash].value := %000100000000 + ord(d) + (f and %11111);
  i_MOVF  : flash[iFlash].value := %001000000000 + ord(d) + (f and %11111);
  i_RLF   : flash[iFlash].value := %001101000000 + ord(d) + (f and %11111);
  i_RRF   : flash[iFlash].value := %001100000000 + ord(d) + (f and %11111);
  i_SUBWF : flash[iFlash].value := %000010000000 + ord(d) + (f and %11111);
  i_SWAPF : flash[iFlash].value := %001110000000 + ord(d) + (f and %11111);
  i_XORWF : flash[iFlash].value := %000110000000 + ord(d) + (f and %11111);
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codAsmF(const inst: TPIC10Inst; const f: word);
{Codifica las instrucciones orientadas a registro, con sinatxis: NEMÓNICO f}
begin
  case inst of
  i_CLRF  : flash[iFlash].value := %000001100000 + (f and %11111);
  i_MOVWF : flash[iFlash].value := %000000100000 + (f and %11111);
  i_TRIS  : flash[iFlash].value := %000000000000 + (f and %1111); //Only valid if f=5,6,7,8,9
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codAsmFB(const inst: TPIC10Inst; const f: word; b: byte);
//Codifica las instrucciones orientadas a bit.
begin
  case inst of
  i_BCF  : flash[iFlash].value := %010000000000 + word(b<<5) + (f and %11111);
  i_BSF  : flash[iFlash].value := %010100000000 + word(b<<5) + (f and %11111);
  i_BTFSC: flash[iFlash].value := %011000000000 + word(b<<5) + (f and %11111);
  i_BTFSS: flash[iFlash].value := %011100000000 + word(b<<5) + (f and %11111);
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codAsmK(const inst: TPIC10Inst; const k: byte);
{Codifica las instrucciones con constantes.}
begin
  case inst of
  i_ANDLW : flash[iFlash].value := %111000000000 + k;
  i_IORLW : flash[iFlash].value := %110100000000 + k;
  i_MOVLW : flash[iFlash].value := %110000000000 + k;
  i_RETLW : flash[iFlash].value := %100000000000 + k;
  i_XORLW : flash[iFlash].value := %111100000000 + k;
  i_MOVLB : flash[iFlash].value := %000000010000 + (k AND %111);  //Extended
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codAsmA(const inst: TPIC10Inst; const a: word);
{Codifica las instrucciones de control.
 "a" debe ser word, porque la dirección destino, requiere hasta 9 bits.}
begin
  case inst of
  i_CALL  : flash[iFlash].value := %100100000000 + (a and %11111111);
  i_GOTO : flash[iFlash].value := %101000000000 + (a and %111111111);
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codAsm(const inst: TPIC10Inst);
//Codifica las instrucciones de control.
begin
  case inst of
  i_CLRW  : flash[iFlash].value := %000001000000;
  i_NOP   : flash[iFlash].value := %000000000000;
  i_CLRWDT: flash[iFlash].value := %000000000100;
  i_SLEEP : flash[iFlash].value := %000000000011;
  i_OPTION: flash[iFlash].value := %000000000010;
  i_RETFIE: flash[iFlash].value := %000000011111;  //Extended
  i_RETURN: flash[iFlash].value := %000000011110;  //Extended
  else
    raise Exception.Create('Implementation Error.');
  end;
  useFlash;  //Mark as "used" and increase pointer.
end;
procedure TPICBase.codGotoAt(iflash0: integer; const k: word);
{Codifica una instrucción GOTO, en una posición específica y sin alterar el puntero "iFlash"
actual. Se usa para completar saltos indefinidos}
begin
  flash[iFlash0].value := %101000000000 + (k and %111111111);
end;
procedure TPICBase.codCallAt(iflash0: integer; const k: word);
{Codifica una instrucción i_CALL, en una posición específica y sin alterar el puntero "iFlash"
actual. Se usa para completar llamadas indefinidas}
begin
  flash[iFlash0].value := %100100000000 + (k and %11111111);
end;
function TPICBase.codInsert(iflash0, nInsert, nWords: integer): boolean;
{Inserta en la posición iflash0, "nInsert" palabras, desplazando "nWords" palabras.
Al final debe quedar "nInsert" palabras de espacio libre en iflash0.
Si hay error devuelve FALSE.}
var
  i: Integer;
begin
  Result := True;  //By default
  if iFlash+nInsert+nWords-1> MaxFlash then begin
    //Overflow on address
    exit(false);
  end;
  for i:= iflash + nInsert + nWords -1 downto iFlash + nWords do begin
    flash[i] := flash[i-nInsert];
  end;
end;
function TPICBase.FindOpcode(Op: string; var syntax: string): TPIC10Inst;
{Busca una cádena que represente a una instrucción (Opcode). Si encuentra devuelve
 el identificador de instrucción y una cadena que representa a la sintaxis en "syntax".
 Si no encuentra devuelve "i_Inval". }
var
  idInst: TPIC10Inst;
  tmp: String;
  found: Boolean;
begin
  found := false;
  tmp := UpperCase(Op);
  for idInst := low(TPIC10Inst) to high(TPIC10Inst) do begin
    if PIC16InstName[idInst] = tmp then begin
      found := true;
      break;
    end;
  end;
  if found then begin
    Result := idInst;
    syntax := PIC16InstSyntax[idInst];
  end else  begin
    Result := i_Inval;
  end;
end;
procedure TPICBase.addTopLabel(lbl: string);
begin
  flash[iFlash].topLabel := lbl;
end;
procedure TPICBase.addTopComm(comm: string; replace: boolean);
{Agrega un comentario de línea al código en la posición de memoria actual}
begin
  if replace then begin
    flash[iFlash].topComment := comm;
  end else begin
    flash[iFlash].topComment := flash[iFlash].topComment + comm;
  end;
end;
procedure TPICBase.addSideComm(comm: string; before: boolean);
{Agrega un comentario para que apareza al lado de la instrucción.
 "before" = TRUE -> Se debe llamar después de codificar la instrucción
 "before" = FALSE -> Se debe llamar antes de codificar la instrucción
 }
begin
  if before then begin
    if iFlash= 0 then exit;
    flash[iFlash-1].sideComment+=comm;   //se agrega al que pudiera haber
  end else begin
    if iFlash= 0 then exit;
    flash[iFlash].sideComment+=comm;   //se agrega al que pudiera haber
  end;
end;
procedure TPICBase.addPosInformation(rowSrc, colSrc: word; idFile: byte);
{Agrega information de la posición en el codigo fuente, a la posición actual de la
memoria flash.}
begin
  flash[iFlash].rowSrc := rowSrc;
  flash[iFlash].colSrc := colSrc;
  flash[iFlash].idFile := idFile;
end;
function  TPICBase.StrHexFlash(i1, i2: integer): string;
{Devuelve la cadena, de bytes hexadecimales de la memoria Flash, desde la posición
 i1 hasta i2.}
var
  i: Integer;
  tmp: String;
begin
  Result:='';
  for i:=i1 to i2 do begin
    tmp := IntToHex(flash[i].value,4);
    Result+=copy(tmp,3,2) + copy(tmp,1,2);  //se graba con los bytes invertidos
  end;
end;
//Campos para procesar instrucciones
function TPICBase.GetBank(i : Longint): TPICRAMBank;
begin
  case i of
  0: Result := bank0;
  1: Result := bank1;
  2: Result := bank2;
  3: Result := bank3;
  else
    Result := bank0;
  end;
end;
function TPICBase.GetPage(i: Longint): TPICBaseFlashPage;
begin
  case i of
  0: Result := page0;
  1: Result := page1;
  2: Result := page2;
  3: Result := page3;
  else
    Result := page0;
  end;
end;
function TPICBase.GetSTATUS: byte;
begin
  Result := ram[$03].value;
end;
function TPICBase.GetSTATUS_Z: boolean;
begin
  Result := (ram[$03].dvalue and %00000100) <> 0;
end;
procedure TPICBase.SetSTATUS_Z(AValue: boolean);
begin
  if AVAlue then ram[$03].dvalue := ram[$03].dvalue or  %00000100
            else ram[$03].dvalue := ram[$03].dvalue and %11111011;
end;
function TPICBase.GetSTATUS_C: boolean;
begin
  Result := (ram[$03].dvalue and %00000001) <> 0;
end;
procedure TPICBase.SetSTATUS_C(AValue: boolean);
begin
  if AVAlue then ram[$03].dvalue := ram[$03].dvalue or  %00000001
            else ram[$03].dvalue := ram[$03].dvalue and %11111110;
end;
function TPICBase.GetSTATUS_DC: boolean;
begin
  Result := (ram[$03].dvalue and %00000010) <> 0;
end;
procedure TPICBase.SetSTATUS_DC(AValue: boolean);
begin
  if AVAlue then ram[$03].dvalue := ram[$03].dvalue or  %00000010
            else ram[$03].dvalue := ram[$03].dvalue and %11111101;
end;
function TPICBase.GetSTATUS_IRP: boolean;
begin
  Result := (ram[$03].dvalue and %10000000) <> 0;
end;
procedure TPICBase.SetSTATUS_IRP(AValue: boolean);
begin
  if AVAlue then ram[$03].dvalue := ram[$03].dvalue or  %10000000
            else ram[$03].dvalue := ram[$03].dvalue and %01111111;
end;
function TPICBase.GetINTCON: byte;
begin
  Result := ram[$0B].dvalue;
end;
function TPICBase.GetINTCON_GIE: boolean;
begin
  Result := (ram[$0B].dvalue and %10000000) <> 0;
end;
procedure TPICBase.SetINTCON_GIE(AValue: boolean);
begin
  if AVAlue then ram[$0B].dvalue := ram[$0B].dvalue or  %10000000
            else ram[$0B].dvalue := ram[$0B].dvalue and %01111111;
end;
procedure TPICBase.SetMaxFlash(AValue: integer);
begin
  if FMaxFlash = AValue then Exit;
  FMaxFlash := AValue;
end;
procedure TPICBase.SetFRAM(value: byte);
{Escribe en la RAM; en la dirección global f_, el valor "value"
Para determinar el valor real de la dirección, se toma en cuenta los bits de BSR}
begin
  if f_ = 0 then begin
    //Caso especial de direccionamiento indirecto
    if STATUS_IRP then begin
      ram[ram[04].value + $100].value := value;
    end else begin
      ram[ram[04].value].value := value;
    end;
    exit;
  end;
  {Se escribe aplicando la máscara de bits implementados. Se podría usar la máscara en
  lectura o escritura, pero se prefiere hacerlo en escritura, porque se espera que se
  hagan menos operaciones de escritura que lectura.}
  case BSR and %111 of
  %000: ram[f_                ].value := value and ram[f_                ].dimplem;
  %001: ram[f_+PIC_BANK_SIZE  ].value := value and ram[f_+PIC_BANK_SIZE  ].dimplem;
  %010: ram[f_+PIC_BANK_SIZE*2].value := value and ram[f_+PIC_BANK_SIZE*2].dimplem;
  %011: ram[f_+PIC_BANK_SIZE*3].value := value and ram[f_+PIC_BANK_SIZE*3].dimplem;
  %100: ram[f_+PIC_BANK_SIZE*4].value := value and ram[f_+PIC_BANK_SIZE*4].dimplem;
  %101: ram[f_+PIC_BANK_SIZE*5].value := value and ram[f_+PIC_BANK_SIZE*5].dimplem;
  %110: ram[f_+PIC_BANK_SIZE*6].value := value and ram[f_+PIC_BANK_SIZE*6].dimplem;
  %111: ram[f_+PIC_BANK_SIZE*7].value := value and ram[f_+PIC_BANK_SIZE*7].dimplem;
  end;
end;
function TPICBase.GetFRAM: byte;
{Devuelve el valor de la RAM, de la posición global f_.
Para determinar el valor real de la dirección, se toma en cuenta los bits de STATUS}
begin
  if f_ = 0 then begin
    //Caso especial de direccionamiento indirecto
    if STATUS_IRP then begin
      Result := ram[ram[04].value + $100].value;
    end else begin
      Result := ram[ram[04].value].value;
    end;
    exit;
  end;
  case BSR and %01100000 of
  %000: Result := ram[f_                ].value;
  %001: Result := ram[f_+PIC_BANK_SIZE  ].value;
  %010: Result := ram[f_+PIC_BANK_SIZE*2].value;
  %011: Result := ram[f_+PIC_BANK_SIZE*3].value;
  %100: Result := ram[f_+PIC_BANK_SIZE*4].value;
  %101: Result := ram[f_+PIC_BANK_SIZE*5].value;
  %110: Result := ram[f_+PIC_BANK_SIZE*6].value;
  %111: Result := ram[f_+PIC_BANK_SIZE*7].value;
  end;
end;
procedure TPICBase.Decode(const opCode: word);
{Decodifica la instrucción indicada. Actualiza siempre la variable "idIns", y
dependiendo de la instrucción, puede actualizar: d_, f_, b_ y k_

0000 0000 0000	i_NOP
0000 0000 0010	i_OPTION
0000 0000 0011	i_SLEEP
0000 0000 0100	i_CLRWDT
0000 0000 01ff	i_TRIS x (x=5,6,7, f=01,10,11)
0000 0000 1fff	i_TRIS x (x=8,9, f=000, 001)
0000 001f ffff	i_MOVWF f
0000 01df ffff	CLR f,d
0000 10df ffff	i_SUBWF f,d
0000 11df ffff	i_DECF f,d

0001 00df ffff	i_IORWF f,d
0001 01df ffff	i_ANDWF f,d
0001 10df ffff	i_XORWF f,d
0001 11df ffff	i_ADDWF f,d

0010 00df ffff	i_MOVF f,d
0010 01df ffff	i_COMF f,d
0010 10df ffff	i_INCF f,d
0010 11df ffff	i_DECFSZ f,d

0011 00df ffff	i_RRF f,d
0011 01df ffff	i_RLF f,d
0011 10df ffff	i_SWAPF f,d
0011 11df ffff	i_INCFSZ f,d

0100 bbbf ffff	i_BCF f,b
0101 bbbf ffff	i_BSF f,b
0110 bbbf ffff	i_BTFSC f,b
0111 bbbf ffff	i_BTFSS f,b

1000 kkkk kkkk	i_RETLW k
1001 kkkk kkkk	i_CALL k
101k kkkk kkkk	GOTO k
1100 kkkk kkkk	i_MOVLW k
1101 kkkk kkkk	i_IORLW k
1110 kkkk kkkk	i_ANDLW k
1111 kkkk kkkk	i_XORLW k
}
var
  codH : byte;  //6 bits altos de la instrucción
  codL : byte;  //byte bajo de la instrucción
begin
  codH := (opCode and $0F00) >> 8;  //se debería optimizar
  codL := opCode and $00FF;
  case codH of
  %0000: begin
    if (codL and %11111000) = %00010000 then begin
      idIns := i_MOVLB;   //Extended instruction
      k_ := codL and %00000111;
    end else if (codL and %11100000) = %00100000 then begin
      idIns := i_MOVWF;
      f_ := codL and %00011111;
    end else if (codL and %11100000) = %01100000 then begin
      idIns := i_CLRF;
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %10000000 then begin
      idIns := i_SUBWF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %11000000 then begin
      idIns := i_DECF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else begin
      //bit7 a cero, hay varias opciones
      case codL of
      %00000000: begin
        idIns := i_NOP;
      end;
      %00011111: begin
        idIns := i_RETFIE;  //Extended instruction
      end;
      %00011110: begin
        idIns := i_RETURN;  //Extended instruction
      end;
      %01000000: begin
        idIns := i_CLRW;
      end;
      %00000010: begin
        idIns := i_OPTION;
      end;
      %00000011: begin
        idIns := i_SLEEP;
      end;
      %00000100: begin
        idIns := i_CLRWDT;
      end;
      %00000101: begin
        idIns := i_TRIS;
        f_ := 5;
      end;
      %00000110: begin
        idIns := i_TRIS;  //"i_TRIS GPIO" o "i_TRIS PORTB" according to the device
        f_ := 6;
      end;
      %00000111: begin
        idIns := i_TRIS;  //"i_TRIS PORTC" exist only in some devices
        f_ := 7;
      end;
      %00001000: begin
        idIns := i_TRIS;
        f_ := 8;
      end;
      %00001001: begin
        idIns := i_TRIS;
        f_ := 9;
      end;
      else
        idIns := i_Inval;
      end;
    end;
  end;
  %0001: begin
    if (codL and %11000000) = %00000000 then begin
      idIns := i_IORWF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %01000000 then begin
      idIns := i_ANDWF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %10000000 then begin
      idIns := i_XORWF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %11000000 then begin
      idIns := i_ADDWF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end;
  end;
  %0010: begin
    if (codL and %11000000) = %00000000 then begin
      idIns := i_MOVF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %01000000 then begin
      idIns := i_COMF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %10000000 then begin
      idIns := i_INCF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %11000000 then begin
      idIns := i_DECFSZ;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end;
  end;
  %0011: begin
    if (codL and %11000000) = %00000000 then begin
      idIns := i_RRF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %01000000 then begin
      idIns := i_RLF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %10000000 then begin
      idIns := i_SWAPF;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end else if (codL and %11000000) = %11000000 then begin
      idIns := i_INCFSZ;
      d_ := TPICBaseDestin(codL and %00100000);
      f_ := codL and %00011111;
    end;
  end;
  %0100: begin
    idIns := i_BCF;
    b_ := (codL and %11100000) >> 5;
    f_ := codL and %00011111;
  end;
  %0101: begin
    idIns := i_BSF;
    b_ := (codL and %11100000) >> 5;
    f_ := codL and %00011111;
  end;
  %0110: begin
    idIns := i_BTFSC;
    b_ := (codL and %11100000) >> 5;
    f_ := codL and %00011111;
  end;
  %0111: begin
    idIns := i_BTFSS;
    b_ := (codL and %11100000) >> 5;
    f_ := codL and %00011111;
  end;
  %1000: begin
    idIns := i_RETLW;
    k_ := codL;
  end;
  %1001: begin
    idIns := i_CALL;
    k_ := codL;
  end;
  %1010: begin
    idIns := i_GOTO;
    k_ := codL;
  end;
  %1011: begin
    idIns := i_GOTO;
    k_ := codL + 256;
  end;
  %1100: begin
    idIns := i_MOVLW;
    k_ := codL;
  end;
  %1101: begin
    idIns := i_IORLW;
    k_ := codL;
  end;
  %1110: begin
    idIns := i_ANDLW;
    k_ := codL;
  end;
  %1111: begin
    idIns := i_XORLW;
    k_ := codL;
  end;
  else
    idIns := i_Inval;
  end;
end;
function TPICBase.Disassembler(const opCode: word; bankNum: byte = 255;
                             useVarName: boolean = false): string;
{Desensambla la instrucción "opCode". Esta rutina utiliza las variables: d_, f_, b_ y k_
"opCode"  -> Código de Operación que se desea decodificar. Se asume que es de 12 bits.
"bankNum" -> Es el banco de trabajo en el que se supone se está decodificando el OpCode.
             Se usa para determinar la dirección de memoria real a la que se accede
             (cuando el OpCode alccede a memoria). Si no se conoce el valor, se debe
             poner en 255.
"useVarName" -> Indica que se quiere usar etiquetas para los nombres de las variables
             (En los Opcode que accedan a memoria). Solo es válido cuando
             bankNum = 0,1,2,3 y exista un nombre asociado a la variable.
}
var
  nemo: String;
  f: word;
begin
  Decode(opCode);   //decodifica instrucción
  nemo := lowerCase(trim(PIC16InstName[idIns])) + ' ';
  case idIns of
  i_ADDWF,
  i_ANDWF,
  i_COMF ,
  i_DECF ,
  i_DECFSZ,
  i_INCF,
  i_INCFSZ,
  i_IORWF,
  i_MOVF,
  i_RLF,
  i_RRF,
  i_SUBWF,
  i_SWAPF,
  i_XORWF: begin
      if bankNum in [0,1,2,3,4,5,6,7] then begin
        //Banco conocido
        f := f_ + PIC_BANK_SIZE*bankNum;  //Dirección real
      end else begin
        //Se asume un banco desconocido
        useVarName := false;  //Desactiva por si acaso
        bankNum := 0;  //Trabajará en este banco
        f := f;        //Dirección asumida
      end;
      if useVarName and (ram[f].name<>'') then begin
        //Required to include address name
        if d_ = toF then
          Result := nemo + ram[f].name + ',f'
        else
          Result := nemo + ram[f].name + ',w';
      end else begin
        //No Required to include address name
        if d_ = toF then
          Result := nemo + '0x'+IntToHex(f,3) + ',f'
        else
          Result := nemo + '0x'+IntToHex(f,3) + ',w';
      end;
     end;
  i_CLRF,
  i_MOVWF: begin
        if bankNum in [0,1,2,3,4,5,6,7] then begin
          //Banco conocido
          f := f_ + PIC_BANK_SIZE*bankNum;  //Dirección real
        end else begin
          //Se asume un banco desconocido
          useVarName := false;  //Desactiva por si acaso
          bankNum := 0;  //Trabajará en este banco
          f := f;        //Dirección asumida
        end;
        if useVarName and (ram[f].name<>'') then begin
          Result := nemo + ram[f].name;
        end else begin
          Result := nemo + '0x'+IntToHex(f,3);
        end;
     end;
  i_TRIS: begin
    Result := nemo + '0x'+IntToHex(f,2);
  end;
  i_BCF,
  i_BSF,
  i_BTFSC,
  i_BTFSS: begin    //Instrucciones de bit
      if bankNum in [0,1,2,3,4,5,6,7] then begin
        //Banco conocido
        f := f_ + PIC_BANK_SIZE*bankNum;  //Dirección real
      end else begin
        //Se asume un banco desconocido
        useVarName := false;  //Desactiva por si acaso
        bankNum := 0;  //Trabajará en este banco
        f := f;        //Dirección asumida
      end;
      if useVarName and (ram[f].bitname[b_]<>'') then begin
        //Hay nombre de bit
        Result := nemo + ram[f].bitname[b_];
      end else if useVarName and (ram[f].name<>'') then begin
        //Hay nombre de byte
        Result := nemo + ram[f].name + ', ' + IntToStr(b_);
      end else begin
        Result := nemo + '0x'+IntToHex(f,3) + ', ' + IntToStr(b_);
      end;
     end;
  i_ANDLW,
  i_IORLW,
  i_MOVLW,
  i_RETLW,
  i_XORLW,
  i_MOVLB: begin
       Result := nemo + '0x'+IntToHex(k_,2);
     end;
  i_CALL,
  i_GOTO: begin   //Faltaría decodificar la dirección
    Result := nemo + '0x'+IntToHex(k_,3);
  end;
  i_CLRW,
  i_NOP,
  i_CLRWDT,
  i_RETFIE,
  i_RETURN,
  i_SLEEP,
  i_OPTION: begin
       Result := nemo ;
     end;
  else
    Result := 'Invalid'
  end;
end;
function TPICBase.CurInstruction: TPIC10Inst;
{Devuelve la instrucción, a la cue apunta PC, actualmente}
var
  val: Word;
begin
  val := flash[PCH*256+PCL].value; // page0.mem[PCL].value;
  Decode(val);   //decodifica instrucción
  Result := idIns;
end;
procedure TPICBase.Exec();
{Executa la instrucción actual}
var
  pc: word;
begin
  pc := PCH*256+PCL;
  Exec(pc);
end;
procedure TPICBase.Exec(pc: word);
{Ejecuta la instrución actual con dirección "pc".
Falta implementar las operaciones, cuando acceden al registro INDF, el Watchdog timer,
los contadores, las interrupciones}
var
  opc: Word;
  //fullAdd: word;
  msk, resNib: byte;
  resByte, bit7, bit0: byte;
  resWord: word;
  resInt : integer;
begin
  //Decodifica instrucción
  opc := flash[pc].value; // page0.mem[PCL].value;
  Decode(opc);   //decodifica instrucción
  case idIns of
  i_ADDWF: begin
    resByte := FRAM;
    resWord := W + resByte;
    resNib := (W and $0F) + (resByte and $0F);
    if d_ = toF then begin
      FRAM := resWord and $FF;
    end else begin  //toW
      w := resWord and $FF;
    end;
    STATUS_Z := (resWord and $ff) = 0;
    STATUS_C := (resWord > 255);
    STATUS_DC := (resNib > 15);
  end;
  i_ANDWF: begin
    resByte := W and FRAM;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
  end;
  i_CLRF: begin
    FRAM := 0;
    STATUS_Z := true;
  end;
  i_CLRW: begin
    W := 0;
    STATUS_Z := true;
  end;
  i_COMF : begin
    resByte := not FRAM;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
  end;
  i_DECF : begin
    resByte := FRAM;
    if resByte = 0 then resByte := $FF else dec(resByte);
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
  end;
  i_DECFSZ: begin
    resByte := FRAM;
    if resByte = 0 then resByte := $FF else dec(resByte);
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
    if STATUS_Z then begin
      //salta una instrucción
      if PCL = 255 then begin
        PCL := 0;
        inc(PCH);
      end else begin
        inc(PCL);
      end;
      Inc(nClck);   //En este caso toma un ciclo más
    end;
  end;
  i_INCF: begin
    resByte := FRAM;
    if resByte = 255 then resByte := 0 else inc(resByte);
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
  end;
  i_INCFSZ: begin
    resByte := FRAM;
    if resByte = 255 then resByte := 0 else inc(resByte);
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte = 0;
    if STATUS_Z then begin
      //salta una instrucción
      if PCL = 255 then begin
        PCL := 0;
        inc(PCH);
      end else begin
        inc(PCL);
      end;
      Inc(nClck);   //En este caso toma un ciclo más
    end;
  end;
  i_IORWF: begin
    resByte := W or FRAM;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte <> 0;
  end;
  i_MOVF: begin
    resByte := FRAM;
    if d_ = toF then begin
      //no mueve, solo verifica
      STATUS_Z := (resByte = 0);
    end else begin  //toW
      w := resByte;
      STATUS_Z := (resByte = 0);
    end;
  end;
  i_MOVWF: begin
    FRAM := W;   //escribe a donde esté mapeado, (si está mapeado)
    if f_ = $02 then begin //Es el PCL
      PCH := PCLATH;  //Cuando se escribe en PCL, se carga PCH con PCLATH
    end;
  end;
  i_NOP: begin
  end;
  i_RLF: begin
    resByte := FRAM;
    bit7 := resByte and $80; //guarda bit 7
    resByte := (resByte << 1) and $ff;  //desplaza
    //pone C en bit bajo
    if STATUS_C then begin  //C era 1
      resByte := resByte or $01;  //pone a 1 el bit 0
    end else begin          //C era 0
      //no es necesario agregarlo, porque por defecto se agrega 0
    end;
    //Actualiza C
    if bit7 = 0 then STATUS_C := false
                else STATUS_C := true;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
  end;
  i_RRF: begin
    resByte := FRAM;
    bit0 := resByte and $01; //guarda bit 0
    resByte := resByte >> 1;  //desplaza
    //pone C en bit alto
    if STATUS_C then begin  //C era 1
      resByte := resByte or $80;  //pone a 1 el bit 0
    end else begin          //C era 0
      //no es necesario agregarlo, porque por defecto se agrega 0
    end;
    //Actualiza C
    if bit0 = 0 then STATUS_C := false
                else STATUS_C := true;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
  end;
  i_SUBWF: begin
    resByte := FRAM;
    resInt := resByte - W;
    if d_ = toF then begin
      FRAM :=  resInt and $FF;
    end else begin  //toW
      w := resInt and $FF;
    end;
    STATUS_Z := (resInt = 0);
    if resInt < 0 then STATUS_C := false   //negativo
    else STATUS_C := true;
    resInt := (resByte and $0F) - (W and $0F);
    if resInt < 0 then STATUS_DC := false   //negativo
    else STATUS_DC := true;
  end;
  i_SWAPF: begin
    resByte := FRAM;
    FRAM := (resByte >> 4) or (resByte << 4);
  end;
  i_XORWF: begin
    resByte := W xor FRAM;
    if d_ = toF then begin
      FRAM := resByte;
    end else begin  //toW
      w := resByte;
    end;
    STATUS_Z := resByte <> 0;
  end;
  //BIT-ORIENTED FILE REGISTER OPERATIONS
  i_BCF: begin
    msk := $1 << b_;
    msk := not msk;
    FRAM := FRAM and msk;
  end;
  i_BSF: begin
    msk := $1 << b_;
    FRAM := FRAM or msk;// b_
  end;
  i_BTFSC: begin
    msk := $1 << b_;
    if (FRAM and msk) = 0 then begin
      //salta una instrucción
      if PCL = 255 then begin
        PCL := 0;
        inc(PCH);
      end else begin
        inc(PCL);
      end;
      Inc(nClck);   //En este caso toma un ciclo más
    end;
  end;
  i_BTFSS: begin
    msk := $1 << b_;
    if (FRAM and msk) <> 0 then begin
      //salta una instrucción
      if PCL = 255 then begin
        PCL := 0;
        inc(PCH);
      end else begin
        inc(PCL);
      end;
      Inc(nClck);   //En este caso toma un ciclo más
    end;
  end;
  //LITERAL AND CONTROL OPERATIONS
  i_ANDLW: begin
    resByte := W and K_;
    w := resByte;
    STATUS_Z := resByte = 0;
  end;
  i_CALL: begin
    //Guarda dirección en Pila
    STACK[STKPTR] := PCH * 256 + PCL;
    if STKPTR = 7 then begin
      //Desborde de pila
      STKPTR := 0;
      if OnExecutionMsg<>nil then OnExecutionMsg('Stack Overflow on CALL OpCode at $' + IntToHex(pc,4));
    end else begin
      STKPTR := STKPTR +1;
    end;
    //En k, deben haber 11 bits
    PCL := k_ and $FF;
    PCH := word(k_ >> 8) or   //toma los 3 bits restantes de k
           (PCLATH and %00011000);  //y completa con los bits 3 y 4 de PCLATH
    Inc(nClck,2);   //Esta instrucción toma dos ciclos
    exit;
  end;
  i_CLRWDT: begin
  end;
  i_GOTO: begin
      //En k, deben haber 11 bits
      PCL := k_ and $FF;
      PCH := byte(k_ >> 8) or   //toma los 3 bits restantes de k
             (PCLATH and %00011000);  //y completa con los bits 3 y 4 de PCLATH
      Inc(nClck,2);   //Esta instrucción toma dos ciclos
      exit;
  end;
  i_IORLW: begin
    resByte := W or k_;
    w := resByte;
    STATUS_Z := resByte <> 0;
  end;
  i_MOVLW: begin
      W := k_;
  end;
  i_RETFIE: begin
    //Saca dirección en Pila
    if STKPTR = 0 then begin
      //Desborde de pila
      STKPTR := 7;
      if OnExecutionMsg<>nil then OnExecutionMsg('Stack Overflow on RETFIE OpCode at $' + IntToHex(pc,4));
    end else begin
      STKPTR := STKPTR - 1;
    end;
    PCH := hi(STACK[STKPTR]);  //solo debería haber 5 bits
    PCL := lo(STACK[STKPTR]);
    Inc(nClck);   //Esta instrucción toma un ciclo más
    //Activa GIE
    INTCON_GIE := true;
  end;
  i_RETLW: begin
    //Saca dirección en Pila
    if STKPTR = 0 then begin
      //Desborde de pila
      STKPTR := 7;
      if OnExecutionMsg<>nil then OnExecutionMsg('Stack Overflow on RETLW OpCode at $' + IntToHex(pc,4));
    end else begin
      STKPTR := STKPTR - 1;
    end;
    PCH := hi(STACK[STKPTR]);  //solo debería haber 5 bits
    PCL := lo(STACK[STKPTR]);
    Inc(nClck);   //Esta instrucción toma un ciclo más
    //Fija valor en W
    W := k_;
  end;
  i_RETURN: begin
    //Saca dirección en Pila
    if STKPTR = 0 then begin
      //Desborde de pila
      STKPTR := 7;
      if OnExecutionMsg<>nil then OnExecutionMsg('Stack Overflow on RETURN OpCode at $' + IntToHex(pc,4));
    end else begin
      STKPTR := STKPTR - 1;
    end;
    PCH := hi(STACK[STKPTR]);  //solo debería haber 5 bits
    PCL := lo(STACK[STKPTR]);
    Inc(nClck);   //Esta instrucción toma un ciclo más
  end;
  i_SLEEP: begin
  end;
  i_XORLW: begin
    resByte := W xor k_;
    w := resByte;
    STATUS_Z := resByte <> 0;
  end;
  i_OPTION: begin
    OPTION := W;
  end;
  i_TRIS: begin
    if f_ = 6 then TRISA := W;
    if f_ = 7 then TRISB := W;
    if f_ = 8 then TRISC := W;
  end;
  i_MOVLB: begin
    BSR := k_;
  end;
  i_Inval: begin
    MsjError := 'Invalid Opcode';
  end;
  end;
  //Incrementa contador
  if PCL = 255 then begin
    PCL := 0;
    inc(PCH);
  end else begin
    inc(PCL);
  end;
  Inc(nClck);
end;
procedure TPICBase.ExecTo(endAdd: word);
{Ejecuta las instrucciones secuencialmente, desde la instrucción actual, hasta que el
contador del programa, sea igual a la dirección "endAdd".}
var
  pc: word;
begin
  //Hace una primera ejecución, sin verificar Breakpoints
  pc := PCH<<8+PCL;
  Exec(pc);
  //Ejecuta cíclicamnente
  pc := PCH<<8+PCL;
  while pc <> endAdd do begin
    if flash[pc].breakPnt then begin
      //Encontró un BreakPoint, sale sin ejecutar esa instrucción
      if OnExecutionMsg<>nil then OnExecutionMsg('Stopped for breakpoint.');
//      stopped := true;
      exit;
    end;
    //Ejecuta
    Exec(pc);
    pc := PCH<<8+PCL;  //Actuliza Contador de programa
  end;
end;
procedure TPICBase.ExecNCycles(nCyc: integer; out stopped: boolean);
{Ejecuta el número de ciclos indicados, o hasta que se produzca alguna condición
externa, que puede ser:
* Se encuentre un Punto de Interrupción.
* Se detecta la señal, de detenerse.
* Se genere algún error en la ejecución.
* Se ejecuta la instrucción i_SLEEP.
la bandera "stopped", indica que se ha detendio la ejecución sin completar la cantidad
de instrucciones requeridas.
Normalmente Se ejecutará el número de ciclos indicados, pero en algunos casos se
ejecutará un ciclo más, debido a que algunas instrucciones toman dos ciclos.}
var
  clkEnd: Int64;
  pc: word;
begin
  clkEnd := nClck + nCyc;   //Valor final del contador
  while nClck < clkEnd do begin
    pc := PCH<<8+PCL;
    if flash[pc].breakPnt then begin
      //Encontró un BreakPoint, sale sin ejecutar esa instrucción
      if OnExecutionMsg<>nil then OnExecutionMsg('Stopped for breakpoint.');
      stopped := true;
      exit;
    end;
    if not flash[pc].used then begin
      //Encontró un BreakPoint, sale sin ejecutar esa instrucción
      if OnExecutionMsg<>nil then OnExecutionMsg('Stopped for executing unused code.');
      stopped := true;
      exit;
    end;
    if CommStop then begin
      //Se detectó el comando STOP
      if OnExecutionMsg<>nil then OnExecutionMsg('Stopped for STOP command.');
      stopped := true;
      exit;
    end;
    //Ejecuta
    Exec(pc);
    if idIns = i_SLEEP then begin
      //Encontró un BreakPoint, sale sin ejecutar esa instrucción
      if OnExecutionMsg<>nil then OnExecutionMsg('Stopped for SLEEP Opcode.');
      stopped := true;
      exit;
    end;
  end;
  stopped := false;
end;
procedure TPICBase.Reset;
//Reinicia el dipsoitivo
var
  i: Integer;
begin
  PCL := 0;
  PCLATH := 0;
  PCH := 0;
  W := 0;
  STKPTR := 0;   //Posición inicial del puntero de pila
  OPTION := $FF;
  TRISA   := $FF;
  BSR    := $00;
  nClck := 0;    //Inicia contador de ciclos
  CommStop := false;  //Limpia bandera
  //Limpia solamente el valor inicial, no toca los otros campos
  for i:=0 to high(ram) do begin
    ram[i].dvalue := $00;
  end;
  ram[$03].dvalue := %00011000;  //STATUS
end;
procedure TPICBase.AddBreakopint(pc: word);
//Agrega un punto de interrupción
begin
  if pc>=PIC_MAX_FLASH then exit;
  flash[pc].breakPnt := true;
end;
procedure TPICBase.ToggleBreakopint(pc: word);
//COnmuta el estado del Punto de Interrupción, en la posición indicada
begin
  if pc>=PIC_MAX_FLASH then exit;
  flash[pc].breakPnt := not flash[pc].breakPnt;
end;
//Funciones para la memoria RAM
function TPICBase.HaveConsecGPR(const i, n: word; maxRam: word): boolean;
{Indica si hay "n" bytes consecutivos libres en la posicióm "i", en RAM.
La búsqueda se hace solo hasta la posición "maxRam"}
var
  c: Integer;
  j: word;
begin
  Result := false;
  c := 0;
  j := i;
  while (j<=maxRam) and (c<n) do begin
    if (ram[j].state <> cs_impleGPR) or (ram[j].used <> 0) then exit;
    inc(c);      //verifica siguiente
    inc(j);
  end;
  if j>maxRam then exit;  //no hay más espacio
  //Si llega aquí es porque estaban libres los bloques
  Result := true;
end;
procedure TPICBase.UseConsecGPR(const i, n: word);
{Marca "n" bytes como usados en la posición de memoria "i", en la RAM.
 Debe haberse verificado previamente que los parámetros son válidos, porque aquí no
 se hará ninguna verificación.}
var j: word;
begin
  for j:=i to i+n-1 do begin
    ram[j].used:=255;  //todos los bits
  end;
end;
function TPICBase.GetFreeBit(out addr: word; out bit: byte; shared: boolean): boolean;
{Devuelve una dirección libre de la memoria RAM (y el banco).
"Shared" indica que se marcará el bit como de tipo "Compartido", y se usa para el
caso en que se quiera comaprtir la misma posición para diversos variables.
Si encuentra espacio, devuelve TRUE.}
var
  maxRam: word;
  i: Integer;
begin
  Result := false;   //valor inicial
  maxRam := NumBanks * PIC_BANK_SIZE;  //posición máxima
  //Realmente debería explorar solo hasta la dirección implementada, por eficiencia
  for i:=0 to maxRam-1 do begin
    if (ram[i].state = cs_impleGPR) and (ram[i].used <> 255) then begin
      //Esta dirección tiene al menos un bit libre
      addr := i;  //devuelve dirección
      //busca el bit libre
      if          (ram[i].used and %00000001) = 0 then begin
        bit:=0;
      end else if (ram[i].used and %00000010) = 0 then begin
        bit:=1
      end else if (ram[i].used and %00000100) = 0 then begin
        bit:=2
      end else if (ram[i].used and %00001000) = 0 then begin
        bit:=3
      end else if (ram[i].used and %00010000) = 0 then begin
        bit:=4
      end else if (ram[i].used and %00100000) = 0 then begin
        bit:=5
      end else if (ram[i].used and %01000000) = 0 then begin
        bit:=6
      end else if (ram[i].used and %10000000) = 0 then begin
        bit:=7
      end;
      ram[i].used := ram[i].used or (byte(1)<<bit); //marca bit usado
      if shared then begin
        ram[i].shared:= ram[i].shared or (byte(1)<<bit); //marca bit compartido
      end;
      //Notar que la posición de memoria puede estar mapeada a otro banco.
      Result := true;  //indica que encontró espacio
      exit;
    end;
  end;
end;
function TPICBase.GetFreeByte(out addr: word; shared: boolean): boolean;
{Devuelve una dirección libre de la memoria flash.
"Shared" indica que se marcará el bit como de tipo "Compartido", y se usa para el
caso en que se quiera comaprtir la misma posición para diversos variables.
Si encuentra espacio, devuelve TRUE.}
var
  i: Integer;
  maxRam: word;
begin
  Result := false;   //valor inicial
  maxRam := NumBanks * PIC_BANK_SIZE;  //posición máxima
  //Realmente debería explorar solo hasta la dirección implementada, por eficiencia
  for i:=0 to maxRam-1 do begin
    if (ram[i].state = cs_impleGPR) and (ram[i].used = 0) then begin
      //Esta dirección está libre
      ram[i].used:=255;   //marca como usado
      if shared then begin
        ram[i].shared := 255;  //Marca como compartido
      end;
      addr := i;
      //Notar que la posición de memoria puede estar mapeada a otro banco.
      Result := true;  //indica que encontró espacio
      exit;
    end;
  end;
end;
function TPICBase.GetFreeBytes(const size: integer; var addr: word): boolean;
{Devuelve una dirección libre de la memoria flash (y el banco) para ubicar un bloque
 del tamaño indicado. Si encuentra espacio, devuelve TRUE.
 El tamaño se da en bytes, pero si el valor es negativo, se entiende que es en bits.}
var
  i: word;
  maxRam: Word;
begin
  Result := false;  //valor por defecto
  if size=0 then exit;
  maxRam := word(NumBanks * PIC_BANK_SIZE) - 1;
  for i:=0 to maxRam do begin  //verifica 1 a 1, por seguridad
    if HaveConsecGPR(i, size, maxRam) then begin
      //encontró del tamaño buscado
      UseConsecGPR(i, size);  //marca como usado
      addr := i;
      Result := true;  //indica que encontró espacio
      exit;
    end;
  end;
end;
function TPICBase.TotalMemRAM: word;
{Devuelve el total de memoria RAM disponible}
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to word(NumBanks * PIC_BANK_SIZE) - 1 do begin
    if ram[i].AvailGPR then begin
      Result := Result + 1;
    end;
  end;
end;
function TPICBase.UsedMemRAM: word;
{Devuelve el total de memoria RAM usada}
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to word(NumBanks * PIC_BANK_SIZE) - 1 do begin
    if ram[i].AvailGPR and (ram[i].used <> 0) then begin
      //Notar que "AvailGPR" asegura que no se consideran registros maepados
      Result := Result + 1;
    end;
  end;
end;
procedure TPICBase.ExploreUsed(rutExplorRAM: TPICBaseRutExplorRAM);
{Genera un reporte de uso de RAM}
var
  i: Integer;
begin
  for i := 0 to word(NumBanks * PIC_BANK_SIZE) - 1 do begin
    if ram[i].AvailGPR and (ram[i].used <> 0) then begin
      rutExplorRAM(i, 0, @ram[i]);
    end;
  end;
end;
function TPICBase.ValidRAMaddr(addr: word): boolean;
{Indica si la dirercción indicada es válida dentro del hardware del PIC}
begin
  if addr > PIC_BANK_SIZE*NumBanks then exit(false);   //excede límite
  exit(true);
end;
procedure TPICBase.ClearMemRAM;
{Limpia el contenido de la memoria}
var
  i: Integer;
begin
  for i:=0 to high(ram) do begin
    ram[i].dvalue := $00;
    ram[i].used := 0;
    ram[i].name:='';
    ram[i].shared := 0;
//    ram[i].state := cs_unimplem;  //por defecto se considera no implementado
    ram[i].bitname[0] := '';
    ram[i].bitname[1] := '';
    ram[i].bitname[2] := '';
    ram[i].bitname[3] := '';
    ram[i].bitname[4] := '';
    ram[i].bitname[5] := '';
    ram[i].bitname[6] := '';
    ram[i].bitname[7] := '';
  end;
end;
procedure TPICBase.SetSharedUnused;
{Marca las posiciones que estén en "shared", como no usadas, para que se puedan
usar nuevamente.}
var
  i: Integer;
  amask: Byte;
begin
  for i:=0 to high(ram) do begin
    if (ram[i].state = cs_impleGPR) and (ram[i].shared <> 0) then begin
//debugln('    >> used $'+IntToHEx(i,3)+':'+ram[i].name);
      amask := not ram[i].shared;   //máscara invertida
      ram[i].used := ram[i].used and amask;  //pone en cero los bits shared
    end;
  end;
end;
procedure TPICBase.SetSharedUsed;
{Marca las posiciones que estén en "shared", como usadas, para que no se puedan
usar nuevamente.}
var
  i: Integer;
  amask: Byte;
begin
  for i:=0 to high(ram) do begin
    if (ram[i].state = cs_impleGPR) and (ram[i].shared <> 0) then begin
//debugln('    >> used $'+IntToHEx(i,3)+':'+ram[i].name);
      amask := ram[i].shared;   //máscara
      ram[i].used := ram[i].used or amask;  //pone en uno los bits shared
    end;
  end;
end;
procedure TPICBase.DisableAllRAM;
{Inicia el estado de toda la memoria RAM física definida em el Modelo.
Solo debería usarse, para cuando se va a definir el hardware del dispositivo.}
var
  i: word;
begin
  for i:=0 to high(ram) do begin
    ram[i].addr     := i;
    ram[i].state    := cs_unimplem;
    ram[i].mappedTo := nil;
    ram[i].dimplem  := $FF;  //Todos implementados, por defecto
  end;
  //Inicia estado de pines
  for i:=1 to high(pines) do begin
    pines[i].typ := pptUnused;
  end;
end;
procedure TPICBase.SetStatRAM(i1, i2: word; status0: TPICCellState);
{Inicia el campo State, de la memoria. Permite definir el estado real de la memoria RAM.
}
var
  i: Integer;
begin
  for i:=i1 to i2 do begin  //verifica 1 a 1, por seguridad
    ram[i].state := status0;
  end;
end;
procedure TPICBase.SetMappRAM(i1, i2: word; MappedTo: word);
{Inicia el campo State, de la memoria. Permite definir el estado real de la memoria RAM.
"MappedTo", indica el número de banco al cual está mapeada la sección de memoria indicada,
cuando se pone "status0" en "cs_mapToBnk". En los otrso estados no es útil.}
var
  i: Integer;
begin
  for i:= i1 to i2 do begin  //verifica 1 a 1, por seguridad
    ram[i].mappedTo := @ram[MappedTo];
    inc(MappedTo)
  end;
end;
function TPICBase.SetStatRAMCom(strDef: string): boolean;
{Define el estado de la memoria RAM, usando una cadena de definición.
La cadena de definición, tiene el formato:
<comando 1>, <comando 2>, ...
Cada comando, tiene el formato:
<dirIni>-<dirFin>:<estado de memoria>
Un ejemplo de cadena de definición, es:
   '000-01F:SFR, 020-07F:GPR'
Si hay error, devuelve FALSE, y el mensaje de error en MsjError.
}
var
  coms: TStringList;
  add1, add2: longint;
  state: TPICCellState;
  staMem, com, str: String;
begin
  Result := true;
  coms:= TStringList.Create;
  try
    coms.Delimiter := ',';
    coms.DelimitedText := strDef;
    for str in coms do begin
      com := UpCase(trim(str));
      if com='' then continue;
      if length(com)<>11 then begin
        MsjError := 'Memory definition syntax error: Bad string size.';
        exit(false);
      end;
      if com[4] <> '-' then begin
        MsjError := 'Memory definition syntax error: Expected "-".';
        exit(false);
      end;
      if com[8] <> ':' then begin
        MsjError := 'Memory definition syntax error: Expected ":".';
        exit(false);
      end;
      //Debe tener el formato pedido
      if not TryStrToInt('$'+copy(com,1,3), add1) then begin
        MsjError := 'Memory definition syntax error: Wrong address.';
        exit(false);
      end;
      if not TryStrToInt('$'+copy(com,5,3), add2) then begin
        MsjError := 'Memory definition syntax error: Wrong address.';
        exit(false);
      end;
      staMem := copy(com, 9, 3);
      case staMem of
      'SFR': state := cs_impleSFR;
      'GPR': state := cs_impleGPR;
      'NIM': state := cs_unimplem;
      else
        MsjError := 'Memory definition syntax error: Expected SFR or GPR';
        exit(false);
      end;
      //Ya se tienen los parámetros, para definir la memoria
      SetStatRAM(add1, add2, state);
    end;
  finally
    coms.Destroy;
  end;
end;
function TPICBase.SetMappRAMCom(strDef: string): boolean;
{Define memoria RAM mapeeada, en otra dirección.
La cadena de definición, tiene el formato:
<comando 1>, <comando 2>, ...
Cada comando, tiene el formato:
<dirIni>-<dirFin>:<banco al que está mapeado>
Un ejemplo de cadena de definición, es:
   '000-01F:bnk0, 020-07F:bnk1'
Si hay error, devuelve FALSE, y el mensaje de error en MsjError.
}
var
  coms: TStringList;
  add1, add2, addTar: longint;
  bnkTarStr, com, str: String;
  bnkTar: byte;
begin
  Result := true;
  coms:= TStringList.Create;
  try
    coms.Delimiter := ',';
    coms.DelimitedText := strDef;
    for str in coms do begin
      com := UpCase(trim(str));
      if com='' then continue;
      if length(com)<>12 then begin
        MsjError := 'Memory mapping syntax error: Bad string size.';
        exit(false);
      end;
      if com[4] <> '-' then begin
        MsjError := 'Memory mapping syntax error: Expected "-".';
        exit(false);
      end;
      if com[8] <> ':' then begin
        MsjError := 'Memory mapping syntax error: Expected ":".';
        exit(false);
      end;
      //Debe tener el formato pedido
//      debugln(com);
      if not TryStrToInt('$'+copy(com,1,3), add1) then begin
        MsjError := 'Memory mapping syntax error: Wrong address.';
        exit(false);
      end;
      if not TryStrToInt('$'+copy(com,5,3), add2) then begin
        MsjError := 'Memory mapping syntax error: Wrong address.';
        exit(false);
      end;
      bnkTarStr := copy(com, 9, 4);
      if copy(bnkTarStr,1,3)<>'BNK' then begin
        MsjError := 'Memory mapping syntax error: Expected "bnk0", ...';
        exit(false);
      end;
      if not (bnkTarStr[4] in ['0'..'3']) then begin
        MsjError := 'Memory mapping syntax error: Expected "bnk0", ...';
        exit(false);
      end;
      bnkTar := ord(bnkTarStr[4])-48;  //convierte a número
      //Ya se tienen los parámetros, para definir el mapeo
      case bnkTar of
      0: addTar := (add1 and $7F);
      1: addTar := (add1 and $7F) or $080;
      2: addTar := (add1 and $7F) or $100;
      3: addTar := (add1 and $7F) or $180;
      end;
      SetMappRAM(add1, add2, addTar);
    end;
  finally
    coms.Destroy;
  end;
end;
function TPICBase.MapRAMtoPIN(strDef: string): boolean;
{Mapea puertos de memoria RAM a pines físicos del dispositivo. Útil para la simulación
La cadena de definición, tiene el formato:
<dirección>:<comando 1>, <comando 2>, ...
Cada comando, tiene el formato:
<dirIni>-<dirFin>:<banco al que está mapeado>
Un ejemplo de cadena de definición, es:
   '005:0-17,1-18,2-1,3-2,4-3'
Si hay error, devuelve FALSE, y el mensaje de error en MsjError.
}
var
  coms: TStringList;
  add1, pin, bit: longint;
  com, str, ramName: String;
  pSep: SizeInt;
begin
  Result := true;
  //Obtiene dirección
  if length(strDef) < 4 then begin
    MsjError := 'Syntax error';
    exit(false);
  end;
  if strDef[4] <> ':' then begin
    MsjError := 'Expected "<3-digits address>"';
    exit(false);
  end;
  if not TryStrToInt('$'+copy(strDef,1,3), add1) then begin
    MsjError := 'Address format error.';
    exit(false);
  end;
  delete(strDef, 1, 4);  //quita la dirección
  //Obtiene lista de asociaciones
  coms:= TStringList.Create;
  try
    coms.Delimiter := ',';
    coms.DelimitedText := strDef;
    for str in coms do begin
      com := UpCase(trim(str));  //asociación
      if com='' then continue;
      pSep := pos('-',com);   //Posición de separador
      if pSep = 0 then begin
        MsjError := 'Expected "-".';
        exit(false);
      end;
      //Debe tener el formato pedido
//      debugln(com);
      if not TryStrToInt(copy(com,1,pSep-1), bit) then begin
        MsjError := 'Error in bit number.';
        exit(false);
      end;
      if not TryStrToInt(copy(com,pSep+1,length(com)), pin) then begin
        MsjError := 'Error in pin number.';
        exit(false);
      end;
      if (pin<0) or (pin>PIC_MAX_PINES) then begin
        MsjError := 'Pin number out of range.';
        exit(false);
      end;
      if pin>Npins then begin
        MsjError := 'Pin number out of range, for this device.';
        exit(false);
      end;
      //Ya se tiene el BIT y el PIN. Configura datos del PIN
      pines[pin].add := add1;
      pines[pin].bit := bit;
      pines[pin].typ := pptPort;
      ramName := ram[add1].name;
      if ramName='' then ramName := 'PORT';
      pines[pin].nam :=  ramName + '.' + IntToStr(bit);  //Nombre pro defecto
    end;
  finally
    coms.Destroy;
  end;
end;
procedure TPICBase.SetPin(pNumber: integer; pLabel: string; pType: TPICPinType);
begin
  if pNumber>PIC_MAX_PINES then exit;
  pines[pNumber].nam := pLabel;
  pines[pNumber].typ := pType;
end;
function TPICBase.SetUnimpBITS(strDef: string): boolean;
{Fija bits no implementados en posciones de memoria RAM.}
var
  coms: TStringList;
  add1, n: longint;
  mskBits, com, str: String;
  mskBitsN: byte;
begin
  Result := true;
  coms:= TStringList.Create;
  try
    coms.Delimiter := ',';
    coms.DelimitedText := strDef;
    for str in coms do begin
      com := UpCase(trim(str));
      if com='' then continue;
      if length(com)<>6 then begin
        MsjError := 'Syntax error: Expected "$$$:$$".';
        exit(false);
      end;
      if com[4] <> ':' then begin
        MsjError := 'Syntax error: Expected ":".';
        exit(false);
      end;
      //Debe tener el formato pedido
//      debugln(com);
      if not TryStrToInt('$'+copy(com,1,3), add1) then begin
        MsjError := 'Syntax error: Wrong address.';
        exit(false);
      end;
      if add1>high(ram) then begin
        MsjError := 'Syntax error: Wrong address.';
        exit(false);
      end;
      mskBits := copy(com, 5, 2);
      if not TryStrToInt('$'+mskBits, n) then begin
        MsjError := 'Syntax error: Wrong mask.';
        exit(false);
      end;
      mskBitsN := n;  //Se supone que nunca será > 255
      //Ya se tienen los parámetros, para definir el mapeo
      ram[add1].dimplem := mskBitsN;
    end;
  finally
    coms.Destroy;
  end;
end;
function TPICBase.BankToAbsRAM(const offset, bank: byte): word;
{Convierte una dirección y banco a una dirección absoluta}
begin
  Result := bank * PIC_BANK_SIZE + offset;
end;
procedure TPICBase.AbsToBankRAM(const AbsAddr: word; var offset, bank: byte);
{Convierte dirección absoluta a dirección en bancos}
begin
   offset := AbsAddr and %01111111;
   bank :=  AbsAddr >> 7;
end;
function TPICBase.NameRAM(const addr: word; const bnk: byte): string;
{Devuelve el nombre de una celda de la memoria RAM.}
begin
  Result := ram[BankToAbsRAM(addr, bnk)].name;
end;
function TPICBase.NameRAMbit(const addr: word; const bnk, bit: byte): string;
begin
  Result := ram[BankToAbsRAM(addr, bnk)].bitname[bit];
end;
procedure TPICBase.SetNameRAM(const addr: word; const nam: string
  );
{Escribe en el campo "name" de la RAM en la psoición indicada}
begin
   ram[addr].name:=nam;
end;
procedure TPICBase.AddNameRAM(const addr: word; const bnk: byte; const nam: string
  );
{Escribe en el campo "name" de la RAM en la psoición indicada. Si ya existía un nombre,
lo argega después de una coma.}
begin
  if ram[BankToAbsRAM(addr, bnk)].name = '' then begin
    ram[BankToAbsRAM(addr, bnk)].name:=nam;
  end else begin
    ram[BankToAbsRAM(addr, bnk)].name+=','+nam;
  end;
end;
procedure TPICBase.SetNameRAMbit(const addr: word; const bit: byte; const nam: string);
begin
  if (bit>7) then exit;
  ram[addr].bitname[bit] := nam;
end;
//Funciones para la memoria Flash
function TPICBase.UsedMemFlash: word;
var
  i: Integer;
begin
  Result := 0;
  for i:=$0000 to PIC_MAX_FLASH-1 do begin
    if flash[i].used then inc(Result);
  end;
end;
procedure TPICBase.ClearMemFlash;
var
  i: Integer;
begin
  for i:=0 to high(flash) do begin
    flash[i].value    := $3FFF;
    flash[i].used     := false;
    flash[i].curBnk   := 255;  //Desconocido
    flash[i].breakPnt := false;
    flash[i].topLabel   := '';
    flash[i].sideComment:= '';
    flash[i].topComment := '';
    flash[i].idFile   := -1;  //Indica no inicializado
  end;
end;
procedure TPICBase.GenHex(hexFile: string; ConfigWord: integer = -1);
{Genera el archivo *.hex, a partir de los datos almacenados en la memoria
FLASH.
Actualiza los campos, minUsed y maxUsed.}
var
  cfg, tmp: String;
  iHex: word;  //Índice para explorar
  dat: String; //Cadena de dígitos hexadecimales
  addr: word;  //Dirección de inicio
const
  MAX_INS_HEX = 8;  //Número máximo de instrucciones que devuelve por pasada

  function ExtractHex(out Addre: word): string;
  {Devuelve una cadena (de longitud que varía desde 0, hasta MAX_INS_HEX*4 caracteres)
  con valores en hexadecimal de instrucciones, consecutivas usadas, en le memoria FLASH.
  La lectura se hace a partir de iHex, y los caracteres en hexadecimal se escriben en 4
  dígitos, en la misma forma que se usan para los archivos *.HEX.
  En "Addre" devuelve la dirección absoluta de inicio desde donde lee. Con cada llamada,
  devuelve los bloques consecutivos de datos. Si no hay más datos devuelve cadena vacía.}
  var p1, p2: word;
      cont, p: word;
      tmp: String;
  begin
    Result := '';
    //Busca inicio de instrucciones usadas, desde la posición iHex
    while (iHex<PIC_MAX_FLASH) and not flash[iHex].used  do begin
      inc(iHex);
    end;
    if iHex>=PIC_MAX_FLASH then begin
      //Llegó al final
      exit;  //sale con cadena nula
    end;
    //Ya encontró el inicio ahora busca celdas consecutivas
    p1 := iHex;
    Addre := p1;
    cont := 2;  //inicia contador
    inc(iHex);  //pasa al siguiente
    while (iHex<PIC_MAX_FLASH) and (cont<MAX_INS_HEX) and flash[iHex].used do begin
      inc(iHex);
      inc(cont);
    end;
    if iHex>=PIC_MAX_FLASH then begin
      //Salió porque Llegó al final
      p2 := PIC_MAX_FLASH-1;
    end else if cont>=MAX_INS_HEX then begin
      //Salió porque llegó al máximo de celdas
      if flash[iHex].used then begin
        //La ultima celda estaba ocupada
        p2 := iHex;
        inc(iHex);   //deja listo para la siguiente exploración
      end else begin
        //La ultima celda estaba ocupada
        p2 := iHex-1;
        //iHex, queda apuntando a la siguiente celda
      end;
    end else begin
      //Salió porque encontró celda sin usar
      p2 := iHex-1;
      //iHex, queda apuntando a la siguiente celda
    end;
    //Ya tiene las dos posiciones
    tmp := '';
    for p:=p1 to p2 do begin
      if p1<minUsed then minUsed := p1;   //Actualiza
      if p2>maxUsed then maxUsed := p2;   //Actualiza
      tmp := IntToHex(flash[p].value, 4);
      Result +=copy(tmp,3,2) + copy(tmp,1,2);  //se graba con los bytes invertidos
    end;
  end;

begin
  hexLines.Clear;      //Se usará la lista hexLines
  GenHexExAdd($0000);
  //Prepara extracción de datos
  minUsed := PIC_MAX_FLASH;
  maxUsed := 0;
  iHex := 0;
  //Inicia la extracción de código
  dat := ExtractHex(addr);
  while dat <>'' do begin
     GenHexData(addr, dat);
     dat := ExtractHex(addr);
  end;
  //Bits de configuración
  tmp := '';
  if ConfigWord<>-1 then begin
    //Se pide generar bits de configuración
    {Los bits de configuración para la serie 16F, se almacenan en:
Config: 0x2007 (0x400E in the HEX file)
EEPROM: 0x2100 (0x4200 in the HEX file) }
    cfg := IntToHex(ConfigWord and $FFFF, 4);
    tmp +=copy(cfg,3,2) + copy(cfg,1,2);  //se graba con los bytes invertidos
    GenHexData($2007, tmp);
  end;
  GenHexEOF;                    //Fin de archivo
  GenHexComm(self.Model);       //Comentario
  hexLines.SaveToFile(hexFile); //Genera archivo
end;
procedure TPICBase.DumpCode(lOut: TStrings; incAdrr, incCom, incVarNam: boolean);
{Desensambla las instrucciones grabadas en el PIC.
 Se debe llamar despues de llamar a GenHex(), para que se actualicen las variables}
var
  valOp, i: Word;
  lblLin, comLat, comLin, lin: String;
  bnkOp: Byte;
begin
  //Se supone que minUsed y maxUsed, ya deben haber sido actualizados.
  for i := minUsed to maxUsed do begin
    //Lee comentarios y etiqueta
    lblLin := flash[i].topLabel;
    comLat := flash[i].sideComment;
    comLin := flash[i].topComment;
    //Escribe etiqueta al inicio de línea
    if lblLin<>'' then lOut.Add(lblLin+':');
    //Escribe comentario al inicio de línea
    if incCom and (comLin<>'') then  begin
      lOut.Add(comLin);
    end;
    //Decodifica instrucción
    valOp := flash[i].value;
    bnkOp := flash[i].curBnk;
    //Escribe línea
    lin := Disassembler(valOp, bnkOp, incVarNam);  //Instrucción
    //Verificas si incluye dirección física
    if incAdrr then  begin
      lin := '0x'+IntToHex(i,3) + ' ' + lin;
    end;
    //Verifica si incluye comentario lateral
    if incCom then begin
      lin := lin  + ' ' + comLat;
    end;
    lOut.Add('    ' + lin);
  end;
end;
constructor TPICBase.Create;
begin
  inherited Create;
  //configuración de hardware por defecto
  NumBanks:=2;     //Número de bancos de RAM. Por defecto se asume 2
  NumPages:=1;     //Número de páginas de memoria Flash. Por defecto 1
  MaxFlash := PIC_PAGE_SIZE;  //En algunos casos, puede ser menor al tamaño de una página
  bank0.Init(0, $000, @ram);
  bank1.Init(1, $080, @ram);
  bank2.Init(2, $100, @ram);
  bank3.Init(3, $180, @ram);
  //inicia una configuración común
  ClearMemRAM;
  SetStatRAM($020, $04F, cs_impleGPR);

  page0.Init($0000          , @flash);
  page1.Init(1*PIC_PAGE_SIZE, @flash);
  page2.Init(2*PIC_PAGE_SIZE, @flash);
  page3.Init(3*PIC_PAGE_SIZE, @flash);

  //estado inicial
  iFlash := 0;   //posición de inicio
  ClearMemFlash;
end;
destructor TPICBase.Destroy;
begin
  inherited Destroy;
end;

procedure InitTables;
begin
  //Inicializa Mnemónico de instrucciones
  PIC16InstName[i_ADDWF ] := 'ADDWF';
  PIC16InstName[i_ANDWF ] := 'ANDWF';
  PIC16InstName[i_CLRF  ] := 'CLRF';
  PIC16InstName[i_CLRW  ] := 'CLRW';
  PIC16InstName[i_COMF  ] := 'COMF';
  PIC16InstName[i_DECF  ] := 'DECF';
  PIC16InstName[i_DECFSZ] := 'DECFSZ';
  PIC16InstName[i_INCF  ] := 'INCF';
  PIC16InstName[i_INCFSZ] := 'INCFSZ';
  PIC16InstName[i_IORWF ] := 'IORWF';
  PIC16InstName[i_MOVF  ] := 'MOVF';
  PIC16InstName[i_MOVWF ] := 'MOVWF';
  PIC16InstName[i_NOP   ] := 'NOP';
  PIC16InstName[i_RLF   ] := 'RLF';
  PIC16InstName[i_RRF   ] := 'RRF';
  PIC16InstName[i_SUBWF ] := 'SUBWF';
  PIC16InstName[i_SWAPF ] := 'SWAPF';
  PIC16InstName[i_XORWF ] := 'XORWF';
  PIC16InstName[i_BCF   ] := 'BCF';
  PIC16InstName[i_BSF   ] := 'BSF';
  PIC16InstName[i_BTFSC ] := 'BTFSC';
  PIC16InstName[i_BTFSS ] := 'BTFSS';
  PIC16InstName[i_ANDLW ] := 'ANDLW';
  PIC16InstName[i_CALL  ] := 'CALL';
  PIC16InstName[i_CLRWDT] := 'CLRWDT';
  PIC16InstName[i_GOTO ] := 'GOTO';
  PIC16InstName[i_IORLW ] := 'IORLW';
  PIC16InstName[i_MOVLW ] := 'MOVLW';
  PIC16InstName[i_RETFIE] := 'RETFIE';
  PIC16InstName[i_RETLW ] := 'RETLW';
  PIC16InstName[i_RETURN] := 'RETURN';
  PIC16InstName[i_SLEEP ] := 'SLEEP';
  PIC16InstName[i_XORLW ] := 'XORLW';
  PIC16InstName[i_OPTION] := 'OPTION';
  PIC16InstName[i_TRIS]   := 'TRIS';
  PIC16InstName[i_MOVLB]  := 'MOVLB';
  PIC16InstName[i_Inval] := '<Inval>';

  //Inicializa Sintaxis de las instrucciones
  {Los valorees para la sintaxis significan:
  f->dirección de un registro en RAM (0..127)
  d->destino (W o F)
  b->número de bit (0..7)
  a->dirección destino (0..$7FF)
  k->literal byte (0..255)
  }
  PIC16InstSyntax[i_ADDWF ] := 'fd';
  PIC16InstSyntax[i_ANDWF ] := 'fd';
  PIC16InstSyntax[i_CLRF  ] := 'f';
  PIC16InstSyntax[i_CLRW  ] := '';
  PIC16InstSyntax[i_COMF  ] := 'fd';
  PIC16InstSyntax[i_DECF  ] := 'fd';
  PIC16InstSyntax[i_DECFSZ] := 'fd';
  PIC16InstSyntax[i_INCF  ] := 'fd';
  PIC16InstSyntax[i_INCFSZ] := 'fd';
  PIC16InstSyntax[i_IORWF ] := 'fd';
  PIC16InstSyntax[i_MOVF  ] := 'fd';
  PIC16InstSyntax[i_MOVWF ] := 'f';
  PIC16InstSyntax[i_NOP   ] := '';
  PIC16InstSyntax[i_RLF   ] := 'fd';
  PIC16InstSyntax[i_RRF   ] := 'fd';
  PIC16InstSyntax[i_SUBWF ] := 'fd';
  PIC16InstSyntax[i_SWAPF ] := 'fd';
  PIC16InstSyntax[i_XORWF ] := 'fd';
  PIC16InstSyntax[i_BCF   ] := 'fb';
  PIC16InstSyntax[i_BSF   ] := 'fb';
  PIC16InstSyntax[i_BTFSC ] := 'fb';
  PIC16InstSyntax[i_BTFSS ] := 'fb';
  PIC16InstSyntax[i_ANDLW ] := 'k';
  PIC16InstSyntax[i_CALL  ] := 'a';
  PIC16InstSyntax[i_CLRWDT] := '';
  PIC16InstSyntax[i_GOTO ] := 'a';
  PIC16InstSyntax[i_IORLW ] := 'k';
  PIC16InstSyntax[i_MOVLW ] := 'k';
  PIC16InstSyntax[i_RETFIE] := '';
  PIC16InstSyntax[i_RETLW ] := 'k';
  PIC16InstSyntax[i_RETURN] := '';
  PIC16InstSyntax[i_SLEEP ] := '';
  PIC16InstSyntax[i_XORLW ] := 'k';
  PIC16InstName[i_OPTION] := '';
  PIC16InstName[i_TRIS]   := 'f';
  PIC16InstName[i_MOVLB]  := 'k';
  PIC16InstSyntax[i_Inval] := '<???>';
end;
initialization
  InitTables;
end.
//2485