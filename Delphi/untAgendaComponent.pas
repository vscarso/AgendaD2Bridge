unit untAgendaComponent;

interface

uses
  System.Classes, System.SysUtils, Data.DB, System.DateUtils, System.TypInfo, System.JSON;

type
  { TAgendaTheme: Temas pré-definidos }
  TAgendaTheme = (atDefault, atDark, atSoft, atModern);

  { TAgendaFont: Fontes permitidas }
  TAgendaFont = (afSansSerif, afSerif, afMonospace, afRoboto, afOpenSans, afLato);

  { TAgendaFieldMap: Mapeamento de campos do DataSet }
  TAgendaFieldMap = class(TPersistent)
  private
    FFieldID: string;
    FFieldProfessional: string;
    FFieldClient: string;
    FFieldService: string;
    FFieldStartTime: string;
    FFieldEndTime: string;
    FFieldStatus: string;
    FFieldColor: string;
    FFieldProfessionalPhoto: string;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    function ToJSON: string;
    procedure FromJSON(const AJSON: string);
  published
    property FieldID: string read FFieldID write FFieldID;
    property FieldProfessional: string read FFieldProfessional write FFieldProfessional;
    property FieldProfessionalPhoto: string read FFieldProfessionalPhoto write FFieldProfessionalPhoto;
    property FieldClient: string read FFieldClient write FFieldClient;
    property FieldService: string read FFieldService write FFieldService;
    property FieldStartTime: string read FFieldStartTime write FFieldStartTime;
    property FieldEndTime: string read FFieldEndTime write FFieldEndTime;
    property FieldStatus: string read FFieldStatus write FFieldStatus;
    property FieldColor: string read FFieldColor write FFieldColor;
  end;

  { TAgendaAppearance: Configurações Visuais Separadas }
  TAgendaAppearance = class(TPersistent)
  private
    FTheme: TAgendaTheme;
    FFont: TAgendaFont;
    FHeaderColor: string;
    FHeaderTextColor: string;
    FSlotHoverColor: string;
    FRowHeight: Integer;
    FFontSize: Integer;
    FShowCalendar: Boolean;
    FShowNavigation: Boolean;
    FShowDateText: Boolean;
    FShowHeader: Boolean;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    function ToJSON: string;
    procedure FromJSON(const AJSON: string);
    function GetFontFamily: string;
  published
    property Theme: TAgendaTheme read FTheme write FTheme default atDefault;
    property Font: TAgendaFont read FFont write FFont default afSansSerif;
    property HeaderColor: string read FHeaderColor write FHeaderColor;
    property HeaderTextColor: string read FHeaderTextColor write FHeaderTextColor;
    property SlotHoverColor: string read FSlotHoverColor write FSlotHoverColor;
    property RowHeight: Integer read FRowHeight write FRowHeight default 70;
    property FontSize: Integer read FFontSize write FFontSize default 14;
    property ShowCalendar: Boolean read FShowCalendar write FShowCalendar default True;
    property ShowNavigation: Boolean read FShowNavigation write FShowNavigation default True;
    property ShowDateText: Boolean read FShowDateText write FShowDateText default True;
    property ShowHeader: Boolean read FShowHeader write FShowHeader default True;
  end;

  { Eventos do Componente }
  TOnAgendaSlotClick = procedure(Sender: TObject; const Professional: string; const TimeSlot: string) of object;
  TOnAgendaAppointmentClick = procedure(Sender: TObject; const AppointmentID: string) of object;

  { TD2BridgeAgenda: O componente principal }
  TD2BridgeAgenda = class(TComponent)
  private
    FDataSet: TDataSet;
    FFieldMap: TAgendaFieldMap;
    FAppearance: TAgendaAppearance;
    FProfessionals: TStringList;
    FStartTime: Integer;
    FEndTime: Integer;
    FIntervalMinutes: Integer;
    FCurrentDate: TDateTime;
    FOnSlotClick: TOnAgendaSlotClick;
    FOnAppointmentClick: TOnAgendaAppointmentClick;
    FOnDateChange: TNotifyEvent;
    
    procedure SetFieldMap(AValue: TAgendaFieldMap);
    procedure SetAppearance(AValue: TAgendaAppearance);
    function GetStatusBadge(const Status: string): string;
    function FormatTime(ATime: TDateTime): string;
    function IsTimeInAppointment(ATime: TDateTime; AppStart, AppEnd: TDateTime): Boolean;
    procedure SetProfessionals(AValue: TStringList);
    function GetDummyAction: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DoInternalNewAppointment(EventParams: TStrings);
    procedure DoInternalEditAppointment(EventParams: TStrings);
    procedure DoInternalDateNav(EventParams: TStrings);
    procedure DoInternalDateSelect(EventParams: TStrings);

    function GenerateHTML: string;

    { Exportação/Importação em JSON }
    function ExportVisualJSON: string;
    procedure ImportVisualJSON(const AJSON: string);
    function ExportConfigJSON: string;
    procedure ImportConfigJSON(const AJSON: string);

  published
    { Propriedades de Ação para o Object Inspector }
    property _ActionExportVisual: string read GetDummyAction; 
    property _ActionImportVisual: string read GetDummyAction;
    property _ActionExportConfig: string read GetDummyAction;
    property _ActionImportConfig: string read GetDummyAction;

    property DataSet: TDataSet read FDataSet write FDataSet;
    property FieldMap: TAgendaFieldMap read FFieldMap write SetFieldMap;
    property Appearance: TAgendaAppearance read FAppearance write SetAppearance;
    property Professionals: TStringList read FProfessionals write SetProfessionals;
    property StartTime: Integer read FStartTime write FStartTime default 8;
    property EndTime: Integer read FEndTime write FEndTime default 18;
    property IntervalMinutes: Integer read FIntervalMinutes write FIntervalMinutes default 30;
    property CurrentDate: TDateTime read FCurrentDate write FCurrentDate;
    
    property OnSlotClick: TOnAgendaSlotClick read FOnSlotClick write FOnSlotClick;
    property OnAppointmentClick: TOnAgendaAppointmentClick read FOnAppointmentClick write FOnAppointmentClick;
    property OnDateChange: TNotifyEvent read FOnDateChange write FOnDateChange;
  end;

