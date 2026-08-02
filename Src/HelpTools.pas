unit HelpTools;
interface

{
Usage:

Function InitHTMLHelp(const HelpFileName : String) : THTMLhelpRouter;
}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, HelpContextMap;

const
   cVersion = '2.02';

   HH_DISPLAY_TOPIC        = $0000;
   HH_HELP_FINDER          = $0000;  { WinHelp equivalent }
   HH_DISPLAY_TOC          = $0001;  { not currently implemented }
   HH_DISPLAY_INDEX        = $0002;  { not currently implemented }
   HH_DISPLAY_SEARCH       = $0003;  { not currently implemented }
   HH_SET_WIN_TYPE         = $0004;
   HH_GET_WIN_TYPE         = $0005;
   HH_GET_WIN_HANDLE       = $0006;
   HH_ENUM_INFO_TYPE       = $0007;
   HH_SET_INFO_TYPE        = $0008;
   HH_SYNC                 = $0009;
   HH_RESERVED1            = $000A;
   HH_RESERVED2            = $000B;
   HH_RESERVED3            = $000C;
   HH_KEYWORD_LOOKUP       = $000D;
   HH_DISPLAY_TEXT_POPUP   = $000E;
   HH_HELP_CONTEXT         = $000F;
   HH_TP_HELP_CONTEXTMENU  = $0010;
   HH_TP_HELP_WM_HELP      = $0011;
   HH_CLOSE_ALL            = $0012;
   HH_ALINK_LOOKUP         = $0013;
   HH_GET_LAST_ERROR       = $0014;
   HH_ENUM_CATEGORY        = $0015;
   HH_ENUM_CATEGORY_IT     = $0016;
   HH_RESET_IT_FILTER      = $0017;
   HH_SET_INCLUSIVE_FILTER = $0018;
   HH_SET_EXCLUSIVE_FILTER = $0019;
   HH_INITIALIZE           = $001C;
   HH_UNINITIALIZE         = $001D;
   HH_PRETRANSLATEMESSAGE  = $00fd;
   HH_SET_GLOBAL_PROPERTY  = $00fc;

type
   THH_POPUP = record
      cbStruct: integer;
      hinst: THandle;
      idString: cardinal;
      pszText: PChar;
      pt: TPoint;
      clrForeground: TColor;
      clrBackground: TColor;
      rcMargins: TRect;
      pszFont: PChar;
   end;

type
   THH_AKLINK = record
      cbStruct: integer;
      fReserved: boolean;
      pszKeywords: Pchar;
      pszUrl: Pchar;
      pszMsgText: PChar;
      pszMsgTitle: PChar;
      pszMsgWindow: PChar;
      fIndexOnFail: boolean;
   end;

type
  THelpType = (htAuto, htWinhelp, htHTMLhelp);
  TShowType = (stDefault, stMain, stPopup);

  EOwnerError = class(Exception);

  THTMLhelpRouter = class(TComponent)
  private
    fHelpType: THelpType;
    fShowType: TShowType;
    fAppOnHelp: THelpEvent;
    fOnHelp: THelpEvent;
    fHelpfile: string;
    function CurrentForm: TForm;
    function FindHandle(var Helphandle: HWND; var hfile: string): boolean;
    procedure SetHelpType(value: THelpType);
    function GetVersion: string;
    procedure SetVersion(dummy: string);
    function OnRouteHelp(Command: Word; Data: Longint; var CallHelp: Boolean): Boolean;
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function HTMLhelpInstalled: boolean;
    function HelpContent: boolean;
    function HelpKeyword(keyword: string): boolean;
    function HelpKLink(keyword: string): boolean;
    function HelpALink(akeyword: string): boolean;
    function HelpJump(hfile, topicid: string): boolean;
    function HelpPopup(X,Y: integer; text: string): boolean;
  published
    property HelpType: THelpType read fHelpType write SetHelpType;
    property ShowType: TShowType read fShowType write fShowType default stDefault;
    property Helpfile: string read fHelpfile write fHelpfile;
    property OnHelp: THelpEvent read fOnHelp write fOnHelp;
    property Version: string read GetVersion write SetVersion;
  end;

