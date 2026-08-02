unit ThumbnailPoolUnit;

interface

uses
  Windows, Classes, SysUtils;

const
  POOL_IDLE_MS_DEFAULT = 30000;
  PASS_SIZE_2MB  = 2 * 1024 * 1024;
  PASS_SIZE_4MB  = 4 * 1024 * 1024;
  PASS_SIZE_20MB = 20 * 1024 * 1024;

type
  TImageEntry = record
    FullPath: String;
    FileSize: Int64;
    FileDate: TDateTime;
  end;
  TImageEntryList = array of TImageEntry;

  IThumbnailCache = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Lookup(const CacheKey: String; W, H: Integer;
      var StoredSize: Int64; var StoredDate: TDateTime): Boolean;
    procedure Store(const CacheKey: String; W, H: Integer;
      FileSize: Int64; FileDate: TDateTime; const Data: TMemoryStream);
    procedure Remove(const CacheKey: String);
  end;

  IThumbnailGenerator = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function Generate(const FileName: String; W, H: Integer): TMemoryStream;
  end;

  IGameImageProvider = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function GetGameCount: Integer;
    function GetImages(GameIndex: Integer; out Images: TImageEntryList): Boolean;
  end;

  TThumbnailSizes = array of Integer;

  TThumbnailPool = class
  public
    type
      TThumbnailWorker = class(TThread)
      private
        FPool: TThumbnailPool;
        FSkippedDueToLock: Boolean;
        FHadWork: Boolean;
        function TryLockGame(Index: Integer): Boolean;
        procedure UnlockGame(Index: Integer);
        procedure ProcessGame(Index: Integer);
        procedure ProcessImage(const Entry: TImageEntry);
        function ImageNeedsCache(const CacheKey: String; W, H: Integer;
          const Entry: TImageEntry): Boolean;
      protected
        procedure Execute; override;
      public
        constructor Create(APool: TThumbnailPool);
      end;
  private
    FWorkers: array of TThumbnailWorker;
    FLocks: array of Integer;
    FWorkerCount: Integer;
    FPass: Integer;
    FWorkersInPass: Integer;
    FCache: IThumbnailCache;
    FGenerator: IThumbnailGenerator;
    FProvider: IGameImageProvider;
    FSizes: TThumbnailSizes;
    FActive: Boolean;
    FIdleSleepMs: Integer;
    procedure GrowLocks(const NewCount: Integer);
    function GetPassSizeLimit: Int64;
  public
    constructor Create(const AWorkerCount: Integer;
      const ACache: IThumbnailCache;
      const AGenerator: IThumbnailGenerator;
      const AProvider: IGameImageProvider;
      const ASizes: TThumbnailSizes);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property Active: Boolean read FActive;
    property IdleSleepMs: Integer read FIdleSleepMs write FIdleSleepMs;
  end;

function MakeCacheKey(const FullPath: String): String;

implementation

function MakeCacheKey(const FullPath: String): String;
var
  Expanded: String;
