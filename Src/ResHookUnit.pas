unit ResHookUnit;
interface

uses Consts;

type
  TMenuKeyCap = (mkcBkSp, mkcTab, mkcEsc, mkcEnter, mkcSpace, mkcPgUp,
    mkcPgDn, mkcEnd, mkcHome, mkcLeft, mkcUp, mkcRight, mkcDown, mkcIns,
    mkcDel, mkcShift, mkcCtrl, mkcAlt);

var
  MenuKeyCaps: array[TMenuKeyCap] of string = (
    SmkcBkSp, SmkcTab, SmkcEsc, SmkcEnter, SmkcSpace, SmkcPgUp,
    SmkcPgDn, SmkcEnd, SmkcHome, SmkcLeft, SmkcUp, SmkcRight,
    SmkcDown, SmkcIns, SmkcDel, SmkcShift, SmkcCtrl, SmkcAlt);

Var
  { Defaults match LanguageSetup English fallbacks; LoadMenuLanguage overwrites these. }
  MsgDlgWarning : String = 'Warning';
  MsgDlgError : String = 'Error';
  MsgDlgInformation : String = 'Information';
  MsgDlgConfirm : String = 'Confirmation';
  MsgDlgYes : String = '&Yes';
  MsgDlgNo : String = '&No';
  MsgDlgOK : String = 'OK';
  MsgDlgCancel : String = 'Cancel';
  MsgDlgAbort : String = '&Abort';
  MsgDlgRetry : String = '&Retry';
  MsgDlgIgnore : String = '&Ignore';
  MsgDlgAll : String = '&All';
  MsgDlgNoToAll : String = 'No to &all';
  MsgDlgYesToAll : String = 'Yes to a&ll';

implementation

uses SysUtils, Classes, Windows, Menus, IdGlobal, IdGlobalProtocols, IdException,
     ResHookHelpers;

{ RTL patching system }

type
  PJump = ^TJump;
  TJump = packed record
    OpCode: Byte;
    Distance: Pointer;
  end;

procedure AddressPatch(const ASource, ADestination: Pointer);
const
  Size = SizeOf(TJump);
var
  NewJump: PJump;
  OldProtect: Cardinal;
begin
  if VirtualProtect(ASource, Size, PAGE_EXECUTE_READWRITE, OldProtect) then
  begin
    NewJump := PJump(ASource);
    NewJump.OpCode := $E9;
    NewJump.Distance := Pointer(Integer(ADestination) - Integer(ASource) - 5);

    FlushInstructionCache(GetCurrentProcess, ASource, SizeOf(TJump));
    VirtualProtect(ASource, Size, OldProtect, @OldProtect);
  end;
end;

{ New version of "ShortCutToText" }

function GetSpecialName(ShortCut: TShortCut): string;
var
  ScanCode: Integer;
  KeyName: array[0..255] of Char;
begin
  Result := '';
  ScanCode := MapVirtualKey(WordRec(ShortCut).Lo, 0) shl 16;
  if ScanCode <> 0 then
  begin
    GetKeyNameText(ScanCode, KeyName, SizeOf(KeyName));
    GetSpecialName := KeyName;
  end;
end;

function NewShortCutToText(ShortCut: TShortCut): string;
var
  Name: string;
begin
  case WordRec(ShortCut).Lo of
    $08, $09:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcBkSp) + WordRec(ShortCut).Lo - $08)];
    $0D: Name := MenuKeyCaps[mkcEnter];
    $1B: Name := MenuKeyCaps[mkcEsc];
    $20..$28:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcSpace) + WordRec(ShortCut).Lo - $20)];
    $2D..$2E:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcIns) + WordRec(ShortCut).Lo - $2D)];
    $30..$39: Name := Chr(WordRec(ShortCut).Lo - $30 + Ord('0'));
    $41..$5A: Name := Chr(WordRec(ShortCut).Lo - $41 + Ord('A'));
    $60..$69: Name := Chr(WordRec(ShortCut).Lo - $60 + Ord('0'));
    $70..$87: Name := 'F' + IntToStr(WordRec(ShortCut).Lo - $6F);
  else
    Name := GetSpecialName(ShortCut);
  end;
  if Name <> '' then
  begin
    Result := '';
    if ShortCut and scShift <> 0 then Result := Result + MenuKeyCaps[mkcShift];
    if ShortCut and scCtrl <> 0 then Result := Result + MenuKeyCaps[mkcCtrl];
    if ShortCut and scAlt <> 0 then Result := Result + MenuKeyCaps[mkcAlt];
    Result := Result + Name;
  end
  else Result := '';