implementation

{ TAgendaFieldMap }

constructor TAgendaFieldMap.Create;
begin
  FFieldID := 'ID';
  FFieldProfessional := 'NOME_PROFISSIONAL';
  FFieldClient := 'NOME_CLIENTE';
  FFieldService := 'NOME_SERVICO';
  FFieldStartTime := 'HORA_INICIO';
  FFieldEndTime := 'HORA_FIM';
  FFieldStatus := 'STATUS';
  FFieldColor := 'COR_AGENDA';
  FFieldProfessionalPhoto := 'FOTO_PROFISSIONAL';
end;

procedure TAgendaFieldMap.Assign(Source: TPersistent);
var
  Src: TAgendaFieldMap;
begin
  if Source is TAgendaFieldMap then
  begin
    Src := TAgendaFieldMap(Source);
    FFieldID := Src.FieldID;
    FFieldProfessional := Src.FieldProfessional;
    FFieldProfessionalPhoto := Src.FieldProfessionalPhoto;
    FFieldClient := Src.FieldClient;
    FFieldService := Src.FieldService;
    FFieldStartTime := Src.FieldStartTime;
    FFieldEndTime := Src.FieldEndTime;
    FFieldStatus := Src.FieldStatus;
    FFieldColor := Src.FieldColor;
  end
  else
    inherited Assign(Source);
end;

function TAgendaFieldMap.ToJSON: string;
var
  J: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('FieldID', FFieldID);
    J.AddPair('FieldProfessional', FFieldProfessional);
    J.AddPair('FieldProfessionalPhoto', FFieldProfessionalPhoto);
    J.AddPair('FieldClient', FFieldClient);
    J.AddPair('FieldService', FFieldService);
    J.AddPair('FieldStartTime', FFieldStartTime);
    J.AddPair('FieldEndTime', FFieldEndTime);
    J.AddPair('FieldStatus', FFieldStatus);
    J.AddPair('FieldColor', FFieldColor);
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

procedure TAgendaFieldMap.FromJSON(const AJSON: string);
var
  J: TJSONObject;
