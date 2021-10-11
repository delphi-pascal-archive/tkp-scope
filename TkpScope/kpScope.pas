unit kpScope;
{
    TkpScope  верси€ 1.1

    компонент, позвол€ющий имитировать экран осциллографа
    поддерживает до 10 кривых с общей осью абсцисс
    —овместимость: Delphi 3+

    Copyright (C) Konstantin Polyakov, 1998-20002
    FIDO 2:5030/542
    e-mail: kpolyakov@mail.ru
    http://kpolyakov.newmail.ru
    http://kpolyakov.narod.ru

—войства
    property  Pen: TPen;                        стиль линий
    property  Brush;                            фон рабочей части
    property  TextBrush;                        фон тесктовых меток
    property  Font;                             шрифт текстовых меток
    property  MaxCurves: integer;               количество кривых
    property  Colors[Index: integer]: TColor;   цвета кривых
    property  MinX: double;                     минимальное значение X
    property  MinY: double;                     минимальное значение Y
    property  RangeX: double;                   диапазон по оси X
    property  RangeY: double;                   диапазон по оси Y
    property  GridX: double;                    шаг разметки по оси X
    property  GridY: double;                    шаг разметки по оси Y
    property  TickX: double;                    шаг промежуточных маркеров по оси X
    property  TickY: double;                    шаг промежуточных маркеров по оси Y
    property  LeftMargin: integer;              левое поле
    property  RightMargin: integer;             правое поле
    property  TopMargin: integer;               верхнее поле
    property  BottomMargin: integer;            нижнее поле

ћетоды
    procedure  StartFrom(CurveNo, X, Y: integer); начальна€ точка дл€ кривой CurveNo
    procedure  ShowPoint(CurveNo, X, Y: integer); добавить точку дл€ кривой CurveNo
    procedure  Reset;                             сброс
}

{$R-}
interface

uses Windows, Classes, Graphics, Controls;

const
    LimitCurves = 10;

type
  TkpScope = class(TGraphicControl)
  private
    FPen:           TPen;
    FBrush:     TBrush;
    FTextBrush: TBrush;
    FBackColor: TColor;
    FFont:      TFont;
    FMaxCurves: integer;
    FColors: array[1..LimitCurves] of TColor;
    FMinX:      double;
    FMinXShift: double;
    FMinY:      double;
    FRangeX:    double;
    FRangeY:    double;
    FGridX:     double;
    FGridY:     double;
    FTickX:     double;
    FTickY:     double;
    FPrevX:     array[1..LimitCurves] of integer;
    FPrevY:     array[1..LimitCurves] of integer;
    FLeftMargin:  integer;
    FRightMargin: integer;
    FTopMargin: integer;
    FBottomMargin: integer;
    FSaveImage: TBitmap;
    FBoxRect:   TRect;
    FScaleRect: TRect;
    Kx, Ky:             double;
    scrollFlag: Boolean;
    FirstGrid:  double;
    LastGrid:   double;
    LastTick:   double;
    Loaded:     Boolean;
    FontMargin: integer;
    { Private declarations }
    procedure SetPen(Value: TPen);
    procedure SetBrush(Value: TBrush);
    procedure SetTextBrush(Value: TBrush);
    procedure SetFont(Value: TFont);
    procedure SetMaxCurves(Value: integer);
    function  GetColor(Index: integer): TColor;
    procedure SetColor(Index: integer; Value: TColor);
    procedure SetMinX(Value: double);
    procedure SetRangeX(Value: double);
    procedure SetTickX(Value: double);
    procedure SetGridX(Value: double);
    procedure SetMinY(Value: double);
    procedure SetRangeY(Value: double);
    procedure SetTickY(Value: double);
    procedure SetGridY(Value: double);
    procedure SetLeftMargin(Value: integer);
    procedure SetRightMargin(Value: integer);
    procedure SetTopMargin(Value: integer);
    procedure SetBottomMargin(Value: integer);
    function  XToScreen(X: double): integer;
    function  YToScreen(Y: double): integer;
  protected
    procedure  Paint; override;
    procedure  Restore;
    procedure  Initialize;
    procedure  StyleChanged(Sender: TObject);
    procedure  ScrollTo (CurveNo, X: integer);
  public
    { Public declarations }
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure  StartFrom(CurveNo, X, Y: integer);
    procedure  ShowPoint(CurveNo, X, Y: integer);
    procedure  Reset;
    property  Colors[Index: integer]: TColor read GetColor write SetColor;
  published
    property  Pen: TPen read FPen write SetPen;
    property  Brush: TBrush read FBrush write SetBrush;
    property  TextBrush: TBrush read FTextBrush write SetTextBrush;
    property  Font: TFont read FFont write SetFont;
    property  MaxCurves: integer read FMaxCurves write SetMaxCurves;
    // property  Colors[Index: integer]: TColor read GetColor write SetColor;
    property  MinX: double read FMinX write SetMinX;
    property  MinY: double read FMinY write SetMinY;
    property  RangeX: double read FRangeX write SetRangeX;
    property  RangeY: double read FRangeY write SetRangeY;
    property  TickX: double read FTickX write SetTickX;
    property  TickY: double read FTickY write SetTickY;
    property  GridX: double read FGridX write SetGridX;
    property  GridY: double read FGridY write SetGridY;
    property  LeftMargin: integer read FLeftMargin write SetLeftMargin;
    property  RightMargin: integer read FRightMargin write SetRightMargin;
    property  TopMargin: integer read FTopMargin write SetTopMargin;
    property  BottomMargin: integer read FBottomMargin
                                    write SetBottomMargin;
