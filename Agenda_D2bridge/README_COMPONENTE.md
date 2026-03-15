# 📖 Manual Técnico TD2BridgeAgenda (v1.1)

O `TD2BridgeAgenda` é um componente visual avançado para Lazarus, projetado para transformar dados de um `TDataSet` em uma agenda web interativa estilo Google Calendar, utilizando o framework **D2Bridge**.

---

## 🛠️ 1. Instalação e Configuração

1.  Abra o arquivo `agendad2bridge.lpk` no Lazarus.
2.  Clique em **Compilar** e depois em **Instalar**.
3.  Reinicie a IDE quando solicitado.
4.  O componente aparecerá na paleta **VSComponents**.

---

## 💾 2. Requisitos de Banco de Dados (SQL)

Para que a agenda funcione, sua Query deve retornar os dados formatados. Exemplo recomendado:

```sql
SELECT 
  A.ID, 
  P.NOME AS PROFISSIONAL, 
  P.FOTO AS FOTO_PROFISSIONAL, -- URL da imagem
  C.NOME AS CLIENTE, 
  S.NOME AS SERVICO, 
  A.HORA_INICIO, 
  A.HORA_FIM, 
  A.STATUS, 
  A.COR_HEXA -- Ex: #FF5733
FROM AGENDA A
JOIN PROFISSIONAIS P ON P.ID = A.ID_PROFISSIONAL
JOIN CLIENTES C ON C.ID = A.ID_CLIENTE
JOIN SERVICOS S ON S.ID = A.ID_SERVICO
WHERE A.DATA_AGENDA = :DATA
```

---

## ⚙️ 3. Propriedades (Object Inspector)

### A. Bloco `Appearance` (Visual)
Controla como a agenda é renderizada no navegador.

| Propriedade | Tipo | Descrição |
| :--- | :--- | :--- |
| **Theme** | Enum | `atDefault` (Azul), `atDark` (Escuro), `atSoft` (Lilás), `atModern` (Preto). |
| **Font** | Enum | Seleciona fontes como Roboto, Open Sans ou Lato (Injeta Google Fonts). |
| **FontSize** | Integer | Tamanho da fonte geral em pixels (Padrão: 14). |
| **HeaderColor** | Color/Hex | Cor de fundo da barra de título. |
| **HeaderTextColor** | Color/Hex | Cor do texto e ícones no cabeçalho. |
| **SlotHoverColor** | Color/Hex | Cor de destaque ao passar o mouse em horários vagos. |
| **RowHeight** | Integer | Altura de cada linha de horário (Padrão: 70). |
| **ShowHeader** | Boolean | Liga/Desliga a barra superior inteira. |
| **ShowDateText** | Boolean | Mostra/Esconde o texto da data (ex: 13/03/2026). |
| **ShowCalendar** | Boolean | Mostra/Esconde o ícone de seletor de data. |
| **ShowNavigation** | Boolean | Mostra/Esconde os botões Hoje/Ant/Próx. |

### B. Bloco `FieldMap` (Mapeamento de Dados)
Diz ao componente quais campos do seu DataSet correspondem a cada informação.

- **FieldID**: Chave primária do agendamento.
- **FieldProfessional**: Campo com o nome do profissional (deve bater com a lista `Professionals`).
- **FieldProfessionalPhoto**: Campo com a URL da foto (VARCHAR).
- **FieldClient**: Nome do cliente para exibir no card.
- **FieldService**: Nome do serviço para exibir no card.
- **FieldStartTime / FieldEndTime**: Campos de hora (TDateTime).
- **FieldStatus**: Texto do status (Gera badges coloridas automaticamente).
- **FieldColor**: Campo SQL que traz a cor Hexadecimal customizada para o card.

### C. Propriedades Gerais
- **Professionals**: `TStrings`. Lista manual dos nomes dos profissionais que aparecerão nas colunas.
- **StartTime / EndTime**: Inteiros (ex: 8 e 18). Define o limite da agenda.
- **IntervalMinutes**: Inteiro (ex: 30). Define o "pulo" de cada linha.
- **CurrentDate**: `TDateTime`. A data que a agenda está exibindo no momento.

---

## 🔗 4. Comunicação e CallBacks (O Coração)

O componente usa **Simple CallBacks** do D2Bridge. Você deve tratar os eventos no método `CallBack` do seu Form Pascal.

### Fluxo de Implementação:

```pascal
procedure TForm1.CallBack(const CallBackName: string; EventParams: TStrings);
begin
  inherited;
  
  // 1. Navegação de Datas (Botões Hoje, Próximo, Anterior)
  if SameText(CallBackName, 'AgendaDateNav') then
    D2BridgeAgenda1.DoInternalDateNav(EventParams)
    
  // 2. Seleção via Calendário JS
  else if SameText(CallBackName, 'AgendaDateSelect') then
    D2BridgeAgenda1.DoInternalDateSelect(EventParams)
    
  // 3. Clique em Horário Vago (Novo Agendamento)
  else if SameText(CallBackName, 'AgendaNew') then
  begin
    // EventParams[0] = Nome do Profissional
    // EventParams[1] = Horário Clicado (HH:nn)
    lblStatus.Caption := 'Novo para ' + EventParams[0] + ' às ' + EventParams[1];
    FormCadastro.Show; 
  end
  
  // 4. Clique em Agendamento Existente (Editar)
  else if SameText(CallBackName, 'AgendaEdit') then
  begin
    // EventParams[0] = ID do agendamento (FieldID)
    ZQueryAgenda.Locate('ID', EventParams[0], []);
    FormEdicao.Show;
  end;
end;
```

---

## 🔄 5. Atualizando a Tela (Refresh)

Sempre que a data mudar ou um dado for salvo, você deve atualizar o controle visual:

```pascal
procedure TForm1.D2BridgeAgenda1DateChange(Sender: TObject);
begin
  // Atualiza os dados
  ZQueryAgenda.Close;
  ZQueryAgenda.ParamByName('DATA').AsDate := D2BridgeAgenda1.CurrentDate;
  ZQueryAgenda.Open;
  
  // Atualiza o HTML no D2Bridge
  LabelAgenda.Caption := D2BridgeAgenda1.GenerateHTML;
end;
```

---

## 🎨 6. Importação/Exportação Visual (JSON)

No Object Inspector, existem 4 "Ações" (propriedades que começam com `_Action`):
1.  **ExportVisual**: Copia todas as cores e fontes para o Clipboard em formato JSON.
2.  **ImportVisual**: Abre uma caixa para você colar um JSON e aplicar o visual instantaneamente.
3.  **ExportConfig / ImportConfig**: Faz o mesmo para o mapeamento de campos (`FieldMap`).

*Dica: Útil para replicar o mesmo visual em diferentes agendas do seu sistema.*

---

## 💡 7. Dicas de Produtividade

- **Badges de Status**: O componente reconhece textos como "Confirmado", "Cancelado", "Agendado" e aplica cores automáticas do Bootstrap.
- **Fotos**: Se a URL da foto for inválida ou o campo estiver vazio, o cabeçalho se ajusta automaticamente para mostrar apenas o nome.
- **Cores Hexa**: O campo `FieldColor` aceita formatos como `#FF0000` ou `red`.

---
*Manual gerado em 13/03/2026 para o projeto Agenda_D2bridge.*
