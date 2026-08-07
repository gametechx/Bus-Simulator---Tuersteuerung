program BusSteuerung;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, Unit1;

{$R *.res}

begin
  Application.Title := 'Bus Simulator - Tuersteuerung';
  Application.Scaled := True;
  RequireDerivedFormResource := False;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
