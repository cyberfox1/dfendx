unit FireDACSilentUnit;

{ Shared FireDAC UI suppression so missing vendor libs (e.g. sqlite3.dll)
  raise once instead of GUIx wait/error dialog spam. }

interface

procedure EnsureFireDACSilent;

implementation

uses
  FireDAC.Comp.Client;

var
  FireDACSilentConfigured: Boolean = False;

procedure EnsureFireDACSilent;
begin
  if FireDACSilentConfigured then
    Exit;
  { Public API on this RAD: TFDCustomManager.SilentMode.
    (Older samples used FDGUIxSilentMode — not declared in Studio 23 FireDAC.UI.Intf.) }
  FDManager.SilentMode := True;
  FireDACSilentConfigured := True;
end;

end.