end;

procedure Register;

implementation

uses Consts, SysUtils;

type
    THackTControl = class (TControl)
    public
      property Color;
    end;

{*********************************************************************}
constructor TkpScope.Create (AOwner: TComponent);
var i: integer;
begin
  inherited Create(AOwner);  { Call inherited constructor ! }

  Loaded := False;

  Width := 400;
  Height := 100;

  FMinX := 0;
  FRangeX := 100;
  FGridX := 10;
  FTickX := 2;

  FMinY := 0;
  FRangeY := 100;
  FGridY := 50;
  FTickY := 10;

  FMaxCurves := 1;

  FPen := TPen.Create;
  FPen.OnChange := StyleChanged;

  FBrush := TBrush.Create;
  FBrush.OnChange := StyleChanged;

  FTextBrush := TBrush.Create;
  FTextBrush.OnChange := StyleChanged;
  FTextBrush.Color := clBtnFace;

  FSaveImage := TBitmap.Create;

  FFont := TFont.Create;
  FFont.OnChange := StyleChanged;
  FontMargin := 5;

  for i:=0 to LimitCurves do
        FColors[i] := clBlack;
end;

{*********************************************************************}
destructor TkpScope.Destroy;
begin
  FPen.Free;      { Free allocated resources }
  FBrush.Free;
  FTextBrush.Free;
  FFont.Free;
  inherited Destroy;  { Call inherited destructor ! }
end;

{*********************************************************************}
procedure TkpScope.SetMinX(Value: double);
begin
    if FMinX <> Value then begin
        FMinX := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetRangeX(Value: double);
begin
   if FRangeX <> Value then begin
        FRangeX := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetTickX(Value: double);
begin
    if FTickX <> Value then begin
        FTickX := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetGridX(Value: double);
begin
    if FGridX <> Value then begin
        FGridX := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetMinY(Value: double);
begin
   if FMinY <> Value then begin
        FMinY := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetRangeY(Value: double);
begin
    if FRangeY <> Value then begin
        FRangeY := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetTickY(Value: double);
begin
   if FTickY <> Value then begin
        FTickY := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetGridY(Value: double);
begin
    if FGridY <> Value then begin
        FGridY := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetLeftMargin(Value: integer);
begin
    if FLeftMargin <> Value then begin
        FLeftMargin := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetRightMargin(Value: integer);
begin
    if FRightMargin <> Value then begin
        FRightMargin := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetTopMargin(Value: integer);
begin
    if FTopMargin <> Value then begin
        FTopMargin := Value;
        Initialize;
        Invalidate;
    end;
end;
{*********************************************************************}
procedure TkpScope.SetBottomMargin(Value: integer);
begin
    if FBottomMargin <> Value then begin
        FBottomMargin := Value;
        Initialize;
        Invalidate;
    end;
end;

{*********************************************************************}
function  TkpScope.XToScreen(X: double): integer;
begin
        Result := FBoxRect.Left+round(Kx*(X-FMinXShift));