type
  { Unicode Delphi: PChar is PWideChar. Must call HtmlHelpW, not HtmlHelpA
    (A expects ANSI paths; W matches String/PChar). }
  THtmlHelpW = function(hwndCaller: THandle; pszFile: PWideChar; uCommand: Cardinal; dwData: Longint): THandle; stdcall;

var
  HtmlHelpW: THtmlHelpW;
  HHCTRL: THandle;
  GLOBAL_HELPROUTER: THTMLhelpRouter;

function LoadHHCTRL: boolean;

Function InitHTMLHelp(const HelpFileName : String) : THTMLhelpRouter;

procedure Register;

implementation

{$HINTS off}
{$WARNINGS off}

function LoadHHCTRL: boolean;
begin
  if HHCTRL = 0 then
  begin
    HtmlHelpW := nil;
    HHCTRL := LoadLibrary('HHCTRL.OCX');
    if (HHCTRL <> 0) then
      @HtmlHelpW := GetProcAddress(HHCTRL, 'HtmlHelpW');
  end;
  Result := Assigned(HtmlHelpW);
end;

function CheckRouterInstance: boolean;
begin
  result := True;
  if GLOBAL_HELPROUTER <> NIL then raise Exception.Create('Multiple instances of THTMLhelpRouter are not allowed');
end;

{ --- THTMLhelpRouter --- }

constructor THTMLhelpRouter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if CheckRouterInstance and not (csDesigning in Componentstate) then
  begin
       fAppOnHelp := Application.onhelp;
       Application.onhelp := OnRouteHelp;
       GLOBAL_HELPROUTER := Self;
  end;
  fShowType := stDefault;
end;

destructor THTMLhelpRouter.Destroy;
begin
  if not (csDesigning in Componentstate) then if assigned(fAppOnHelp) then Application.onhelp := fAppOnHelp else Application.onhelp := nil;
  GLOBAL_HELPROUTER := nil;
  inherited Destroy;
end;

function THTMLhelpRouter.CurrentForm: TForm;
begin
  if Screen.ActiveForm <> NIL then
       Result:= Screen.ActiveForm
  else Result:= Owner as TForm;
end;

procedure THTMLhelpRouter.SetHelpType(value: THelpType);
begin
     if value <> fHelpType then
     begin
          fHelpType := value;
          if fHelpType in [htAuto,htHTMLhelp] then LoadHHCTRL;
     end;
end;

function THTMLhelpRouter.HTMLhelpInstalled: boolean;
begin
  if not Assigned(HtmlHelpW) then LoadHHCTRL;
  Result := Assigned(HtmlHelpW);
end;

function THTMLhelpRouter.FindHandle(var Helphandle: HWND; var Hfile: string): boolean;
var
   CForm: TForm;
begin
   case HelpType of
      htWinhelp:  result := false;
      htHTMLhelp: result := true;
      htAuto:     result := HTMLhelpInstalled;
   end;
   HFile := Application.helpfile;
   HelpHandle := Application.handle;
{IFDEF VER100}
   CForm := CurrentForm;
   if Assigned(CForm) and CForm.HandleAllocated and (CForm.HelpFile <> '') then
   begin
       HelpHandle := CForm.Handle;
       HFile := CForm.HelpFile;
   end;
{ENDIF}
   if fHelpFile <> '' then
   begin
       HFile := fhelpfile;
       HelpHandle := Application.handle;
   end;
end;

function THTMLhelpRouter.OnRouteHelp(Command: Word; Data: Longint; var CallHelp: Boolean): Boolean;
var
   showHTML: boolean;
   rHandle: integer;
   HelpHandle: HWND;
   HFile: string;
   Topic: string;
