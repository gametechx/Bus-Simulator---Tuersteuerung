unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
  private
    EditPort: TEdit;
    BtnConnect: TButton;
    ShapeStatus: TShape;
    LblStatus: TLabel;

    LblTuer1: TLabel;
    LblTuer2: TLabel;

    MemoLog: TMemo;
    Timer1: TTimer;

    FHandle: THandle;
    FConnected: Boolean;
    FRxBuffer: string;

    procedure BuildUI;
    procedure BtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    function OpenSerial(const APort: string): Boolean;
    procedure CloseSerial;
    procedure SerialSend(const ACmd: string);
    procedure ProcessLine(const ALine: string);
    procedure Log(const AText: string);

    procedure MakeTuerPanel(ATop: Integer; ATitel, APraefix: string; out ALbl: TLabel);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Form1: TForm1;

implementation

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHandle := INVALID_HANDLE_VALUE;
  FConnected := False;
  FRxBuffer := '';
  BuildUI;
end;

procedure TForm1.BuildUI;
var
  LblPort: TLabel;
begin
  Caption := 'Bus Simulator - Tuersteuerung';
  Width := 560;
  Height := 560;
  Position := poScreenCenter;

  // --- Verbindung ---
  LblPort := TLabel.Create(Self);
  LblPort.Parent := Self;
  LblPort.Left := 12;
  LblPort.Top := 16;
  LblPort.Caption := 'COM-Port:';

  EditPort := TEdit.Create(Self);
  EditPort.Parent := Self;
  EditPort.Left := 80;
  EditPort.Top := 12;
  EditPort.Width := 80;
  EditPort.Text := 'COM3';

  BtnConnect := TButton.Create(Self);
  BtnConnect.Parent := Self;
  BtnConnect.Left := 170;
  BtnConnect.Top := 10;
  BtnConnect.Width := 100;
  BtnConnect.Caption := 'Verbinden';
  BtnConnect.Name := 'BtnConnect';
  BtnConnect.OnClick := @BtnClick;

  ShapeStatus := TShape.Create(Self);
  ShapeStatus.Parent := Self;
  ShapeStatus.Left := 290;
  ShapeStatus.Top := 12;
  ShapeStatus.Width := 20;
  ShapeStatus.Height := 20;
  ShapeStatus.Shape := stCircle;
  ShapeStatus.Brush.Color := RGBToColor(255, 165, 0); // Orange

  LblStatus := TLabel.Create(Self);
  LblStatus.Parent := Self;
  LblStatus.Left := 320;
  LblStatus.Top := 16;
  LblStatus.Caption := 'Getrennt';
  LblStatus.Font.Style := [fsBold];

  // --- Tueren ---
  MakeTuerPanel(60, 'Vordere Tuer', 'TUER1', LblTuer1);
  MakeTuerPanel(220, 'Hintere Tuer', 'TUER2', LblTuer2);

  // --- Log ---
  MemoLog := TMemo.Create(Self);
  MemoLog.Parent := Self;
  MemoLog.Left := 12;
  MemoLog.Top := 380;
  MemoLog.Width := 520;
  MemoLog.Height := 150;
  MemoLog.ScrollBars := ssVertical;
  MemoLog.ReadOnly := True;
  MemoLog.Font.Name := 'Consolas';

  // --- Timer (pollt die serielle Schnittstelle) ---
  Timer1 := TTimer.Create(Self);
  Timer1.Interval := 100;
  Timer1.Enabled := False;
  Timer1.OnTimer := @Timer1Timer;

  OnClose := @FormClose;
end;

// Baut GroupBox mit Status-Label + Tuer/LED Buttons.
// Jeder Button bekommt einen Name wie 'Btn_TUER1_AUF' oder 'Btn_LED1_BLINK',
// daraus wird beim Klick direkt der Serial-Befehl abgeleitet.
procedure TForm1.MakeTuerPanel(ATop: Integer; ATitel, APraefix: string; out ALbl: TLabel);
var
  Box: TGroupBox;
  BtnAuf, BtnZu, BtnAn, BtnAus, BtnBlink: TButton;
  LedNr: string;