end;
{*********************************************************************}
function  TkpScope.YToScreen(Y: double): integer;
begin
        Result := FBoxRect.Bottom-round(Ky*(Y-FMinY));
end;

{*********************************************************************}
procedure  TkpScope.Restore;
begin
  BitBlt(Canvas.Handle, 0, 0, Width, Height,
         FSaveImage.Canvas.Handle, 0, 0, SRCCOPY );
end;

{*********************************************************************}
procedure  TkpScope.StartFrom(CurveNo, X, Y: integer);
  procedure MovePointOn(C: TCanvas);
  begin
    C.MoveTo(FPrevX[CurveNo],FPrevY[CurveNo]);
  end;
begin
    ScrollFlag := False;
    ScrollTo(CurveNo, X);
    FPrevX[CurveNo] := XToScreen(X);
    FPrevY[CurveNo] := YToScreen(Y);
    MovePointOn(FSaveImage.Canvas);
//    MovePointOn(Canvas);
    Restore;
end;

{*********************************************************************}
procedure  TkpScope.ShowPoint(CurveNo, X, Y: integer);
  procedure MovePointOn(C: TCanvas);
  begin
    C.MoveTo(FPrevX[CurveNo],FPrevY[CurveNo]);
  end;
  procedure ShowPointOn(C: TCanvas);
  begin
    with C do begin
        Pen.Color := Colors[CurveNo];
        LineTo(FPrevX[CurveNo],FPrevY[CurveNo]);
    end;
  end;
begin
    ScrollFlag := False;
    MovePointOn(FSaveImage.Canvas);
    MovePointOn(Canvas);
    ScrollTo(CurveNo, X);
    FPrevX[CurveNo] := XToScreen(X);
    FPrevY[CurveNo] := YToScreen(Y);
    ShowPointOn(FSaveImage.Canvas);
//    ShowPointOn(Canvas);
    Restore;
end;
{*********************************************************************}
procedure  TkpScope.ScrollTo (CurveNo, X: integer);
var     ScreenShiftX, ScreenX, nCurve: integer;

  procedure ScrollOn(C: TCanvas; DoMemory: Boolean);
  var X, tempFirstGrid, tempLastGrid: double;
      {ScreenXMin, } ScreenXMax: integer;
      XLabel: string;
      rct, rct1: TRect;
  begin
     with FBoxRect, C do begin
        rct := Rect(Left+1, Top, Right+1, Bottom+FontMargin);
        ScrollDC(Handle, -ScreenShiftX, 0, rct, rct, 0, @rct1);
//        BitBlt(Handle,
//            Left+1,Top, Right-Left-ScreenShiftX,
//            Bottom-Top+FontMargin,
//            Handle,
//            Left+ScreenShiftX+1,Top,SRCCOPY);

        Pen.Color := FPen.Color;
        MoveTo(Left+ScreenShiftX+1,Top);
        LineTo(Right+1,Top);

        Brush.Color := FBrush.Color;
        Font.Name := FFont.Name;
        Font.Style := FFont.Style;
        Font.Size := FFont.Size;
        Font.CharSet := FFont.CharSet;

        FillRect(Rect(Right-ScreenShiftX+1,Top+1,Right+1,Bottom));
        Brush.Color := FBackColor;
        FillRect(Rect(Right-ScreenShiftX+1,Bottom+1,Right+1,
                                        Bottom+FontMargin));

        ScreenX := XToScreen(LastTick);
        Pen.Color := FPen.Color;
        MoveTo(ScreenX,Bottom);
        LineTo(Right,Bottom);

        X := LastTick;
        while X <= (FMinXShift + FRangeX) do begin
            ScreenX := XToScreen(X);
            MoveTo(ScreenX,FBoxRect.Bottom);
            LineTo(ScreenX,FBoxRect.Bottom+3);
            {if DoMemory then} LastTick := X;
            X := X + FTickX;
        end;

        tempFirstGrid := FirstGrid;
        tempLastGrid := LastGrid;

        X := FirstGrid;
        while(X < FMinXShift) do begin
            ScreenX := XToScreen(X)+ScreenShiftX;
            XLabel := Format('%g',[X]);
            Brush.Color := FBackColor;
            FillRect(
                Rect(ScreenX-TextWidth(XLabel) div 2 - 1,
                    FBoxRect.Bottom+FontMargin  ,
                    ScreenX+TextWidth(XLabel) div 2 + 1,
                    FBoxRect.Bottom+FontMargin+TextHeight(XLabel)));
            X := X + FGridX;
            tempFirstGrid := X;
        end;
        if tempLastGrid < tempFirstGrid then
           tempLastGrid := tempFirstGrid;

