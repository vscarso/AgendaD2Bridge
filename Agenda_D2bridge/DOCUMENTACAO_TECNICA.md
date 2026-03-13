# 🛠️ Documentação Técnica Detalhada: Componente TD2BridgeAgenda

Esta documentação fornece detalhes de baixo nível sobre a arquitetura e o funcionamento do componente `TD2BridgeAgenda`.

---

## 🏗️ 1. Arquitetura do Componente

O componente é construído sobre a classe `TComponent` do Free Pascal, o que garante independência de frameworks visuais pesados durante a instalação na IDE. Ele gera uma string HTML5/CSS3 compatível com **Bootstrap 5**, que é o padrão utilizado pelo D2Bridge.

### Estrutura de Classes:
- **`TD2BridgeAgenda`**: Classe principal que gerencia o DataSet e a lógica de slots.
- **`TAgendaAppearance`**: Classe persistente para configurações visuais.
- **`TAgendaFieldMap`**: Classe persistente para mapeamento de campos SQL.

---

## 📡 2. Protocolo de CallBacks (Simple CallBack)

O componente utiliza a sintaxe de tags do D2Bridge para comunicação assíncrona.

| Tag no HTML | Nome do CallBack | Parâmetros Enviados |
| :--- | :--- | :--- |
| `{{CallBack=AgendaDateNav(prev)}}` | `AgendaDateNav` | `['prev']`, `['next']` ou `['today']` |
| `{{CallBack=AgendaDateSelect([this.value])}}` | `AgendaDateSelect` | `['yyyy-mm-dd']` (valor do input date) |
| `{{CallBack=AgendaNew(Prof, Hora)}}` | `AgendaNew` | `[NomeProfissional, HH:nn]` |
| `{{CallBack=AgendaEdit(ID)}}` | `AgendaEdit` | `[ID_DO_REGISTRO]` |

### Como o Pascal processa:
Quando o usuário clica em um botão na Web, o framework D2Bridge intercepta a tag `{{CallBack=...}}` e dispara o evento `CallBack` do seu formulário. O componente fornece métodos internos para processar esses dados automaticamente:
- `DoInternalDateNav`: Atualiza `CurrentDate` baseado em prev/next/today.
- `DoInternalDateSelect`: Converte a string ISO do JS para `TDateTime`.

---

## 🎨 3. Lógica de Temas e CSS

O componente injeta um bloco de estilo `<style>` no final do HTML gerado para lidar com efeitos que o Bootstrap não cobre nativamente, como o `hover` nos slots vazios.

### Temas Disponíveis:
1.  **atDefault**: Baseado nas cores padrão do Bootstrap (Azul/Branco).
2.  **atDark**: Modo escuro completo. Inverte cores de fundo, texto e bordas da tabela.
3.  **atSoft**: Utiliza tons de roxo e lilás (`#6f42c1`).
4.  **atModern**: Minimalista, focado em preto e branco com bordas finas.

---

## ⚙️ 4. Mapeamento de Campos (FieldMap)

O `FieldMap` é essencial para que o motor de busca encontre os dados no `TDataSet`.

- **Lógica de Busca**: O componente percorre o DataSet filtrado por data e usa o método `Locate` ou uma varredura `First/Next` para preencher as células.
- **Sobreposição de Horários**: Se dois agendamentos ocuparem o mesmo slot, o componente renderizará o primeiro encontrado e marcará os slots subsequentes como ocupados (ajustando a opacidade).

---

## 🚀 5. Integração Avançada (Exemplo de Filtro)

Se você quiser filtrar a agenda por Profissional dinamicamente:

```pascal
procedure TForm1.btnFiltrarClick(Sender: TObject);
begin
  D2BridgeAgenda1.Professionals.Clear;
  D2BridgeAgenda1.Professionals.Add('Dr. Bruno');
  // Re-gera a agenda apenas para o Dr. Bruno
  LabelAgenda.Caption := D2BridgeAgenda1.GenerateHTML;
end;
```

---

## 📋 6. Glossário de Erros Comuns

1.  **"Data não atualiza"**: Verifique se você chamou `LabelAgenda.Caption := D2BridgeAgenda1.GenerateHTML` dentro do evento `OnDateChange`.
2.  **"Cards sem cor"**: Certifique-se que o campo no banco retorna um Hexadecimal válido (ex: `#FFFFFF`) e que `FieldColor` está apontando para ele.
3.  **"Fotos não aparecem"**: A URL deve ser acessível pelo navegador do cliente. Teste a URL diretamente no Chrome antes.

---
*Fim da Documentação Técnica.*