begin
   { Always swallow VCL default help: modern Windows WinHelp opens an EOL webpage. }
   result := false;

   if assigned(fOnHelp) then result := fOnHelp(command, data, callhelp);
   if not callHelp then exit;
   if assigned(fAppOnHelp) then result := fAppOnHelp(command, data, callhelp);
   if not callHelp then exit;

   showHTML := FindHandle(HelpHandle, HFile);
   result := false;
   rHandle := 0;

   if showHTML and HTMLhelpInstalled then
   begin
     if HFile = '' then HFile := fHelpfile;
     HFile := ExpandFileName(ChangeFileExt(HFile, '.chm'));
     if (HFile <> '') and FileExists(HFile) then
     begin
       case Command of
       HELP_FINDER, HELP_CONTENTS:
         begin
           rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_TOC, 0);
           if rHandle = 0 then
             rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_TOPIC, 0);
         end;
       HELP_KEY:
         rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_INDEX, Data);
       HELP_QUIT:
         rHandle := HtmlHelpW(HelpHandle, nil, HH_CLOSE_ALL, 0);
       HELP_CONTEXT, HELP_CONTEXTPOPUP:
         begin
           { Prefer explicit topic map: MAP/ALIAS can open Menu.html which only
             meta-refreshes to index.html (wrong case) → "Can't reach this page". }
           Topic := HelpContextToTopic(Data);
           if Topic <> '' then
             rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile + '::/' + Topic), HH_DISPLAY_TOPIC, 0);
           if rHandle = 0 then
             rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_HELP_CONTEXT, Data);
           if rHandle = 0 then
             rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_TOPIC, 0);
         end;
       end;
       Result := rHandle <> 0;
     end;
   end;

   { WinHelp only when explicitly requested. Never for CHM / htAuto / htHTMLhelp:
     WinHelp on Win10+ launches Microsoft web help (end-of-life page). }
   if (not Result) and (fHelpType = htWinhelp) then
   begin
     case Command of
     HELP_SETPOPUP_POS: if fShowType = stMain then Command := 0;
     HELP_CONTEXTPOPUP: if fShowType = stMain then Command := HELP_CONTEXT;
     end;
     if Command <> 0 then
       Result := WinHelp(HelpHandle, PChar(ChangeFileExt(HFile, '.hlp')), Command, Data)
     else
       Result := True;
   end;

   CallHelp := False;
end;

function THTMLhelpRouter.HelpContent: boolean;
begin
   result := application.helpcommand(HELP_FINDER, 0);
end;

function THTMLhelpRouter.HelpJump(hfile, topicid: string): boolean;
var
   Command: array[0..255] of Char;
   showHTML: boolean;
   rHandle: integer;
   HelpHandle: HWND;
   HF, HID: string;
begin
   result := false;
   showHTML := FindHandle(HelpHandle, HF);

   if Hfile <> '' then
   begin
        HF := HFile;
        HelpHandle := 0;
   end;
   if showHTML then
   begin
     {rHandle := 0;}
     HFile := changefileext(HF,'.chm');
     HID := TopicID;
     if copy(lowercase(extractfileext(HID)),1,4) <> '.htm' then HID := HID + '.htm';
     rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile + '::/' + HID), HH_DISPLAY_TOPIC, 0);
     Result := rHandle <> 0;
   end;
   if (not result) and (fHelpType <> htHTMLhelp) then
   begin
     hfile := changefileext(HF,'.hlp');
     StrLFmt(Command, SizeOf(Command) - 1, 'JumpID("","%s")', [TopicID]);
     Result := WinHelp(HelpHandle, PChar(Hfile), HELP_CONTENTS, 0);
     if Result then Result := WinHelp(HelpHandle, PChar(hfile), HELP_COMMAND, Longint(@Command));
   end;
end;

function THTMLhelpRouter.HelpPopup(X,Y: integer; text: string): boolean;
var
   CForm: TForm;
   HP: THH_Popup;
begin
   if (fHelpType <> htWinhelp) and HTMLhelpInstalled then
   begin
     CForm := CurrentForm;
     with HP do
     begin
          cbStruct := sizeof(HP);
          hInstance := 0;
          idString := 0;
          pszText := PChar(text);
          pt.x := X;
          pt.y := Y;
          ClientToScreen(CForm.handle, pt);
          clrForeground := -1;
          clrBackground := -1;
          rcMargins.Left := -1;
          rcMargins.Right := -1;
          rcMargins.Top := -1;
          rcMargins.Bottom := -1;
          pszFont := PChar('MS Sans Serif, 10');
     end;
     Result := HtmlHelpW(CForm.Handle, nil, HH_DISPLAY_TEXT_POPUP, Longint(@HP)) <> 0;
   end
   else result := false;