begin
  LedNr := Copy(APraefix, Length(APraefix), 1); // '1' oder '2'

  Box := TGroupBox.Create(Self);
  Box.Parent := Self;
  Box.Left := 12;
  Box.Top := ATop;
  Box.Width := 520;
  Box.Height := 150;
  Box.Caption := ATitel;

  ALbl := TLabel.Create(Self);
  ALbl.Parent := Box;
  ALbl.Left := 16;
  ALbl.Top := 20;
  ALbl.Caption := 'ZU';
  ALbl.Font.Size := 16;
  ALbl.Font.Style := [fsBold];

  BtnAuf := TButton.Create(Self);
  BtnAuf.Parent := Box;
  BtnAuf.Left := 150;
  BtnAuf.Top := 20;
  BtnAuf.Width := 100;
  BtnAuf.Caption := 'Tuer AUF';
  BtnAuf.Name := 'Btn_' + APraefix + '_AUF';
  BtnAuf.OnClick := @BtnClick;

  BtnZu := TButton.Create(Self);
  BtnZu.Parent := Box;
  BtnZu.Left := 260;
  BtnZu.Top := 20;
  BtnZu.Width := 100;
  BtnZu.Caption := 'Tuer ZU';
  BtnZu.Name := 'Btn_' + APraefix + '_ZU';
  BtnZu.OnClick := @BtnClick;

  BtnAn := TButton.Create(Self);
  BtnAn.Parent := Box;
  BtnAn.Left := 16;
  BtnAn.Top := 70;
  BtnAn.Width := 90;
  BtnAn.Caption := 'LED AN';
  BtnAn.Name := 'Btn_LED' + LedNr + '_AN';
  BtnAn.OnClick := @BtnClick;

  BtnAus := TButton.Create(Self);
  BtnAus.Parent := Box;
  BtnAus.Left := 116;
  BtnAus.Top := 70;
  BtnAus.Width := 90;
  BtnAus.Caption := 'LED AUS';
  BtnAus.Name := 'Btn_LED' + LedNr + '_AUS';
  BtnAus.OnClick := @BtnClick;

  BtnBlink := TButton.Create(Self);
  BtnBlink.Parent := Box;
  BtnBlink.Left := 216;
  BtnBlink.Top := 70;
  BtnBlink.Width := 90;
  BtnBlink.Caption := 'LED BLINK';
  BtnBlink.Name := 'Btn_LED' + LedNr + '_BLINK';
  BtnBlink.OnClick := @BtnClick;
end;

// Ein zentraler Click-Handler fuer ALLE Buttons.
// Der Verbinden-Button wird ueber seinen Namen erkannt, alle anderen
// leiten ihren Serial-Befehl direkt aus ihrem Namen ab (Btn_TUER1_AUF -> TUER1:AUF).
procedure TForm1.BtnClick(Sender: TObject);
var
  Btn: TButton;
  CmdName: string;
begin
  if not (Sender is TButton) then Exit;
  Btn := TButton(Sender);

  if Btn = BtnConnect then
  begin
    if FConnected then
    begin
      CloseSerial;
    end
    else
    begin
      if OpenSerial(Trim(EditPort.Text)) then
      begin
        FConnected := True;
        ShapeStatus.Brush.Color := clGreen;
        LblStatus.Caption := 'Verbunden (' + EditPort.Text + ')';
        BtnConnect.Caption := 'Trennen';
        Timer1.Enabled := True;
        Log('Verbunden mit ' + EditPort.Text);
        SerialSend('STATUS');
      end
      else
        Log('Fehler: Port ' + EditPort.Text + ' konnte nicht geoeffnet werden.');
    end;
    Exit;
  end;

  // z.B. 'Btn_TUER1_AUF' -> 'TUER1_AUF' -> 'TUER1:AUF'
  CmdName := Btn.Name;
  if Pos('Btn_', CmdName) = 1 then
  begin
    CmdName := Copy(CmdName, 5, Length(CmdName));
    CmdName := StringReplace(CmdName, '_', ':', [rfReplaceAll]);
    SerialSend(CmdName);
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  Buf: array[0..255] of Byte;
  BytesRead: DWORD;
  s: string;
  p: Integer;
  zeile: string;