end;

Type TLoadResStringMode = (lrsmLearning, lrsmNormal);

Var LoadResStringMode : TLoadResStringMode;

Var NrMsgDlgWarning, NrMsgDlgError, NrMsgDlgInformation, NrMsgDlgConfirm, NrMsgDlgYes,
    NrMsgDlgNo, NrMsgDlgOK, NrMsgDlgCancel, NrMsgDlgAbort, NrMsgDlgRetry, NrMsgDlgIgnore,
    NrMsgDlgAll, NrMsgDlgNoToAll, NrMsgDlgYesToAll : NativeUInt;

Var Nr : Integer;

{ New version of "LoadResString" }

function NewLoadResString(ResStringRec: PResStringRec): string;
var Buffer: array [0..4095] of char;
begin
  if ResStringRec=nil then begin result:=''; exit; end;

  if ResStringRec.Identifier >= NativeUInt(64*1024) then begin
    Result:=PChar(ResStringRec.Identifier);
    exit;
  end;

  If LoadResStringMode=lrsmLearning then begin
    Case Nr of
      0 : NrMsgDlgWarning:=ResStringRec.Identifier;
      1 : NrMsgDlgError:=ResStringRec.Identifier;
      2 : NrMsgDlgInformation:=ResStringRec.Identifier;
      3 : NrMsgDlgConfirm:=ResStringRec.Identifier;
      4 : NrMsgDlgYes:=ResStringRec.Identifier;
      5 : NrMsgDlgNo:=ResStringRec.Identifier;
      6 : NrMsgDlgOK:=ResStringRec.Identifier;
      7 : NrMsgDlgCancel:=ResStringRec.Identifier;
      8 : NrMsgDlgAbort:=ResStringRec.Identifier;
      9 : NrMsgDlgRetry:=ResStringRec.Identifier;
     10 : NrMsgDlgIgnore:=ResStringRec.Identifier;
     11 : NrMsgDlgAll:=ResStringRec.Identifier;
     12 : NrMsgDlgNoToAll:=ResStringRec.Identifier;
     13 : NrMsgDlgYesToAll:=ResStringRec.Identifier;
    end;
    SetString(Result, Buffer, LoadString(FindResourceHInstance(ResStringRec.Module^), ResStringRec.Identifier, Buffer, SizeOf(Buffer)));
    exit;
  end;

  If ResStringRec.Identifier=NrMsgDlgWarning then begin result:=MsgDlgWarning; exit; end;
  If ResStringRec.Identifier=NrMsgDlgError then begin result:=MsgDlgError; exit; end;
  If ResStringRec.Identifier=NrMsgDlgInformation then begin result:=MsgDlgInformation; exit; end;
  If ResStringRec.Identifier=NrMsgDlgConfirm then begin result:=MsgDlgConfirm; exit; end;
  If ResStringRec.Identifier=NrMsgDlgYes then begin result:=MsgDlgYes; exit; end;
  If ResStringRec.Identifier=NrMsgDlgNo then begin result:=MsgDlgNo; exit; end;
  If ResStringRec.Identifier=NrMsgDlgOK then begin result:=MsgDlgOK; exit; end;
  If ResStringRec.Identifier=NrMsgDlgCancel then begin result:=MsgDlgCancel; exit; end;
  If ResStringRec.Identifier=NrMsgDlgAbort then begin result:=MsgDlgAbort; exit; end;
  If ResStringRec.Identifier=NrMsgDlgRetry then begin result:=MsgDlgRetry; exit; end;
  If ResStringRec.Identifier=NrMsgDlgIgnore then begin result:=MsgDlgIgnore; exit; end;
  If ResStringRec.Identifier=NrMsgDlgAll then begin result:=MsgDlgAll; exit; end;
  If ResStringRec.Identifier=NrMsgDlgNoToAll then begin result:=MsgDlgNoToAll; exit; end;
  If ResStringRec.Identifier=NrMsgDlgYesToAll then begin result:=MsgDlgYesToAll; exit; end;

  SetString(Result, Buffer, LoadString(FindResourceHInstance(ResStringRec.Module^), ResStringRec.Identifier, Buffer, SizeOf(Buffer)));