//        XLabel := Format('%g',[tempFirstGrid]);
//        ScreenXMin := XToScreen(tempFirstGrid) - (TextWidth(XLabel) div 2)
//                      - ScreenShiftX - 5;
        XLabel := Format('%g',[LastGrid]);
        ScreenXMax := XToScreen(LastGrid) + (TextWidth(XLabel) div 2) + 5;

        rct := Rect(0, Bottom+FontMargin, Width,
                       Bottom+FontMargin+TextHeight(XLabel)+2);
        ScrollDC(Handle, -ScreenShiftX, 0, rct, rct, 0, @rct1);

        Brush.Color := FBackColor;
        ScreenX := ScreenXMax+ScreenShiftX;
        FillRect(Rect(
                Width-ScreenShiftX,Bottom+FontMargin,
                Width,Bottom+FontMargin+TextHeight(XLabel)+2));

        X := tempLastGrid;
        while X <= (FMinXShift + FRangeX) do begin
            ScreenX := XToScreen(X);
            MoveTo(ScreenX,FBoxRect.Bottom);
            LineTo(ScreenX,FBoxRect.Bottom+FontMargin);
            XLabel := Format('%g',[X]);
            Brush.Color := FTextBrush.Color;
            SetTextColor(Handle,FFont.Color);
            TextOut(ScreenX-TextWidth(XLabel) div 2,
                    FBoxRect.Bottom+FontMargin, XLabel );
            tempLastGrid := X;
            X := X + FGridX;
        end;

        if True {DoMemory} then begin
                FirstGrid := tempFirstGrid;
                LastGrid := tempLastGrid;
        end;

        MoveTo(FPrevX[CurveNo]-ScreenShiftX,FPrevY[CurveNo]);
    end;
  end;
begin
    ScreenX := XToScreen(X);
    ScreenShiftX := ScreenX - FBoxRect.Right;
    if ScreenShiftX > 0 then begin
        FMinXShift := FMinXShift + ScreenShiftX / Kx;
        if ScreenShiftX > FBoxRect.Right-FBoxRect.Left+1 then
           ScreenShiftX := FBoxRect.Right-FBoxRect.Left+1;
        ScrollOn(FSaveImage.Canvas,False);
//        ScrollOn(Canvas,True);
        ScrollFlag := True;
        for nCurve:=1 to FMaxCurves do
           Dec(FPrevX[nCurve],ScreenShiftX);
    end;
end;

{*********************************************************************}
procedure  TkpScope.Reset;
begin
    Initialize;
    Invalidate;
end;

{*********************************************************************}
procedure  TkpScope.Initialize;
var ScreenX, ScreenY: integer;
    X, Y: double;
    XLabel, YLabel: string;
