unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, kpScope, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Scope1: TkpScope;
    Timer1: TTimer;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  count: integer;

implementation

{$R *.DFM}

function Func(CurveNo: integer; X: double) : double;
begin
  Result := 0;   
  case CurveNo of
     1:  Result := 50+ (10*sin(count/40)+20)*sin(count/100);
     2:  Result := 70+ (10*sin(count/260)+20)*sin(count/80);
     3:  Result := 30 - (10*sin(count/75)+10)*sin(count/15);
     4:  Result := 60 + (5*sin(count/30)+10)*sin(count/20);
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var i: integer;
begin
   for i:=0 to 30 do begin
       Inc(count,1);
       Scope1.ShowPoint(1,count,round(Func(1,count)));
       Scope1.ShowPoint(2,count,round(Func(2,count)));
       Scope1.ShowPoint(3,count,round(Func(3,count)));
       Scope1.ShowPoint(4,count,round(Func(4,count)));
    end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
    Scope1.Colors[1] := clRed;
    Scope1.Colors[2] := clLime;
    Scope1.Colors[3] := clAqua;
    Scope1.Colors[4] := clNavy;
    Scope1.StartFrom(1,count,round(Func(1,count)));
    Scope1.StartFrom(2,count,round(Func(2,count)));
    Scope1.StartFrom(3,count,round(Func(3,count)));
    Scope1.StartFrom(4,count,round(Func(4,count)));
    Timer1.Enabled := True;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    Timer1.Enabled := False;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
    Button2Click(Sender); 
    count := 1;
    Scope1.Reset;
end;

end.
