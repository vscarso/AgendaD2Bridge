# 📦 Componente TD2BridgeAgenda (VSComponents) PIX PARA O CAFé: vitor.scarso@hotmail.com

O `TD2BridgeAgenda` é um componente visual para Lazarus que automatiza a criação de agendas dinâmicas na Web usando o framework **D2Bridge**. Ele transforma o resultado de um `TDataSet` em um grid interativo estilo Google Calendar baseado em Bootstrap.

# 📖 Manual Técnico TD2BridgeAgenda (v1.5)

O `TD2BridgeAgenda` é um componente visual avançado para Lazarus/Delphi, projetado para transformar dados de um `TDataSet` em uma agenda web interativa estilo Google Calendar, utilizando o framework **D2Bridge**.

---

## 🛠️ 1. Instalação e Configuração

1.  Abra o arquivo `Agenda\\AgendaD2bridge.lpk` (Lazarus) ou os pacotes `Agenda\\Delphi\\AgendaD2BridgeR.dpk` + `Agenda\\Delphi\\AgendaD2BridgeD.dpk` (Delphi).
2.  Clique em **Compilar** e depois em **Instalar**.
3.  Reinicie a IDE quando solicitado.
4.  O componente aparecerá na paleta **VSComponents**.

---

## 💾 2. Requisitos de Banco de Dados (SQL)

Para que a agenda funcione, sua Query deve retornar os dados formatados. Exemplo recomendado:

```sql
SELECT 
  A.ID, 
  A.DATA_AGENDA,
  P.NOME AS PROFISSIONAL, 
  P.FOTO AS FOTO_PROFISSIONAL, -- URL da imagem
  C.NOME AS CLIENTE, 
  S.NOME AS SERVICO, -- Pode conter múltiplos serviços (Ex: "Corte;Barba")
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

### Observação importante sobre DATA + HORA
Se seu banco tiver `DATA_AGENDA` como `DATE` e `HORA_INICIO/HORA_FIM` como `TIME`, o componente combina a data selecionada com a hora automaticamente.

### Mostrar profissionais mesmo sem eventos (dias vazios)
Para que a agenda apareça com as colunas de todos os profissionais e slots vazios mesmo quando não existir nenhum agendamento no dia, use um SELECT com `PROFISSIONAIS` como tabela principal e `LEFT JOIN` na agenda:

```sql
SELECT
  A.ID,
  A.DATA_AGENDA,
  P.NOME AS NOME_PROFISSIONAL,
  C.NOME AS NOME_CLIENTE,
  LIST(S.NOME, ';') AS NOME_SERVICO,
  A.HORA_INICIO,
  A.HORA_FIM,
  A.STATUS,
  A.COR_EVENTO,
  P.FOTO_PROFISSIONAL,
  P.COR_AGENDA
FROM PROFISSIONAIS P
LEFT JOIN AGENDA A
  ON A.ID_PROFISSIONAL = P.ID
 AND A.DATA_AGENDA = :DATA
LEFT JOIN CLIENTES C ON C.ID = A.ID_CLIENTE
LEFT JOIN AGENDA_ITENS AI ON AI.ID_AGENDA = A.ID
LEFT JOIN SERVICOS S ON S.ID = AI.ID_SERVICO
WHERE P.STATUS = 1
GROUP BY
  A.ID, A.DATA_AGENDA, P.NOME, C.NOME, A.HORA_INICIO, A.HORA_FIM,
  A.STATUS, A.COR_EVENTO, P.FOTO_PROFISSIONAL, P.COR_AGENDA
ORDER BY P.NOME, A.HORA_INICIO;
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
| **ShowSelectProfessional** | Boolean | No mobile, mostra um seletor de profissional (sem scroll horizontal). |
| **AllowNewOnBusySlot** | Boolean | Permite/impede clique de “novo” em horário ocupado. |

### B. Bloco `FieldMap` (Mapeamento de Dados)
Diz ao componente quais campos do seu DataSet correspondem a cada informação.

- **FieldID**: Chave primária do agendamento.
- **FieldDate**: Campo com a data do agendamento (ex: `DATA_AGENDA`).
- **FieldGroupID**: Campo opcional para agrupar vários registros em 1 evento (pai/filho).
- **FieldProfessional**: Campo com o nome do profissional (deve bater com a lista `Professionals`).
- **FieldProfessionalPhoto**: Campo com a URL da foto (VARCHAR).
- **FieldClient**: Nome do cliente para exibir no card.
- **FieldService**: Nome do serviço para exibir no card.
- **ServiceSeparator**: Caractere usado para separar múltiplos serviços (Padrão: `;`).
- **FieldStartTime / FieldEndTime**: Campos de hora (TDateTime).
- **FieldStatus**: Status do agendamento (pode ser texto ou número; usa `StatusColors` para cor).
- **FieldColor**: Campo SQL que traz a cor Hexadecimal customizada para o card.