begin
  J := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
  if Assigned(J) then
  try
    if J.Values['FieldID'] <> nil then FFieldID := J.Values['FieldID'].Value;
    if J.Values['FieldProfessional'] <> nil then FFieldProfessional := J.Values['FieldProfessional'].Value;
    if J.Values['FieldClient'] <> nil then FFieldClient := J.Values['FieldClient'].Value;
    if J.Values['FieldService'] <> nil then FFieldService := J.Values['FieldService'].Value;
    if J.Values['FieldStartTime'] <> nil then FFieldStartTime := J.Values['FieldStartTime'].Value;
    if J.Values['FieldEndTime'] <> nil then FFieldEndTime := J.Values['FieldEndTime'].Value;
    if J.Values['FieldStatus'] <> nil then FFieldStatus := J.Values['FieldStatus'].Value;
    if J.Values['FieldColor'] <> nil then FFieldColor := J.Values['FieldColor'].Value;
    if J.Values['FieldProfessionalPhoto'] <> nil then FFieldProfessionalPhoto := J.Values['FieldProfessionalPhoto'].Value;
  finally
    J.Free;
  end;
end;

{ TAgendaAppearance }

constructor TAgendaAppearance.Create;
begin
  FTheme := atDefault;
  FFont := afSansSerif;
  FHeaderColor := '#ffffff';
  FHeaderTextColor := '#0d6efd';
  FSlotHoverColor := '#f1f8ff';
  FRowHeight := 70;
  FFontSize := 14;
  FShowCalendar := True;
  FShowNavigation := True;
  FShowDateText := True;
  FShowHeader := True;
end;

procedure TAgendaAppearance.Assign(Source: TPersistent);
var
  Src: TAgendaAppearance;
begin
  if Source is TAgendaAppearance then
  begin
    Src := TAgendaAppearance(Source);
    FTheme := Src.Theme;
    FFont := Src.Font;
    FHeaderColor := Src.HeaderColor;
    FHeaderTextColor := Src.HeaderTextColor;
    FSlotHoverColor := Src.SlotHoverColor;
    FRowHeight := Src.RowHeight;
    FFontSize := Src.FontSize;
    FShowCalendar := Src.ShowCalendar;
    FShowNavigation := Src.ShowNavigation;
    FShowDateText := Src.ShowDateText;
    FShowHeader := Src.ShowHeader;
  end
  else
    inherited Assign(Source);
end;

function TAgendaAppearance.ToJSON: string;
var
  J: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('Theme', GetEnumName(TypeInfo(TAgendaTheme), Ord(FTheme)));
    J.AddPair('Font', GetEnumName(TypeInfo(TAgendaFont), Ord(FFont)));
    J.AddPair('HeaderColor', FHeaderColor);
    J.AddPair('HeaderTextColor', FHeaderTextColor);
    J.AddPair('SlotHoverColor', FSlotHoverColor);
    J.AddPair('RowHeight', TJSONNumber.Create(FRowHeight));
    J.AddPair('FontSize', TJSONNumber.Create(FFontSize));
    J.AddPair('ShowCalendar', TJSONBool.Create(FShowCalendar));
    J.AddPair('ShowNavigation', TJSONBool.Create(FShowNavigation));
    J.AddPair('ShowDateText', TJSONBool.Create(FShowDateText));
    J.AddPair('ShowHeader', TJSONBool.Create(FShowHeader));
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

procedure TAgendaAppearance.FromJSON(const AJSON: string);
var
  J: TJSONObject;
begin
  J := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
  if Assigned(J) then
  try
    if J.Values['Theme'] <> nil then FTheme := TAgendaTheme(GetEnumValue(TypeInfo(TAgendaTheme), J.Values['Theme'].Value));
    if J.Values['Font'] <> nil then FFont := TAgendaFont(GetEnumValue(TypeInfo(TAgendaFont), J.Values['Font'].Value));
    if J.Values['HeaderColor'] <> nil then FHeaderColor := J.Values['HeaderColor'].Value;
    if J.Values['HeaderTextColor'] <> nil then FHeaderTextColor := J.Values['HeaderTextColor'].Value;
    if J.Values['SlotHoverColor'] <> nil then FSlotHoverColor := J.Values['SlotHoverColor'].Value;
    if J.Values['RowHeight'] <> nil then FRowHeight := J.Values['RowHeight'].Value.ToInteger;
    if J.Values['FontSize'] <> nil then FFontSize := J.Values['FontSize'].Value.ToInteger;
    if J.Values['ShowCalendar'] <> nil then FShowCalendar := (J.Values['ShowCalendar'] is TJSONTrue);
    if J.Values['ShowNavigation'] <> nil then FShowNavigation := (J.Values['ShowNavigation'] is TJSONTrue);
    if J.Values['ShowDateText'] <> nil then FShowDateText := (J.Values['ShowDateText'] is TJSONTrue);
    if J.Values['ShowHeader'] <> nil then FShowHeader := (J.Values['ShowHeader'] is TJSONTrue);
  finally
    J.Free;
  end;
