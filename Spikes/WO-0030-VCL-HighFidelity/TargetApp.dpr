program TargetApp;
uses
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics, System.SysUtils, System.IOUtils, Winapi.Windows,
  System.Classes, Vcl.ExtCtrls;

var
  TargetForm: TForm;
  AW_Title: TLabel;
  AW_Desc: TLabel;
  AW_Edit: TEdit;
  AW_BtnCancel: TButton;
  AW_BtnConfirm: TButton;
  LJson: string;
  I: Integer;
  C: TComponent;
  Ctrl: TControl;
  IsFirst: Boolean;
  LFontColor: Integer;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  
  TargetForm := TForm.Create(nil);
  TargetForm.Caption := 'AsWish VCL Target Implementation';
  TargetForm.Name := 'AW_Form';
  TargetForm.Width := 400;
  TargetForm.Height := 250;
  TargetForm.Position := poScreenCenter;
  TargetForm.Color := clWhite;

  AW_Title := TLabel.Create(TargetForm);
  AW_Title.Parent := TargetForm;
  AW_Title.Name := 'AW_Title';
  AW_Title.Caption := 'Title';
  AW_Title.Left := 16;
  AW_Title.Top := 16;
  AW_Title.Font.Size := 14;
  AW_Title.Font.Style := [fsBold];
  // INTENTIONAL L3 DIFFERENCE: Expected clNavy, using clRed
  AW_Title.Font.Color := clRed;

  AW_Desc := TLabel.Create(TargetForm);
  AW_Desc.Parent := TargetForm;
  AW_Desc.Name := 'AW_Desc';
  AW_Desc.Caption := 'Description text here';
  AW_Desc.Left := 16;
  AW_Desc.Top := 50;
  
  AW_Edit := TEdit.Create(TargetForm);
  AW_Edit.Parent := TargetForm;
  AW_Edit.Name := 'AW_Edit';
  AW_Edit.Text := '';
  AW_Edit.Left := 16;
  AW_Edit.Top := 80;
  AW_Edit.Width := 350;
  
  AW_BtnCancel := TButton.Create(TargetForm);
  AW_BtnCancel.Parent := TargetForm;
  AW_BtnCancel.Name := 'AW_BtnCancel';
  AW_BtnCancel.Caption := 'Cancel';
  AW_BtnCancel.Width := 80;
  AW_BtnCancel.Height := 30;
  AW_BtnCancel.Top := 160;
  
  AW_BtnConfirm := TButton.Create(TargetForm);
  AW_BtnConfirm.Parent := TargetForm;
  AW_BtnConfirm.Name := 'AW_BtnConfirm';
  AW_BtnConfirm.Caption := 'Confirm';
  AW_BtnConfirm.Width := 80;
  AW_BtnConfirm.Height := 30;
  AW_BtnConfirm.Top := 160;

  // INTENTIONAL L2 DIFFERENCE: Swapping positions (Confirm is left-of Cancel)
  AW_BtnConfirm.Left := 180;
  AW_BtnCancel.Left := 276;

  // Extraction Logic
  LJson := '{' + sLineBreak;
  LJson := LJson + '  "Profile": {"DPI": ' + IntToStr(Screen.PixelsPerInch) + ', "Theme": "Windows"},' + sLineBreak;
  LJson := LJson + '  "Observations": [' + sLineBreak;
  
  IsFirst := True;
  for I := 0 to TargetForm.ComponentCount - 1 do
  begin
    C := TargetForm.Components[I];
    if (C is TControl) and (Copy(C.Name, 1, 3) = 'AW_') then
    begin
      if not IsFirst then LJson := LJson + ',' + sLineBreak;
      IsFirst := False;
      
      Ctrl := TControl(C);
      LFontColor := 0;
      if Ctrl is TLabel then LFontColor := TLabel(Ctrl).Font.Color
      else if Ctrl is TButton then LFontColor := TButton(Ctrl).Font.Color
      else if Ctrl is TEdit then LFontColor := TEdit(Ctrl).Font.Color;
      
      LJson := LJson + '    {' + sLineBreak;
      LJson := LJson + '      "Name": "' + Ctrl.Name + '",' + sLineBreak;
      LJson := LJson + '      "ClassName": "' + Ctrl.ClassName + '",' + sLineBreak;
      LJson := LJson + '      "Bounds": {"Left": ' + IntToStr(Ctrl.Left) + ', "Top": ' + IntToStr(Ctrl.Top) + ', "Width": ' + IntToStr(Ctrl.Width) + ', "Height": ' + IntToStr(Ctrl.Height) + '},' + sLineBreak;
      LJson := LJson + '      "FontColor": ' + IntToStr(LFontColor) + sLineBreak;
      LJson := LJson + '    }';
    end;
  end;
  LJson := LJson + sLineBreak + '  ]';
  LJson := LJson + sLineBreak + '}';
  
  var LTargetStream := TStringStream.Create(LJson, TEncoding.UTF8);
  try
    LTargetStream.SaveToFile(ExtractFilePath(ParamStr(0)) + 'RuntimeObservation.json');
  finally
    LTargetStream.Free;
  end;
  
  TargetForm.Show;
  Application.ProcessMessages;
  Sleep(1000);
  TargetForm.Free;
end.