### C. Propriedades Gerais
- **Professionals**: `TStrings`. Lista manual dos nomes dos profissionais que aparecerão nas colunas.
- **StatusColors**: `TStrings`. Mapeamento de Status para cores do Bootstrap (ex: `Agendado=primary`).
- **StartTime / EndTime**: Inteiros (ex: 8 e 18). Define o limite da agenda.
- **IntervalMinutes**: Inteiro (ex: 30). Define o "pulo" de cada linha.
- **CurrentDate**: `TDateTime`. A data que a agenda está exibindo no momento.

---

## 🚀 4. Novidades da Versão 1.3

- **Agendamentos Sobrepostos (Conflicts)**: O componente agora detecta conflitos de horário para o mesmo profissional e exibe os cards lado a lado, ajustando automaticamente a largura e posição (estilo Google Calendar).
- **Múltiplos Serviços**: Suporte nativo a múltiplos serviços por agendamento. Use a propriedade `ServiceSeparator` para definir o delimitador. Cada serviço será exibido com seu próprio ícone de tag.
- **Renderização Absoluta**: Nova lógica de posicionamento CSS `absolute` que permite que um card se estenda visualmente por várias linhas da tabela de forma natural.

---

## 🧩 4.1 Agrupamento de Serviços (Pai/Filho)

Se seu banco tiver **um registro por serviço** (ex: 2 linhas na tabela AGENDA com o mesmo profissional/cliente/horário), o componente consegue exibir **um único card** com a lista de serviços.

- **Recomendado (pai/filho)**: defina `FieldMap.FieldGroupID` apontando para o ID do “pai” (mesmo valor para todas as linhas do mesmo agendamento). Assim o componente agrupa com precisão e o clique do card usa esse ID.
- **Fallback automático**: se `FieldGroupID` estiver vazio, o componente tenta agrupar automaticamente por: Profissional + Cliente + Hora Início + Hora Fim.

---

## 📱 5. Responsividade (Desktop x Mobile)

- **Desktop**: Tabela completa com todos os profissionais lado a lado.
- **Mobile**:
  - `ShowSelectProfessional=True` (padrão): mostra 1 profissional por vez via combo (sem scroll horizontal).
  - `ShowSelectProfessional=False`: mostra todas as agendas de profissionais empilhadas (scroll vertical).

---

## 🔗 6. Comunicação e CallBacks (O Coração)

O componente usa **Simple CallBacks** do D2Bridge. Você deve tratar os eventos no método `CallBack` do seu Form Pascal.

### Regras importantes do Simple CallBack (D2Bridge)

- `{{CallBack=Metodo}}` chama `CallBackName=Metodo` sem parâmetros.
- `{{CallBack=Metodo(Param1)}}` envia 1 parâmetro: `EventParams[0]=Param1`.
- `{{CallBack=Metodo(Param1&Param2)}}` envia 2 parâmetros (separados por `&`): `EventParams[0]=Param1`, `EventParams[1]=Param2`.
- `{{CallBack=Metodo([this.value])}}` envia valor de JavaScript (usar `[]` para expressão JS).

### Fluxo de Implementação (exemplo):

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
    ShowMessage('Novo para ' + EventParams[0] + ' às ' + EventParams[1], true, true);
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

## 🔄 7. Atualizando a Tela (Refresh)

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

## 🔧 8. Padronização de Controles (Tamanho e Fonte)

O componente aplica `Appearance.FontSize` no container principal (agenda inteira). Para evitar que o Bootstrap force tamanhos maiores em controles (`input`, `select`, botões), o componente injeta um CSS interno que padroniza:

- Tamanho da fonte e line-height do título do header
- Tamanho e padding dos botões e inputs
- Altura mínima do combo de profissionais no mobile

Se você quiser deixar a agenda mais compacta, normalmente funciona bem:

- `Appearance.FontSize = 12`
- `Appearance.RowHeight = 70..80`

---

## 💡 7. Dicas de Produtividade

- **Badges de Status**: O componente reconhece textos como "Confirmado", "Cancelado", "Agendado" e aplica cores automáticas do Bootstrap.
- **Fotos**: Se a URL da foto for inválida ou o campo estiver vazio, o cabeçalho se ajusta automaticamente para mostrar apenas o nome.
- **Cores Hexa**: O campo `FieldColor` aceita formatos como `#FF0000` ou `red`.

---
*Manual gerado em 14/03/2026 para o projeto Agenda_D2bridge.*