end;

function TAgendaAppearance.GetFontFamily: string;
begin
  case FFont of
    afSansSerif: Result := 'sans-serif';
    afSerif: Result := 'serif';
    afMonospace: Result := 'monospace';
    afRoboto: Result := '''Roboto'', sans-serif';
    afOpenSans: Result := '''Open Sans'', sans-serif';
    afLato: Result := '''Lato'', sans-serif';
    else Result := 'inherit';
  end;
end;

{ TD2BridgeAgenda }

constructor TD2BridgeAgenda.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFieldMap := TAgendaFieldMap.Create;
  FAppearance := TAgendaAppearance.Create;
  FProfessionals := TStringList.Create;
  FStartTime := 8;
  FEndTime := 18;
  FIntervalMinutes := 30;
  FCurrentDate := Date;
end;

destructor TD2BridgeAgenda.Destroy;
begin
  FFieldMap.Free;
  FAppearance.Free;
  FProfessionals.Free;
  inherited Destroy;
end;

function TD2BridgeAgenda.ExportVisualJSON: string;
begin
  Result := FAppearance.ToJSON;
end;

procedure TD2BridgeAgenda.ImportVisualJSON(const AJSON: string);
begin
  FAppearance.FromJSON(AJSON);
end;

function TD2BridgeAgenda.ExportConfigJSON: string;
begin
  Result := FFieldMap.ToJSON;
end;

procedure TD2BridgeAgenda.ImportConfigJSON(const AJSON: string);
begin
  FFieldMap.FromJSON(AJSON);
end;

procedure TD2BridgeAgenda.SetFieldMap(AValue: TAgendaFieldMap);
begin
  FFieldMap.Assign(AValue);
end;

procedure TD2BridgeAgenda.SetAppearance(AValue: TAgendaAppearance);
begin
  FAppearance.Assign(AValue);
end;

procedure TD2BridgeAgenda.SetProfessionals(AValue: TStringList);
begin
  FProfessionals.Assign(AValue);
end;

function TD2BridgeAgenda.GetDummyAction: string;
begin
  Result := '(Clique em ... para executar)';
end;

function TD2BridgeAgenda.FormatTime(ATime: TDateTime): string;
begin
  Result := FormatDateTime('HH:nn', ATime);
end;

function TD2BridgeAgenda.GetStatusBadge(const Status: string): string;
begin
  if SameText(Status, 'Agendado') then Result := '<span class="badge bg-primary">Agendado</span>'
  else if SameText(Status, 'Confirmado') then Result := '<span class="badge bg-success">Confirmado</span>'
  else if SameText(Status, 'Cancelado') then Result := '<span class="badge bg-danger">Cancelado</span>'
  else if SameText(Status, 'Finalizado') then Result := '<span class="badge bg-secondary">Finalizado</span>'
  else Result := '<span class="badge bg-info">' + Status + '</span>';
end;

function TD2BridgeAgenda.IsTimeInAppointment(ATime: TDateTime; AppStart, AppEnd: TDateTime): Boolean;
var T, S, E: TDateTime;
begin
  T := Frac(ATime);
  S := Frac(AppStart);
  E := Frac(AppEnd);
  if E <= S then E := EncodeTime(23, 59, 59, 999);
  Result := (T >= S) and (T < E);
end;

procedure TD2BridgeAgenda.DoInternalNewAppointment(EventParams: TStrings);
begin
  if Assigned(FOnSlotClick) and (EventParams.Count >= 2) then
    FOnSlotClick(Self, EventParams[0], EventParams[1]);
end;

procedure TD2BridgeAgenda.DoInternalEditAppointment(EventParams: TStrings);
begin
  if Assigned(FOnAppointmentClick) and (EventParams.Count >= 1) then
    FOnAppointmentClick(Self, EventParams[0]);
end;

procedure TD2BridgeAgenda.DoInternalDateNav(EventParams: TStrings);
var Action: string;
begin
  if EventParams.Count > 0 then
  begin
    Action := EventParams[0];
    if SameText(Action, 'prev') then FCurrentDate := FCurrentDate - 1
    else if SameText(Action, 'next') then FCurrentDate := FCurrentDate + 1
    else if SameText(Action, 'today') then FCurrentDate := Date;
    
    if Assigned(FOnDateChange) then FOnDateChange(Self);
  end;
end;

procedure TD2BridgeAgenda.DoInternalDateSelect(EventParams: TStrings);
var
  fs: TFormatSettings;
begin
  if EventParams.Count > 0 then
  begin
    // O browser sempre envia no formato ISO: yyyy-mm-dd
    fs := TFormatSettings.Create;
    fs.DateSeparator := '-';
    fs.ShortDateFormat := 'yyyy-mm-dd';
    try
      FCurrentDate := StrToDate(EventParams[0], fs);
      if Assigned(FOnDateChange) then FOnDateChange(Self);
    except
      // Silencioso se houver erro de conversão
    end;
  end;
end;

function TD2BridgeAgenda.GenerateHTML: string;
var
  HTML: TStringList;
  i, p: Integer;
  SlotTime: TDateTime;
  Found: Boolean;
  AppID, AppClient, AppService, AppStatus, AppColor: string;
  AppStart, AppEnd: TDateTime;
  StyleStr: string;
  ProfPhoto: string;
  ThemeBg, ThemeText, ThemeBorder, ThemeHeaderBg, ThemeHeaderText: string;
begin
  HTML := TStringList.Create;
  try
    // Definição de Cores baseada no Tema
    ThemeBg := '#ffffff';
    ThemeText := '#212529';
    ThemeBorder := '#dee2e6';
    ThemeHeaderBg := FAppearance.HeaderColor;
    ThemeHeaderText := FAppearance.HeaderTextColor;

    case FAppearance.Theme of
      atDark: begin
        ThemeBg := '#212529';
        ThemeText := '#f8f9fa';
        ThemeBorder := '#495057';
        if ThemeHeaderBg = '#ffffff' then ThemeHeaderBg := '#343a40';
        if ThemeHeaderText = '#0d6efd' then ThemeHeaderText := '#ffffff';
      end;
      atSoft: begin
        ThemeBg := '#f8f9fa';
        ThemeText := '#495057';
        if ThemeHeaderBg = '#ffffff' then ThemeHeaderBg := '#e9ceec';
        if ThemeHeaderText = '#0d6efd' then ThemeHeaderText := '#6f42c1';
      end;
      atModern: begin
        ThemeHeaderBg := '#000000';
        ThemeHeaderText := '#ffffff';
      end;
    end;

    // Injeta Fontes Externas se necessário
    if FAppearance.Font in [afRoboto, afOpenSans, afLato] then
    begin
      case FAppearance.Font of
        afRoboto: HTML.Add('<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">');
        afOpenSans: HTML.Add('<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&display=swap" rel="stylesheet">');
        afLato: HTML.Add('<link href="https://fonts.googleapis.com/css2?family=Lato:wght@400;700&display=swap" rel="stylesheet">');
      end;
    end;

    StyleStr := Format('font-family: %s; font-size: %dpx; background-color: %s; color: %s;', 
                [FAppearance.GetFontFamily, FAppearance.FontSize, ThemeBg, ThemeText]);

    HTML.Add('<div class="card shadow-sm border-0" style="' + StyleStr + '">');
    
    // Header customizado
    HTML.Add('<!-- Agenda Version 1.1 - Visibility Logic Updated -->');
    if FAppearance.ShowHeader then
    begin
      // Só cria a div do header se houver algo para mostrar dentro dela
      if FAppearance.ShowDateText or FAppearance.ShowCalendar or FAppearance.ShowNavigation then
      begin
        HTML.Add(Format('  <div class="card-header py-3 d-flex justify-content-between align-items-center border-bottom" style="background-color: %s; color: %s;">', 
                 [ThemeHeaderBg, ThemeHeaderText]));
        
        HTML.Add('    <div class="d-flex align-items-center">');
        // 1. Texto da Data (dd/mm/yyyy)
        if FAppearance.ShowDateText then
          HTML.Add('      <h5 class="mb-0 fw-bold me-3"><i class="fa fa-calendar-alt me-2"></i>' + FormatDateTime('dd/mm/yyyy', FCurrentDate) + '</h5>');
        
        // 2. Seletor de Calendário (Input Date)
        if FAppearance.ShowCalendar then
        begin
          HTML.Add('      <input type="date" class="form-control form-control-sm" style="width: 150px;" ');
          HTML.Add('             value="' + FormatDateTime('yyyy-mm-dd', FCurrentDate) + '" ');
          HTML.Add('             onchange="{{CallBack=AgendaDateSelect([this.value])}}">');
        end;
        HTML.Add('    </div>');

        // 3. Botões de Navegação
        if FAppearance.ShowNavigation then
        begin
          HTML.Add('    <div class="btn-group shadow-sm">');
          HTML.Add('      <button class="btn btn-sm btn-light border" onclick="{{CallBack=AgendaDateNav(prev)}}"><i class="fa fa-chevron-left"></i></button>');
          HTML.Add('      <button class="btn btn-sm btn-light border px-3" onclick="{{CallBack=AgendaDateNav(today)}}">Hoje</button>');
          HTML.Add('      <button class="btn btn-sm btn-light border" onclick="{{CallBack=AgendaDateNav(next)}}"><i class="fa fa-chevron-right"></i></button>');
          HTML.Add('    </div>');
        end;
        HTML.Add('  </div>');
      end;
    end;
    
    HTML.Add('  <div class="card-body p-0">');
    HTML.Add('    <div class="table-responsive">');
    HTML.Add('      <table class="table table-bordered mb-0 align-middle" style="color: inherit; border-color: ' + ThemeBorder + ';">');
    HTML.Add('        <thead class="text-center sticky-top" style="background-color: ' + ThemeBg + ';">');
    HTML.Add('          <tr>');
    HTML.Add('            <th style="width: 80px; background-color: inherit; z-index: 10; border-color: ' + ThemeBorder + ';">Hora</th>');
    for p := 0 to FProfessionals.Count - 1 do
    begin
      ProfPhoto := '';
      if Assigned(FDataSet) and FDataSet.Active then
      begin
        FDataSet.DisableControls;
        try
          if FDataSet.Locate(FFieldMap.FieldProfessional, FProfessionals[p], [loCaseInsensitive]) then
            ProfPhoto := FDataSet.FieldByName(FFieldMap.FieldProfessionalPhoto).AsString;
        finally
          FDataSet.EnableControls;
        end;
      end;

      HTML.Add('            <th style="border-color: ' + ThemeBorder + ';">');
      if ProfPhoto <> '' then
        HTML.Add('              <div class="d-flex flex-column align-items-center"><img src="' + ProfPhoto + '" class="rounded-circle mb-1" style="width: 40px; height: 40px; object-fit: cover; border: 2px solid ' + ThemeHeaderText + ';"><span>' + FProfessionals[p] + '</span></div>')
      else
        HTML.Add('              ' + FProfessionals[p]);
      HTML.Add('            </th>');
    end;
    HTML.Add('          </tr>');
    HTML.Add('        </thead>');
    HTML.Add('        <tbody>');

    for i := FStartTime * (60 div FIntervalMinutes) to (FEndTime * (60 div FIntervalMinutes)) - 1 do
    begin
      SlotTime := IncMinute(EncodeTime(0, 0, 0, 0), i * FIntervalMinutes);
      HTML.Add(Format('          <tr style="height: %dpx;">', [FAppearance.RowHeight]));
      HTML.Add('            <td class="text-center fw-bold small border-end" style="background-color: rgba(0,0,0,0.03); border-color: ' + ThemeBorder + ';">' + FormatTime(SlotTime) + '</td>');

      for p := 0 to FProfessionals.Count - 1 do
      begin
        Found := False;
        if Assigned(FDataSet) and FDataSet.Active then
        begin
          FDataSet.DisableControls;
          try
            FDataSet.First;
            while not FDataSet.Eof do
            begin
              if (SameText(FDataSet.FieldByName(FFieldMap.FieldProfessional).AsString, FProfessionals[p])) and
                 (IsTimeInAppointment(SlotTime, FDataSet.FieldByName(FFieldMap.FieldStartTime).AsDateTime, FDataSet.FieldByName(FFieldMap.FieldEndTime).AsDateTime)) then
              begin
                if Frac(FDataSet.FieldByName(FFieldMap.FieldStartTime).AsDateTime) = Frac(SlotTime) then
                begin
                  AppID := FDataSet.FieldByName(FFieldMap.FieldID).AsString;
                  AppClient := FDataSet.FieldByName(FFieldMap.FieldClient).AsString;
                  AppService := FDataSet.FieldByName(FFieldMap.FieldService).AsString;
                  AppStatus := FDataSet.FieldByName(FFieldMap.FieldStatus).AsString;
                  AppStart := FDataSet.FieldByName(FFieldMap.FieldStartTime).AsDateTime;
                  AppEnd := FDataSet.FieldByName(FFieldMap.FieldEndTime).AsDateTime;
                  AppColor := '#0d6efd';
                  if (FFieldMap.FieldColor <> '') and (FDataSet.FindField(FFieldMap.FieldColor) <> nil) then
                    AppColor := FDataSet.FieldByName(FFieldMap.FieldColor).AsString;

                  HTML.Add('            <td class="p-1" style="min-width: 200px; border-color: ' + ThemeBorder + ';">');
                  HTML.Add('              <div class="card border-0 shadow-sm h-100 p-2" ');
                  HTML.Add('                   style="border-left: 5px solid ' + AppColor + ' !important; cursor: pointer; background-color: ' + ThemeBg + '; color: ' + ThemeText + ';" ');
                  HTML.Add('                   onclick="{{CallBack=AgendaEdit(' + AppID + ')}}">');
                  HTML.Add('                <div class="d-flex justify-content-between align-items-start">');
                  HTML.Add('                  <span class="fw-bold small"><i class="fa fa-user me-1 opacity-50"></i>' + AppClient + '</span>');
                  HTML.Add('                  ' + GetStatusBadge(AppStatus));
                  HTML.Add('                </div>');
                  HTML.Add('                <div class="small opacity-75 mt-1"><i class="fa fa-tag me-1 opacity-50"></i>' + AppService + '</div>');
                  HTML.Add('                <div class="text-end mt-1"><span class="badge bg-light text-dark border-0 small opacity-75">' + FormatTime(AppStart) + ' - ' + FormatTime(AppEnd) + '</span></div>');
                  HTML.Add('              </div>');
                  HTML.Add('            </td>');
                  Found := True;
                end
                else
                begin
                  HTML.Add('            <td class="border-top-0 opacity-25" style="border-color: ' + ThemeBorder + ';"></td>');
                  Found := True;
                end;
                Break;
              end;
              FDataSet.Next;
            end;
          finally
            FDataSet.EnableControls;
          end;
        end;

        if not Found then
        begin
          HTML.Add('            <td class="p-0 text-center align-middle slot-hover" ');
          HTML.Add('                style="cursor: cell; border-color: ' + ThemeBorder + ';" ');
          HTML.Add('                onclick="{{CallBack=AgendaNew(' + FProfessionals[p] + ',' + FormatTime(SlotTime) + ')}}">');
          HTML.Add('              <i class="fa fa-plus opacity-0 text-primary"></i>');
          HTML.Add('            </td>');
        end;
      end;
      HTML.Add('          </tr>');
    end;

    HTML.Add('        </tbody>');
    HTML.Add('      </table>');
    HTML.Add('    </div>');
    HTML.Add('  </div>');
    HTML.Add('</div>');
    HTML.Add(Format('<style>.slot-hover:hover { background-color: %s !important; } .slot-hover:hover i { opacity: 0.5 !important; }</style>', [FAppearance.SlotHoverColor]));
    Result := HTML.Text;
  finally
    HTML.Free;
  end;
end;

end.
