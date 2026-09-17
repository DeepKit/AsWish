program PreviewApp;
uses
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics, System.SysUtils, Winapi.Windows;

var
  PreviewForm: TForm;
  TitleLabel: TLabel;
  DescLabel: TLabel;
  InputBox: TEdit;
  CancelBtn: TButton;
  ConfirmBtn: TButton;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  
  PreviewForm := TForm.Create(nil);
  PreviewForm.Caption := 'AsWish VCL Preview Renderer';
  PreviewForm.Width := 400;
  PreviewForm.Height := 250;
  PreviewForm.Position := poScreenCenter;
  PreviewForm.Color := clWhite;

  TitleLabel := TLabel.Create(PreviewForm);
  TitleLabel.Parent := PreviewForm;
  TitleLabel.Caption := 'Title';
  TitleLabel.Left := 16;
  TitleLabel.Top := 16;
  TitleLabel.Font.Size := 14;
  TitleLabel.Font.Style := [fsBold];
  TitleLabel.Font.Color := clNavy;

  DescLabel := TLabel.Create(PreviewForm);
  DescLabel.Parent := PreviewForm;
  DescLabel.Caption := 'Description text here';
  DescLabel.Left := 16;
  DescLabel.Top := 50;
  
  InputBox := TEdit.Create(PreviewForm);
  InputBox.Parent := PreviewForm;
  InputBox.Text := '';
  InputBox.Left := 16;
  InputBox.Top := 80;
  InputBox.Width := 350;
  
  CancelBtn := TButton.Create(PreviewForm);
  CancelBtn.Parent := PreviewForm;
  CancelBtn.Caption := 'Cancel';
  CancelBtn.Width := 80;
  CancelBtn.Height := 30;
  CancelBtn.Top := 160;
  CancelBtn.Left := 180;
  
  ConfirmBtn := TButton.Create(PreviewForm);
  ConfirmBtn.Parent := PreviewForm;
  ConfirmBtn.Caption := 'Confirm';
  ConfirmBtn.Width := 80;
  ConfirmBtn.Height := 30;
  ConfirmBtn.Top := 160;
  ConfirmBtn.Left := 276; // Cancel.Left + Cancel.Width + 16 gap
  // ConfirmBtn color normally via styles, but setting Font.Color for demo
  ConfirmBtn.Font.Color := clHighlight;

  PreviewForm.Show;
  
  // Fake screenshot via saving to file or just exiting
  Application.ProcessMessages;
  Sleep(1000); // Allow human to see preview
  // In real life we'd take a screenshot here.
  
  PreviewForm.Free;
end.
