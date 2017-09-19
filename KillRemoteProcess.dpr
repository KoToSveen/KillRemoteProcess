program KillRemoteProcess;

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Kill Remote Process';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