begin
  Expanded := ExpandFileName(FullPath);
  if (Length(Expanded) >= 2) and (Expanded[1] = '\') and (Expanded[2] = '\') then
    Result := Expanded
  else
    Result := Copy(Expanded, 3, MaxInt);
end;

{ TThumbnailPool }

constructor TThumbnailPool.Create(const AWorkerCount: Integer;
  const ACache: IThumbnailCache;
  const AGenerator: IThumbnailGenerator;
  const AProvider: IGameImageProvider;
  const ASizes: TThumbnailSizes);
begin
  inherited Create;
  FWorkerCount := AWorkerCount;
  if FWorkerCount < 1 then FWorkerCount := 1;
  FCache := ACache;
  FGenerator := AGenerator;
  FProvider := AProvider;
  SetLength(FSizes, Length(ASizes));
  if Length(ASizes) > 0 then
    Move(ASizes[0], FSizes[0], Length(ASizes) * SizeOf(Integer));
  FPass := 0;
  FWorkersInPass := 0;
  FActive := False;
  FIdleSleepMs := POOL_IDLE_MS_DEFAULT;
  SetLength(FLocks, 0);
  SetLength(FWorkers, 0);
end;

destructor TThumbnailPool.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TThumbnailPool.Start;
var
  I: Integer;
begin
  if FActive then Exit;
  FActive := True;
  FPass := 0;
  FWorkersInPass := FWorkerCount;

  GrowLocks(FProvider.GetGameCount);

  SetLength(FWorkers, FWorkerCount);
  for I := 0 to FWorkerCount - 1 do
    FWorkers[I] := TThumbnailWorker.Create(Self);
end;

procedure TThumbnailPool.Stop;
var
  I: Integer;
begin
  if not FActive then Exit;
  FActive := False;

  for I := 0 to FWorkerCount - 1 do
    if Assigned(FWorkers[I]) then
      FWorkers[I].Terminate;

  for I := 0 to FWorkerCount - 1 do
    if Assigned(FWorkers[I]) then begin
      FWorkers[I].WaitFor;
      FWorkers[I].Free;
    end;

  SetLength(FWorkers, 0);
  SetLength(FLocks, 0);
end;

procedure TThumbnailPool.GrowLocks(const NewCount: Integer);
var
  OldLen, I: Integer;
begin
  OldLen := Length(FLocks);
  if NewCount <= OldLen then Exit;
  SetLength(FLocks, NewCount);
  for I := OldLen to NewCount - 1 do
    FLocks[I] := 0;
end;

function TThumbnailPool.GetPassSizeLimit: Int64;
begin
  case FPass of
    0: Result := PASS_SIZE_2MB;
    1: Result := PASS_SIZE_4MB;
    2: Result := PASS_SIZE_20MB;
  else
    Result := MaxInt;
  end;
end;

{ TThumbnailPool.TThumbnailWorker }

constructor TThumbnailPool.TThumbnailWorker.Create(APool: TThumbnailPool);
begin
  FPool := APool;
  FSkippedDueToLock := False;
  FHadWork := False;
  FreeOnTerminate := False;
  inherited Create(False);
end;

function TThumbnailPool.TThumbnailWorker.TryLockGame(Index: Integer): Boolean;
begin
  if Index >= Length(FPool.FLocks) then Exit(False);
  Result := InterlockedExchange(FPool.FLocks[Index], 1) = 0;
end;

procedure TThumbnailPool.TThumbnailWorker.UnlockGame(Index: Integer);
begin
  if Index < Length(FPool.FLocks) then
    FPool.FLocks[Index] := 0;
end;

procedure TThumbnailPool.TThumbnailWorker.Execute;
var
  GameCount, I, CurrentPass, Elapsed, Chunk: Integer;
  IdleEmptyPass: Boolean;
begin
  while not Terminated do begin
    FSkippedDueToLock := False;
    FHadWork := False;

    GameCount := FPool.FProvider.GetGameCount;
    FPool.GrowLocks(GameCount);

    for I := 0 to GameCount - 1 do begin
      if Terminated then Break;

      if not TryLockGame(I) then begin
        FSkippedDueToLock := True;
        Continue;
      end;

      try
        if not Terminated then
          ProcessGame(I);
      finally
        UnlockGame(I);
      end;
    end;

    if Terminated then Break;

    CurrentPass := FPool.FPass;

    if InterlockedDecrement(FPool.FWorkersInPass) = 0 then begin
      InterlockedIncrement(FPool.FPass);
      FPool.FWorkersInPass := FPool.FWorkerCount;
    end;

    while (CurrentPass = FPool.FPass) and (not Terminated) do
      Sleep(1);

    if Terminated then Break;

    IdleEmptyPass := (not FSkippedDueToLock) and (not FHadWork) and (CurrentPass >= 3);

    if IdleEmptyPass then begin
      Elapsed := 0;
      while (not Terminated) and (Elapsed < FPool.FIdleSleepMs) do begin
        Chunk := 50;
        if Elapsed + Chunk > FPool.FIdleSleepMs then
          Chunk := FPool.FIdleSleepMs - Elapsed;
        Sleep(Chunk);
        Inc(Elapsed, Chunk);
      end;
    end;
  end;
end;

procedure TThumbnailPool.TThumbnailWorker.ProcessGame(Index: Integer);
var
  Images: TImageEntryList;
  J: Integer;
begin
  if not FPool.FProvider.GetImages(Index, Images) then Exit;

  for J := Low(Images) to High(Images) do begin
    if Terminated then Break;
    ProcessImage(Images[J]);
  end;
end;

procedure TThumbnailPool.TThumbnailWorker.ProcessImage(const Entry: TImageEntry);
var
  CacheKey: String;
  SizeI, W, H: Integer;
  Data: TMemoryStream;
  PassSizeLimit: Int64;
begin
  CacheKey := MakeCacheKey(Entry.FullPath);
  PassSizeLimit := FPool.GetPassSizeLimit;

  for SizeI := Low(FPool.FSizes) to High(FPool.FSizes) do begin
    if Terminated then Break;

    W := FPool.FSizes[SizeI];
    H := FPool.FSizes[SizeI];

    if not ImageNeedsCache(CacheKey, W, H, Entry) then Continue;
    if Entry.FileSize > PassSizeLimit then Continue;

    Data := FPool.FGenerator.Generate(Entry.FullPath, W, H);
    if Data = nil then Continue;

    try
      FPool.FCache.Store(CacheKey, W, H, Entry.FileSize, Entry.FileDate, Data);
      FHadWork := True;
    finally
      Data.Free;
    end;
  end;
end;

function TThumbnailPool.TThumbnailWorker.ImageNeedsCache(const CacheKey: String;
  W, H: Integer; const Entry: TImageEntry): Boolean;
var
  StoredSize: Int64;
  StoredDate: TDateTime;
begin
  if not FPool.FCache.Lookup(CacheKey, W, H, StoredSize, StoredDate) then
    Exit(True);
  if StoredSize <> Entry.FileSize then
    Exit(True);
  if Abs(StoredDate - Entry.FileDate) >= 1e-6 then
    Exit(True);
  Result := False;
end;

end.
