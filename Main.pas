unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, ShellAPI,
  Vcl.Forms, Vcl.ImgList, Vcl.Controls, Vcl.Menus, Data.DB, Data.Win.ADODB, Vcl.Grids,
  Vcl.DBGrids, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    StatusBar1: TStatusBar;
    Host: TEdit;
    Label1: TLabel;
    KillBtn: TButton;
    GetBtn: TButton;
    CSVConn: TADOConnection;
    Query: TADOQuery;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    PopupMenu1: TPopupMenu;
    KillThis1: TMenuItem;
    ImageList1: TImageList;
    ExitBtn: TButton;
    procedure GetBtnClick(Sender: TObject);
    procedure ShellExecuteAndWait(FileName: string; param:String);
    procedure KillBtnClick(Sender: TObject);
    procedure KillRemoteProcess;
    procedure FormCreate(Sender: TObject);
    procedure FormattingGrid;
    procedure KillThis1Click(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
    procedure DBGrid1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HostKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure GetRemoteProcesses;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1   : TForm1;
  HostName: String;

implementation

{$R *.dfm}


procedure TForm1.DBGrid1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 46 then KillRemoteProcess;
end;

procedure TForm1.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.FormattingGrid;
begin
  DBGrid1.Columns[0].Width            := 200;
  DBGrid1.Columns[0].Title.Alignment  := taCenter;

  DBGrid1.Columns[1].Width            := 40;
  DBGrid1.Columns[1].Title.Alignment  := taCenter;
  DBGrid1.Columns[1].Alignment        := taCenter;

  DBGrid1.Columns[2].Visible := false;
  DBGrid1.Columns[3].Visible := false;

  DBGrid1.Columns[4].Width            := 90;
  DBGrid1.Columns[4].Title.Alignment  := taCenter;
  DBGrid1.Columns[4].Alignment        := taRightJustify;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CSVConn.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' + ExtractFilePath(Application.ExeName) +
                              ';Persist Security Info=False;Extended Properties="text;HDR=YES;FMT=Delimited"';
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 116 then GetRemoteProcesses;
end;

procedure TForm1.GetRemoteProcesses;
var
  Command: string;
begin
  if Host.Text = '' then Host.Text := '127.0.0.1';
  try
    HostName := Host.Text;
    Command := '/c @echo off && chcp 1251 && tasklist /fo csv /s ' + HostName + ' > RemoteHostProcesses.txt && @echo on';
    ShellExecuteAndWait('cmd', Command);
    Query.Close;
    Query.SQL.Text := 'select * from RemoteHostProcesses.txt order by 1';
    Query.Open;
    FormattingGrid;
    DBGrid1.SetFocus;
  except
    MessageBox(Application.Handle, 'Ошибка! Проверьте введённые данные.', 'Ошибка', MB_OK + MB_ICONERROR);
  end;
  StatusBar1.Panels[0].Text := 'Активных процессов: ' + IntToStr(Query.RecordCount);
end;

procedure TForm1.HostKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then GetRemoteProcesses;
end;

procedure TForm1.GetBtnClick(Sender: TObject);
begin
  GetRemoteProcesses;
end;

procedure TForm1.KillBtnClick(Sender: TObject);
begin
  KillRemoteProcess;
end;

procedure TForm1.KillRemoteProcess;
var
  PID: String;
  Command: String;
begin
  case MessageBox(Application.Handle, PWideChar('Вы действительно хотите завершить "' + DBGrid1.Fields[0].AsString + '"?'), 'Kill Remote Process', MB_YESNO + MB_ICONQUESTION) of
    IDNO: exit;
  end;
  try
    PID     := DBGrid1.Fields[1].AsString;
    Command := '/c taskkill /t /f /s ' + HostName + ' /PID ' + PID;

    ShellExecuteAndWait('cmd', Command);

    GetBtn.Click;
  except

  end;
end;

procedure TForm1.KillThis1Click(Sender: TObject);
begin
  KillRemoteProcess;
end;

procedure TForm1.ShellExecuteAndWait(FileName, param: String);
var
  exInfo: TShellExecuteInfo;
  Ph: DWORD;
begin
  FillChar(exInfo, SizeOf(exInfo), 0);
  with exInfo do
  begin
    cbSize        := SizeOf(exInfo);
    fMask         := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT;
    Wnd           := GetActiveWindow();
    ExInfo.lpVerb := 'open';
    lpFile        := PChar(FileName);
    lpparameters  := pchar(param);
    nShow         := SW_HIDE;
  end;
  if ShellExecuteEx(@exInfo) then
  begin
    Ph := exInfo.HProcess;
  end
  else
    Exit;
  while WaitForSingleObject(ExInfo.hProcess, 50) <> WAIT_OBJECT_0 do
  begin
    Form1.Enabled := false;
    Form1.Cursor  := crHourGlass;
  end;
  CloseHandle(Ph);
  Form1.Cursor  := crDefault;
  Form1.Enabled := true;
end;

end.