end;

{New versions of functions from IdGlobalProtocols}

{ NewRawStrInternetToDateTime extracted to ResHookHelpers }

function NewStrInternetToDateTime(Value: string): TDateTime;
begin
  Result := NewRawStrInternetToDateTime(Value);
end;

{ GmtOffsetStrToDateTime extracted to ResHookHelpers }

function OffsetFromUTC: TDateTime;
var
  iBias: Integer;
  tmez: TTimeZoneInformation;
begin
  Case GetTimeZoneInformation(tmez) of
    TIME_ZONE_ID_INVALID:
      raise EIdFailedToRetreiveTimeZoneInfo.Create('RSFailedTimeZoneInfo');
    TIME_ZONE_ID_UNKNOWN  :
       iBias := tmez.Bias;
    TIME_ZONE_ID_DAYLIGHT :
      iBias := tmez.Bias + tmez.DaylightBias;
    TIME_ZONE_ID_STANDARD :
      iBias := tmez.Bias + tmez.StandardBias;
    else
      raise EIdFailedToRetreiveTimeZoneInfo.Create('RSFailedTimeZoneInfo');
  end;
  {We use ABS because EncodeTime will only accept positve values}
  Result := EncodeTime(Abs(iBias) div 60, Abs(iBias) mod 60, 0, 0);
  {The GetTimeZone function returns values oriented towards convertin
   a GMT time into a local time.  We wish to do the do the opposit by returning
   the difference between the local time and GMT.  So I just make a positive
   value negative and leave a negative value as positive}
  if iBias > 0 then begin
    Result := 0 - Result;
  end;
end;

function NewGMTToLocalDateTime(S: string): TDateTime;
var  {-Always returns date/time relative to GMT!!  -Replaces StrInternetToDateTime}
  DateTimeOffset: TDateTime;
begin
  try
    If length(S)<10 then result:=Now else Result:=NewRawStrInternetToDateTime(S);
  except
    result:=Now;
  end;
  if Length(S) < 5 then begin
    DateTimeOffset := 0.0
  end else begin
    DateTimeOffset := GmtOffsetStrToDateTime(S);
  end;
  {-Apply GMT offset here}
  if DateTimeOffset < 0.0 then begin
    Result := Result + Abs(DateTimeOffset);
  end else begin
    Result := Result - DateTimeOffset;
  end;
  { Apply local offset}
  Result := Result + OffSetFromUTC;
end;


Var S : String;
initialization
  AddressPatch(@IdGlobalProtocols.GMTToLocalDateTime,@NewGMTToLocalDateTime);

  AddressPatch(@Menus.ShortCutToText,@NewShortCutToText);

  LoadResStringMode:=lrsmLearning;
  AddressPatch(@System.LoadResString,@NewLoadResString);
  {$O-}
  Nr:=0; S:=SMsgDlgWarning;
  Nr:=1; S:=SMsgDlgError;
  Nr:=2; S:=SMsgDlgInformation;
  Nr:=3; S:=SMsgDlgConfirm;
  Nr:=4; S:=SMsgDlgYes;
  Nr:=5; S:=SMsgDlgNo;
  Nr:=6; S:=SMsgDlgOK;
  Nr:=7; S:=SMsgDlgCancel;
  Nr:=8; S:=SMsgDlgAbort;
  Nr:=9; S:=SMsgDlgRetry;
  Nr:=10; S:=SMsgDlgIgnore;
  Nr:=11; S:=SMsgDlgAll;
  Nr:=12; S:=SMsgDlgNoToAll;
  Nr:=13; S:=SMsgDlgYesToAll;
  LoadResStringMode:=lrsmNormal;
end.