end;

function THTMLhelpRouter.HelpKeyword(keyword: string): boolean;
var
  Command: array[0..255] of Char;
begin
  StrLcopy(Command, pchar(keyword), SizeOf(Command) - 1);
  result := application.helpcommand(HELP_KEY, Longint(@Command));
end;

function THTMLhelpRouter.HelpKLink(keyword: string): boolean;
var
   Command: array[0..255] of Char;
   showHTML: boolean;
   rHandle: integer;
   HelpHandle: HWND;
   HF, Hfile: string;
   HA: THH_AKLINK;
begin
   result := false;
   showHTML := FindHandle(HelpHandle, HF);

   if showHTML then
   begin
     {rHandle := 0;}
     HFile := changefileext(HF,'.chm');

     with HA do
     begin
          cbStruct := sizeof(HA);
          fReserved := false;
          pszKeywords := pchar(keyword);
          pszUrl := '';
          pszMsgText := '';
          pszMsgTitle := '';
          pszMsgWindow := '';
          fIndexOnFail := true;
     end;
     rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_TOPIC, 0);
     if rHandle <> 0 then
       rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_KEYWORD_LOOKUP, Longint(@HA));
     Result := rHandle <> 0;
   end;
   if (not result) and (fHelpType <> htHTMLhelp) then
   begin
     helpfile := changefileext(HF,'.hlp');
     StrLFmt(Command, SizeOf(Command) - 1, 'KL("%s",1)', [keyword]);
     Result := WinHelp(HelpHandle, PChar(Hfile), HELP_CONTENTS, 0);
     if Result then Result := WinHelp(HelpHandle, PChar(hfile), HELP_COMMAND, Longint(@Command));
   end;
end;

function THTMLhelpRouter.HelpALink(akeyword: string): boolean;
var
   Command: array[0..255] of Char;
   showHTML: boolean;
   rHandle: integer;
   HelpHandle: HWND;
   HF, Hfile: string;
   HA: THH_AKLINK;
begin
   result := false;
   showHTML := FindHandle(HelpHandle, HF);

   if showHTML then
   begin
     {rHandle := 0;}
     HFile := changefileext(HF,'.chm');

     with HA do
     begin
          cbStruct := sizeof(HA);
          fReserved := false;
          pszKeywords := pchar(akeyword);
          pszUrl := '';
          pszMsgText := '';
          pszMsgTitle := '';
          pszMsgWindow := '';
          fIndexOnFail := true;
     end;
     rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_DISPLAY_TOPIC, 0);
     if rHandle <> 0 then
       rHandle := HtmlHelpW(HelpHandle, PWideChar(HFile), HH_ALINK_LOOKUP, Longint(@HA));
     Result := rHandle <> 0;
   end;
   if (not result) and (fHelpType <> htHTMLhelp) then
   begin
     hfile := changefileext(HF,'.hlp');
     StrLFmt(Command, SizeOf(Command) - 1, 'AL("%s",1)', [akeyword]);
     Result := WinHelp(HelpHandle, PChar(Hfile), HELP_CONTENTS, 0);
     if Result then Result := WinHelp(HelpHandle, PChar(hfile), HELP_COMMAND, Longint(@Command));
   end;
end;

function THTMLhelpRouter.GetVersion: string;
begin
     result := cVersion;
end;
procedure THTMLhelpRouter.SetVersion(dummy: string);
begin
  {do nothing}
end;

procedure Register;
begin
  RegisterComponents('EC', [THTMLhelpRouter]);
end;

{$HINTS on}
{$WARNINGS on}

Function InitHTMLHelp(const HelpFileName : String) : THTMLhelpRouter;
begin
  result:=THTMLHelpRouter.Create(Application.MainForm);
  result.HelpType:=htHTMLhelp;
  result.Helpfile:=ExpandFileName(HelpFileName);
  Application.HelpFile:='';
end;

initialization
  HHCTRL := 0;
finalization
   if (HHCTRL <> 0) then FreeLibrary(HHCTRL);
end.
