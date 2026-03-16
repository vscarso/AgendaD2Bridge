# 📦 Componente TD2BridgeAgenda (VSComponents)

O `TD2BridgeAgenda` é um componente visual para Lazarus que automatiza a criação de agendas dinâmicas na Web usando o framework **D2Bridge**. Ele transforma o resultado de um `TDataSet` em um grid interativo estilo Google Calendar baseado em Bootstrap.

---



## 🚀 Instalação no Lazarus

1. Vá em `Package -> Open Package File (.lpk)`.
2. Abra o seu pacote (ex: `VSComponents.lpk`).
3. **IMPORTANTE**: Nas "Required Packages" (Requisitos) do seu pacote, adicione a dependência:
   - **`IDEIntf`** (Necessário para o menu de botão direito na IDE).
   - **`LCL`** (Para suporte a clipboard e diálogos).
4. Adicione as units `untAgendaComponent.pas` e `untAgendaComponentRegister.pas`.
5. Clique em `Compile` e depois em `Install`.

---

## 📋 Guia de Implementação (Passo a Passo)

### 1. O SQL Necessário
Sua query deve filtrar por uma data e trazer os dados do compromisso + nome do profissional.
```sql
SELECT 
  A.ID, P.NOME AS PROFISSIONAL, C.NOME AS CLIENTE, S.NOME AS SERVICO, 
  A.HORA_INICIO, A.HORA_FIM, A.STATUS, P.COR_AGENDA
FROM AGENDA A
JOIN PROFISSIONAIS P ON P.ID = A.ID_PROFISSIONAL
JOIN CLIENTES C ON C.ID = A.ID_CLIENTE
JOIN SERVICOS S ON S.ID = A.ID_SERVICO
WHERE A.DATA_AGENDA = :DATA
```

### 2. No Método CallBack do Form (Obrigatório)
O componente gera comandos HTML que precisam ser "escutados" pelo formulário Pascal. Adicione este redirecionamento:

```pascal
procedure TForm1.CallBack(const CallBackName: string; EventParams: TStrings);
begin
  inherited;
  if SameText(CallBackName, 'AgendaDateNav') then
    D2BridgeAgenda1.DoInternalDateNav(EventParams)
  else if SameText(CallBackName, 'AgendaDateSelect') then
    D2BridgeAgenda1.DoInternalDateSelect(EventParams)
  else if SameText(CallBackName, 'AgendaNew') then
    D2BridgeAgenda1.DoInternalNewAppointment(EventParams)
  else if SameText(CallBackName, 'AgendaEdit') then
    D2BridgeAgenda1.DoInternalEditAppointment(EventParams);
end;
```

---

## ⚡ Exemplos de Cenários de Uso

Aqui estão os 3 principais casos de uso e como tratar cada um no Pascal:

### Cenário A: Clicar em um Slot Vazio (Novo Agendamento)
Quando o usuário clica em um horário disponível (ex: Dr. Bruno às 10:30).
- **Evento**: `OnSlotClick(Sender, Professional, TimeSlot)`
```pascal
procedure TForm1.D2BridgeAgenda1SlotClick(Sender: TObject; const Professional, TimeSlot: string);
begin
  // Exemplo fictício: Abrir form de cadastro pré-preenchido
  FormCadastro.lblTitulo.Caption := 'Novo agendamento para ' + Professional;
  FormCadastro.edtHora.Text := TimeSlot;
  FormCadastro.Show;
end;
```

### Cenário B: Clicar em um Compromisso (Editar/Ver)
Quando o usuário clica em um card colorido que já possui um cliente agendado.
- **Evento**: `OnAppointmentClick(Sender, AppointmentID)`
```pascal
procedure TForm1.D2BridgeAgenda1AppointmentClick(Sender: TObject; const AppointmentID: string);
begin
  // O AppointmentID vem do campo mapeado em FieldID (ex: ID da tabela AGENDA)
  ZQueryAgenda.Locate('ID', AppointmentID, []);
  FormDetalhes.Show;
end;
```

### Cenário C: Navegação de Datas (Calendário)
O componente possui botões (Anterior, Próximo, Hoje) e um **Seletor de Data (Input Date)** integrado.
- **Evento**: `OnDateChange(Sender)`
```pascal
procedure TForm1.D2BridgeAgenda1DateChange(Sender: TObject);
begin
  // 1. Atualiza a Query com a nova data selecionada no componente
  ZQueryAgenda.Close;
  ZQueryAgenda.ParamByName('DATA').AsDate := D2BridgeAgenda1.CurrentDate;
  ZQueryAgenda.Open;
  
  // 2. Atualiza o visual da agenda no navegador
  LabelAgenda.Caption := D2BridgeAgenda1.GenerateHTML;
end;
```

---

## ⚙️ Referência de Propriedades

### Bloco `Appearance` (Visual)
- **Theme**: Estilos visuais prontos (`Default`, `Dark`, `Soft`, `Modern`).
- **Font**: Seleção de fontes (`Roboto`, `Open Sans`, `Lato`, etc.). Injeta links do Google Fonts automaticamente.
- **HeaderColor**: Cor de fundo da barra superior (onde fica a data).
- **SlotHoverColor**: Cor de destaque ao passar o mouse sobre horários livres.
- **RowHeight**: Altura das linhas (ex: 70). Útil para ver mais ou menos horários na tela.

### Bloco `FieldMap` (Mapeamento)
- **FieldID**: Nome do campo ID no seu SELECT.
- **FieldProfessional**: Nome do campo que contém o nome do Profissional (deve bater com a lista `Professionals`).
- **FieldClient / FieldService**: Nomes dos campos para exibição no card.
- **FieldColor**: Nome do campo SQL que traz a cor hexadecimal (ex: #FF5733) para o card.

---

## 💾 Exportação e Importação (JSON e Menu de Contexto)

Você pode salvar suas configurações para reutilizar em outros projetos ou carregar temas dinamicamente de duas formas:

### 1. Pela IDE (Botão Direito no Componente) - NOVO! 🚀
Agora você pode clicar com o **botão direito** no componente `TD2BridgeAgenda` sobre o formulário no Lazarus e acessar:
- **🎨 Exportar Visual (Clipboard)**: Copia o JSON de cores e fontes para sua área de transferência.
- **🎨 Importar Visual (JSON)**: Abre uma caixa de diálogo para você colar um JSON de visual.
- **⚙️ Exportar Configuração (Clipboard)**: Copia o JSON de mapeamento de campos (FieldMap).
- **⚙️ Importar Configuração (JSON)**: Abre uma caixa de diálogo para você colar o mapeamento de campos.

### 2. Por Código (Tempo de Execução)
Útil para salvar preferências do usuário ou configurações de diferentes clínicas em arquivos externos ou banco de dados.

```pascal
// Salva apenas as cores e fontes (Visual)
Memo1.Lines.Text := D2BridgeAgenda1.ExportVisualJSON;

// Salva o mapeamento de campos (Configuração)
Memo2.Lines.Text := D2BridgeAgenda1.ExportConfigJSON;

// Para restaurar:
D2BridgeAgenda1.ImportVisualJSON(StringSalva);
```

---
