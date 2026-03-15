unit untAgendaComponentRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, untAgendaComponent;

procedure Register;

implementation

uses
  PropEdits, Dialogs, Clipbrd;

type
  { TAgendaActionEditor: Faz o botão "..." funcionar no Object Inspector }
  TAgendaActionEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

{ TAgendaActionEditor }

function TAgendaActionEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

procedure TAgendaActionEditor.Edit;
var
  Agenda: TD2BridgeAgenda;
  S: string;
  PropName: string;
begin
  Agenda := GetComponent(0) as TD2BridgeAgenda;
  PropName := GetName;

  if PropName = '_ActionExportVisual' then
  begin
    Clipboard.AsText := Agenda.ExportVisualJSON;
    ShowMessage('🎨 Visual da Agenda copiado para o Clipboard!');
  end
  else if PropName = '_ActionImportVisual' then
  begin
    if InputQuery('Importar Visual', 'Cole o JSON do Visual aqui:', S) then
    begin
      Agenda.ImportVisualJSON(S);
      Modified;
      ShowMessage('✅ Visual aplicado com sucesso!');
    end;
  end;

  if PropName = '_ActionExportConfig' then
  begin
    Clipboard.AsText := Agenda.ExportConfigJSON;
    ShowMessage('⚙️ Mapeamento de Campos copiado para o Clipboard!');
  end
  else if PropName = '_ActionImportConfig' then
  begin
    if InputQuery('Importar Configuração', 'Cole o JSON do FieldMap aqui:', S) then
    begin
      Agenda.ImportConfigJSON(S);
      Modified;
      ShowMessage('✅ Configuração aplicada com sucesso!');
    end;
  end;
end;

procedure Register;
begin
  RegisterComponents('VSComponents', [TD2BridgeAgenda]);
  
  { Registra o editor para cada propriedade de ação }
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionExportVisual', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionImportVisual', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionExportConfig', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionImportConfig', TAgendaActionEditor);
end;

end.