begin

        if LeftMargin=0   then FLeftMargin := 15;
        if RightMargin=0  then FRightMargin := 10;
        if TopMargin=0    then FTopMargin := 2;
        if BottomMargin=0 then FBottomMargin := 20;

        FBoxRect := Rect(LeftMargin,FTopMargin,Width-FRightMargin-1,
                                        Height-FBottomMargin);
        FScaleRect := Rect(FBoxRect.Left,FBoxRect.Bottom,
                           FBoxRect.Right,0);

        Kx := (FBoxRect.Right - FBoxRect.Left)/ FRangeX;
        Ky := (FBoxRect.Bottom - FBoxRect.Top)/ FRangeY;

        FSaveImage.Width := Width;
        FSaveImage.Height := Height;

        FBackColor := THackTControl(Parent).Color;

        with FSaveImage.Canvas do begin
          Brush.Color := FBackColor;
          FillRect(Rect(0,0,Width,Height));
          Brush.Color := FBrush.Color;
          Pen.Color := FPen.Color;
          SettextColor(Handle,FFont.Color);
          Rectangle(FBoxRect.Left, FBoxRect.Top,
                          FBoxRect.Right+2, FBoxRect.Bottom+1);
          Brush.Color := FTextBrush.Color;

          Font.Name := FFont.Name;
          Font.Style := FFont.Style;
          Font.Size := FFont.Size;
          Font.CharSet := FFont.CharSet;
          FontMargin := (TextHeight('0') div 2) + 1;

          X := FMinX;
          FMinXShift := FMinX;
          FirstGrid := FMinX;
          while X <= (FMinXShift + FRangeX) do begin
              ScreenX := XToScreen(X);
              MoveTo(ScreenX,FBoxRect.Bottom);
              LineTo(ScreenX,FBoxRect.Bottom+FontMargin);
              XLabel := Format('%g',[X]);
              SettextColor(Handle,FFont.Color);
              TextOut(ScreenX-TextWidth(XLabel) div 2,
                    FBoxRect.Bottom+FontMargin, XLabel );
              FScaleRect.Bottom := FBoxRect.Bottom+FontMargin+TextHeight(XLabel);
              LastGrid := X;
              X := X + FGridX;
          end;

          X := FMinX;
          while X <= (FMinXShift + FRangeX) do begin
            ScreenX := XToScreen(X);
            MoveTo(ScreenX,FBoxRect.Bottom);
            LineTo(ScreenX,FBoxRect.Bottom+MulDiv(FontMargin,2,5));
            LastTick := X;
            X := X + FTickX;
          end;

          Y := FMinY;
          while Y <= (FMinY + FRangeY) do begin
            ScreenY := YToScreen(Y);
            MoveTo(FBoxRect.Left,ScreenY);
            LineTo(FBoxRect.Left-FontMargin,ScreenY);
            YLabel := Format('%g',[Y]);
            SetTextColor(Handle,FFont.Color);
            TextOut(FBoxRect.Left-MulDiv(FontMargin,7,5)
                                -TextWidth(YLabel),
                    ScreenY-TextHeight(YLabel) div 2, YLabel );
            Y := Y + FGridY;
          end;

          Y := FMinY;
          while Y <= (FMinY + FRangeY) do begin
            ScreenY := YToScreen(Y);
            MoveTo(FBoxRect.Left,ScreenY);
            LineTo(FBoxRect.Left-MulDiv(FontMargin,3,5),ScreenY);
            Y := Y + FTickY;
          end;
        end;

{    for i:=1 to MaxCurves do
        with FSaveImage.Canvas do begin
                Pen.Color := FColors[i];
                MoveTo(FBoxRect.Left+1,
                   FBoxRect.Bottom-round(Ky*FData[i]));
                LineTo(FBoxRect.Right-1,
                   FBoxRect.Bottom-round(Ky*FData[i]));
        end;
}
//    Invalidate;
end;

{*********************************************************************}
procedure TkpScope.SetBrush(Value: TBrush);
begin
  FBrush.Assign(Value);
end;
procedure TkpScope.SetTextBrush(Value: TBrush);
begin
  FTextBrush.Assign(Value);
end;
procedure TkpScope.SetPen(Value: TPen);
begin
  FPen.Assign(Value);
end;
procedure TkpScope.SetFont(Value: TFont);
begin
  FFont.Assign(Value);
end;

{*********************************************************************}
procedure TkpScope.StyleChanged(Sender: TObject);
begin
  if Loaded then Initialize;
  Loaded := True;
  Invalidate;
end;

{*********************************************************************}
procedure TkpScope.SetMaxCurves(Value: integer);
begin
    if (Value < 1) then Value := 1;
    if (Value > LimitCurves) then Value := LimitCurves;
    FMaxCurves := Value;
end;

{*********************************************************************}
function  TkpScope.GetColor(Index: integer): TColor;
begin
        if (Index < 1) or (Index > MaxCurves) then
        raise ERangeError.Create('TkpScope: index out of range');
        Result := FColors[Index];
end;

{*********************************************************************}
procedure TkpScope.SetColor(Index: integer; Value: TColor);
begin
        if (Index < 1) or (Index > FMaxCurves) then
        raise ERangeError.Create('TkpScope: index out of range');
        FColors[Index] := Value;
end;


{*********************************************************************}
procedure TkpScope.Paint;
begin
  if (FSaveImage.Width <> Width) or (FSaveImage.Height <> Height) then
     Initialize;
  Canvas.Draw(0,0,FSaveImage);
end;

{******************************************************************************}
procedure Register;
begin
  RegisterComponents('KP', [TkpScope] );
end;
{******************************************************************************}

end.