begin
  if not FConnected then Exit;
  if not ReadFile(FHandle, Buf, SizeOf(Buf), BytesRead, nil) then Exit;
  if BytesRead = 0 then Exit;

  SetString(s, PAnsiChar(@Buf[0]), BytesRead);
  FRxBuffer := FRxBuffer + s;

  p := Pos(#10, FRxBuffer);
  while p > 0 do
  begin
    zeile := Copy(FRxBuffer, 1, p - 1);
    zeile := StringReplace(zeile, #13, '', [rfReplaceAll]);
    FRxBuffer := Copy(FRxBuffer, p + 1, Length(FRxBuffer));
    if zeile <> '' then
    begin
      Log('<< ' + zeile);
      ProcessLine(zeile);
    end;
    p := Pos(#10, FRxBuffer);
  end;
end;

procedure TForm1.ProcessLine(const ALine: string);
var
  parts, kv: TStringList;
  i: Integer;
begin
  if Pos('TUER1:', ALine) = 1 then
    LblTuer1.Caption := Copy(ALine, 7, Length(ALine))
  else if Pos('TUER2:', ALine) = 1 then
    LblTuer2.Caption := Copy(ALine, 7, Length(ALine))
  else if Pos('STATUS:', ALine) = 1 then
  begin
    parts := TStringList.Create;
    kv := TStringList.Create;
    try
      parts.Delimiter := ',';
      parts.StrictDelimiter := True;
      parts.DelimitedText := Copy(ALine, 8, Length(ALine));
      for i := 0 to parts.Count - 1 do
      begin
        kv.Clear;
        kv.Delimiter := '=';
        kv.StrictDelimiter := True;
        kv.DelimitedText := parts[i];
        if kv.Count = 2 then
        begin
          if kv[0] = 'TUER1' then LblTuer1.Caption := kv[1];
          if kv[0] = 'TUER2' then LblTuer2.Caption := kv[1];
        end;
      end;
    finally
      parts.Free;
      kv.Free;
    end;
  end;
end;

procedure TForm1.SerialSend(const ACmd: string);
var
  BytesWritten: DWORD;
  s: string;
begin
  if not FConnected then
  begin
    Log('Nicht verbunden!');
    Exit;
  end;
  s := ACmd + #13#10;
  WriteFile(FHandle, s[1], Length(s), BytesWritten, nil);
  Log('>> ' + ACmd);
end;

function TForm1.OpenSerial(const APort: string): Boolean;
var
  DCB: TDCB;
  Timeouts: TCommTimeouts;
  FullPort: string;
begin
  Result := False;
  FullPort := '\\.\' + APort;

  FHandle := CreateFile(PChar(FullPort), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, 0, 0);

  if FHandle = INVALID_HANDLE_VALUE then Exit;

  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  DCB.BaudRate := 115200;
  DCB.ByteSize := 8;
  DCB.Parity := 0;   // NOPARITY
  DCB.StopBits := 0; // ONESTOPBIT

  if not SetCommState(FHandle, DCB) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := 0;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := 1000;
  SetCommTimeouts(FHandle, Timeouts);

  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);

  FRxBuffer := '';
  Result := True;
end;

procedure TForm1.CloseSerial;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
  FHandle := INVALID_HANDLE_VALUE;
  FConnected := False;
  Timer1.Enabled := False;
  ShapeStatus.Brush.Color := RGBToColor(255, 165, 0); // Orange
  LblStatus.Caption := 'Getrennt';
  BtnConnect.Caption := 'Verbinden';
  Log('Verbindung getrennt');
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FConnected then CloseSerial;
end;

procedure TForm1.Log(const AText: string);
begin
  MemoLog.Lines.Add(AText);
end;

end.
