unit consoleCheckerThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, DateUtils;

type TConsoleCheckerThread = class(TThread)
  private
    FStates: array[0..3] of integer;
    FLastSeen: array[0..3] of TDateTime;
    FShouldStop: boolean;
    procedure checkConsole(num: integer);
    function getConsoleState(index:integer): integer;
  protected
    procedure Execute; override;
  public
    property states[index:integer]: integer read getConsoleState;
    property shouldStop: boolean read FShouldStop write FShouldStop default false;
    procedure seenConsole(id: integer);
  const
    CONSOLE_RUNNING = 0;
    CONSOLE_UNKNOWN = 1;
    CONSOLE_UP = 2;
    CONSOLE_DOWN = 3;
    THRESHOLD = 5;
  end;

implementation

function TConsoleCheckerThread.getConsoleState(Index:integer):integer;
begin
  result := FStates[index];
end;

procedure TConsoleCheckerThread.seenConsole(id: integer);
begin
  FLastSeen[id] := now;
  FStates[id] := CONSOLE_RUNNING;
end;

procedure TConsoleCheckerThread.checkConsole(num: integer);
var pingProc: TProcess;
begin
  if SecondsBetween(FLastSeen[num], now) > THRESHOLD then begin
    // If we haven't seen a console for a while, ping it to see if it is still
    // there. (Or if we've never seen it, ping it to see if it's there now)
    pingProc := TProcess.create(nil);
    pingProc.Executable:='/bin/ping';
    pingProc.Parameters.Add('192.168.1.3' + inttostr(num+1));
    pingProc.Parameters.Add('-w1');
    pingProc.Parameters.Add('-c1');
    pingProc.Parameters.Add('-q');
    pingProc.Options := pingProc.Options + [poWaitOnExit];
    pingProc.Execute;
    if (pingProc.ExitStatus <> 0) then
      FStates[num] := CONSOLE_DOWN
    else
      FStates[num] := CONSOLE_UP;
    pingProc.free();
  end;
end;

procedure TConsoleCheckerThread.Execute;
var i: integer;
begin
  for i:= 0 to 3 do begin
    FStates[i] := CONSOLE_UNKNOWN;
    FLastSeen[i] := 0;
  end;
  while not FShouldStop do begin
    for i:= 0 to 3 do
      checkConsole(i);
    Sleep(3000);
  end;
end;

end.

