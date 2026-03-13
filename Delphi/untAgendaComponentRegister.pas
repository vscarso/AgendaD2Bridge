unit untAgendaComponentRegister;

interface

uses
  System.Classes, DesignIntf, DesignEditors, Vcl.Dialogs, Vcl.Clipbrd, untAgendaComponent;

type
  { TAgendaActionEditor: Faz o botão "..." funcionar no Object Inspector no Delphi }
  TAgendaActionEditor = class(TStringPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('VSComponents', [TD2BridgeAgenda]);
  
  // Registra os editores para as ações de Importação/Exportação
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionExportVisual', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionImportVisual', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionExportConfig', TAgendaActionEditor);
  RegisterPropertyEditor(TypeInfo(string), TD2BridgeAgenda, '_ActionImportConfig', TAgendaActionEditor);
end;

{ TAgendaActionEditor }

function TAgendaActionEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

procedure TAgendaActionEditor.Edit;
var
  Agenda: TD2BridgeAgenda;
  PropName: string;
  InputJSON: string;
begin
  Agenda := GetComponent(0) as TD2BridgeAgenda;
  PropName := GetName;

  if PropName = '_ActionExportVisual' then
  begin
    Clipboard.AsText := Agenda.ExportVisualJSON;
    ShowMessage('JSON Visual copiado para o Clipboard!');
  end
  else if PropName = '_ActionExportConfig' then
  begin
    Clipboard.AsText := Agenda.ExportConfigJSON;
    ShowMessage('JSON de Configuração copiado para o Clipboard!');
  end
  else if PropName = '_ActionImportVisual' then
  begin
    if InputQuery('Importar Visual', 'Cole o JSON Visual aqui:', InputJSON) then
    begin
      Agenda.ImportVisualJSON(InputJSON);
      ShowMessage('Visual importado com sucesso!');
    end;
  end
  else if PropName = '_ActionImportConfig' then
  begin
    if InputQuery('Importar Configuração', 'Cole o JSON de Configuração aqui:', InputJSON) then
    begin
      Agenda.ImportConfigJSON(InputJSON);
      ShowMessage('Configuração importada com sucesso!');
    end;
  end;
end;

end.
