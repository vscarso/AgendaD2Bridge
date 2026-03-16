unit untAgendaComponent;

{$mode delphi}{$H+}
{$MODESWITCH anonymousfunctions}
{$MODESWITCH functionreferences}

interface

uses
  Classes, SysUtils, DB, DateUtils, TypInfo, FPJSON, jsonparser, Generics.Collections, Generics.Defaults;

type
  { TAppointment: Registro interno para otimização }
  TAppointment = class
    ID: string;
    Professional: string;
    Client: string;
    Service: string;
    StartTime: TDateTime;
    EndTime: TDateTime;
    Status: string;
    Color: string;
    { Campos para controle de sobreposição }
    LaneIndex: Integer;
    MaxLanes: Integer;
  end;
  { TAgendaTheme: Temas pré-definidos }
  TAgendaTheme = (atDefault, atDark, atSoft, atModern);

  { TAgendaFont: Fontes permitidas }
  TAgendaFont = (afSansSerif, afSerif, afMonospace, afRoboto, afOpenSans, afLato);

  { TAgendaFieldMap: Mapeamento de campos do DataSet }
  TAgendaFieldMap = class(TPersistent)
  private
    FFieldID: string;
    FFieldDate: string;
    FFieldGroupID: string;
    FFieldProfessional: string;
    FFieldClient: string;
    FFieldService: string;
    FFieldStartTime: string;
    FFieldEndTime: string;
    FFieldStatus: string;
    FFieldColor: string;
    FFieldProfessionalPhoto: string;
    FServiceSeparator: string;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    function ToJSON: string;
    procedure FromJSON(const AJSON: string);
  published
    property FieldID: string read FFieldID write FFieldID;
    property FieldDate: string read FFieldDate write FFieldDate;
    property FieldGroupID: string read FFieldGroupID write FFieldGroupID;
    property FieldProfessional: string read FFieldProfessional write FFieldProfessional;
    property FieldProfessionalPhoto: string read FFieldProfessionalPhoto write FFieldProfessionalPhoto;
    property FieldClient: string read FFieldClient write FFieldClient;
    property FieldService: string read FFieldService write FFieldService;
    property FieldStartTime: string read FFieldStartTime write FFieldStartTime;
    property FieldEndTime: string read FFieldEndTime write FFieldEndTime;
    property FieldStatus: string read FFieldStatus write FFieldStatus;
    property FieldColor: string read FFieldColor write FFieldColor;
    property ServiceSeparator: string read FServiceSeparator write FServiceSeparator;
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
    FShowSelectProfessional: Boolean;
    FAllowNewOnBusySlot: Boolean;
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
    property ShowSelectProfessional: Boolean read FShowSelectProfessional write FShowSelectProfessional default True;
    property AllowNewOnBusySlot: Boolean read FAllowNewOnBusySlot write FAllowNewOnBusySlot default False;
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
    FStatusColors: TStringList;
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
    procedure SetStatusColors(AValue: TStringList);
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
    property _ActionExportImportVisual: string read GetDummyAction;
    property _ActionExportConfig: string read GetDummyAction;
    property _ActionImportConfig: string read GetDummyAction;

    property DataSet: TDataSet read FDataSet write FDataSet;
    property FieldMap: TAgendaFieldMap read FFieldMap write SetFieldMap;
    property Appearance: TAgendaAppearance read FAppearance write SetAppearance;
    property Professionals: TStringList read FProfessionals write SetProfessionals;
    property StatusColors: TStringList read FStatusColors write SetStatusColors;
    property StartTime: Integer read FStartTime write FStartTime default 8;
    property EndTime: Integer read FEndTime write FEndTime default 18;
    property IntervalMinutes: Integer read FIntervalMinutes write FIntervalMinutes default 30;
    property CurrentDate: TDateTime read FCurrentDate write FCurrentDate;
    
    property OnSlotClick: TOnAgendaSlotClick read FOnSlotClick write FOnSlotClick;
    property OnAppointmentClick: TOnAgendaAppointmentClick read FOnAppointmentClick write FOnAppointmentClick;
    property OnDateChange: TNotifyEvent read FOnDateChange write FOnDateChange;
  end;

implementation

type
  { TAppointmentComparer: Comparador para ordenação de horários }
  TAppointmentComparer = class(TInterfacedObject, IComparer<TAppointment>)
  public
    function Compare(constref Left, Right: TAppointment): Integer;
  end;

function TAppointmentComparer.Compare(constref Left, Right: TAppointment): Integer;
begin
  Result := CompareDateTime(Left.StartTime, Right.StartTime);
end;

function AppendServiceText(const Existing, NewValue, Sep: string): string;
var
  L: TStringList;
  i: Integer;
  S: string;
  UseSep: string;
begin
  UseSep := Sep;
  if UseSep = '' then UseSep := ';';

  if Trim(NewValue) = '' then
  begin
    Result := Existing;
    Exit;
  end;

  if Trim(Existing) = '' then
  begin
    Result := NewValue;
    Exit;
  end;

  L := TStringList.Create;
  try
    L.StrictDelimiter := True;
    L.Delimiter := UseSep[1];
    L.DelimitedText := Existing;
    for i := 0 to L.Count - 1 do
      L[i] := Trim(L[i]);
    S := Trim(NewValue);
    if L.IndexOf(S) < 0 then
      L.Add(S);
    Result := L.DelimitedText;
  finally
    L.Free;
  end;
end;

{ TAgendaFieldMap }

constructor TAgendaFieldMap.Create;
begin
  FFieldID := 'ID';
  FFieldDate := 'DATA_AGENDA';
  FFieldGroupID := '';
  FFieldProfessional := 'NOME_PROFISSIONAL';
  FFieldClient := 'NOME_CLIENTE';
  FFieldService := 'NOME_SERVICO';
  FFieldStartTime := 'HORA_INICIO';
  FFieldEndTime := 'HORA_FIM';
  FFieldStatus := 'STATUS';
  FFieldColor := 'COR_AGENDA';
  FFieldProfessionalPhoto := 'FOTO_PROFISSIONAL';
  FServiceSeparator := ';';
end;

procedure TAgendaFieldMap.Assign(Source: TPersistent);
var
  Src: TAgendaFieldMap;
begin
  if Source is TAgendaFieldMap then
  begin
    Src := TAgendaFieldMap(Source);
    FFieldID := Src.FieldID;
    FFieldDate := Src.FieldDate;
    FFieldGroupID := Src.FieldGroupID;
    FFieldProfessional := Src.FieldProfessional;
    FFieldProfessionalPhoto := Src.FieldProfessionalPhoto;
    FFieldClient := Src.FieldClient;
    FFieldService := Src.FieldService;
    FFieldStartTime := Src.FieldStartTime;
    FFieldEndTime := Src.FieldEndTime;
    FFieldStatus := Src.FieldStatus;
    FFieldColor := Src.FieldColor;
    FServiceSeparator := Src.ServiceSeparator;
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
    J.Add('FieldID', FFieldID);
    J.Add('FieldDate', FFieldDate);
    J.Add('FieldGroupID', FFieldGroupID);
    J.Add('FieldProfessional', FFieldProfessional);
    J.Add('FieldProfessionalPhoto', FFieldProfessionalPhoto);
    J.Add('FieldClient', FFieldClient);
    J.Add('FieldService', FFieldService);
    J.Add('FieldStartTime', FFieldStartTime);
    J.Add('FieldEndTime', FFieldEndTime);
    J.Add('FieldStatus', FFieldStatus);
    J.Add('FieldColor', FFieldColor);
    J.Add('ServiceSeparator', FServiceSeparator);
    Result := J.AsJSON;
  finally
    J.Free;
  end;
end;

procedure TAgendaFieldMap.FromJSON(const AJSON: string);
var
  J: TJSONObject;
begin
  J := TJSONObject(GetJSON(AJSON));
  try
    FFieldID := J.Get('FieldID', FFieldID);
    FFieldDate := J.Get('FieldDate', FFieldDate);
    FFieldGroupID := J.Get('FieldGroupID', FFieldGroupID);
    FFieldProfessional := J.Get('FieldProfessional', FFieldProfessional);
    FFieldClient := J.Get('FieldClient', FFieldClient);
    FFieldService := J.Get('FieldService', FFieldService);
    FFieldStartTime := J.Get('FieldStartTime', FFieldStartTime);
    FFieldEndTime := J.Get('FieldEndTime', FFieldEndTime);
    FFieldStatus := J.Get('FieldStatus', FFieldStatus);
    FFieldColor := J.Get('FieldColor', FFieldColor);
    FFieldProfessionalPhoto := J.Get('FieldProfessionalPhoto', FFieldProfessionalPhoto);
    FServiceSeparator := J.Get('ServiceSeparator', FServiceSeparator);
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
  FShowSelectProfessional := True;
  FAllowNewOnBusySlot := False;
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
    FShowSelectProfessional := Src.ShowSelectProfessional;
    FAllowNewOnBusySlot := Src.AllowNewOnBusySlot;
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
    J.Add('Theme', GetEnumName(TypeInfo(TAgendaTheme), Ord(FTheme)));
    J.Add('Font', GetEnumName(TypeInfo(TAgendaFont), Ord(FFont)));
    J.Add('HeaderColor', FHeaderColor);
    J.Add('HeaderTextColor', FHeaderTextColor);
    J.Add('SlotHoverColor', FSlotHoverColor);
    J.Add('RowHeight', FRowHeight);
    J.Add('FontSize', FFontSize);
    J.Add('ShowCalendar', FShowCalendar);
    J.Add('ShowNavigation', FShowNavigation);
    J.Add('ShowDateText', FShowDateText);
    J.Add('ShowHeader', FShowHeader);
    J.Add('ShowSelectProfessional', FShowSelectProfessional);
    J.Add('AllowNewOnBusySlot', FAllowNewOnBusySlot);
    Result := J.AsJSON;
  finally
    J.Free;
  end;
end;

procedure TAgendaAppearance.FromJSON(const AJSON: string);
var
  J: TJSONObject;
  Data: TJSONData;
begin
  Data := GetJSON(AJSON);
  if not (Data is TJSONObject) then
  begin
    if Assigned(Data) then Data.Free;
    Exit;
  end;
  J := TJSONObject(Data);
  try
    FTheme := TAgendaTheme(GetEnumValue(TypeInfo(TAgendaTheme), J.Get('Theme', 'atDefault')));
    FFont := TAgendaFont(GetEnumValue(TypeInfo(TAgendaFont), J.Get('Font', 'afSansSerif')));
    FHeaderColor := J.Get('HeaderColor', FHeaderColor);
    FHeaderTextColor := J.Get('HeaderTextColor', FHeaderTextColor);
    FSlotHoverColor := J.Get('SlotHoverColor', FSlotHoverColor);
    FRowHeight := J.Get('RowHeight', FRowHeight);
    FFontSize := J.Get('FontSize', FFontSize);
    
    if J.Find('ShowCalendar') <> nil then FShowCalendar := J.Booleans['ShowCalendar'];
    if J.Find('ShowNavigation') <> nil then FShowNavigation := J.Booleans['ShowNavigation'];
    if J.Find('ShowDateText') <> nil then FShowDateText := J.Booleans['ShowDateText'];
    if J.Find('ShowHeader') <> nil then FShowHeader := J.Booleans['ShowHeader'];
    if J.Find('ShowSelectProfessional') <> nil then FShowSelectProfessional := J.Booleans['ShowSelectProfessional'];
    if J.Find('AllowNewOnBusySlot') <> nil then FAllowNewOnBusySlot := J.Booleans['AllowNewOnBusySlot'];
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
  FStatusColors := TStringList.Create;
  FStatusColors.Values['Agendado'] := 'primary';
  FStatusColors.Values['Confirmado'] := 'success';
  FStatusColors.Values['Cancelado'] := 'danger';
  FStatusColors.Values['Finalizado'] := 'secondary';
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
  FStatusColors.Free;
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

procedure TD2BridgeAgenda.SetStatusColors(AValue: TStringList);
begin
  FStatusColors.Assign(AValue);
end;

function TD2BridgeAgenda.GetStatusBadge(const Status: string): string;
var
  Color: string;
begin
  Color := FStatusColors.Values[Status];
  if Color = '' then Color := 'info';
  Result := Format('<span class="badge bg-%s">%s</span>', [Color, Status]);
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
    fs := DefaultFormatSettings;
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
  i, p, k, j, pm: Integer;
  SlotTime: TDateTime;
  Found: Boolean;
  StyleStr: string;
  ProfPhoto: string;
  ThemeBg, ThemeText, ThemeBorder, ThemeHeaderBg, ThemeHeaderText: string;
  Appointments: TObjectList<TAppointment>;
  App, AppNext, AppCompare: TAppointment;
  ProfPhotos: TDictionary<string, string>;
  AppMap: TDictionary<string, TAppointment>;
  MergeKey: string;
  MergeSep: string;
  MergeGroupID: string;
  ProfApps: TObjectList<TAppointment>;
  Cluster: TObjectList<TAppointment>;
  Services: TStringList;
  ServiceBadges: string;
  AppHeight: Integer;
  AppWidth, AppLeft: string;
  AppTop: Integer;
  AppStartMinutes: Integer;
  StartSlotIndex: Integer;
  ClusterEnd: TDateTime;
  InCluster: Boolean;
  fs: TFormatSettings;
  AppDate: TDateTime;
  DateField: TField;
  GroupField: TField;
  StartValue: TDateTime;
  EndValue: TDateTime;
  StartField: TField;
  EndField: TField;
  TimeFS: TFormatSettings;
  NewService: string;
begin
  HTML := TStringList.Create;
  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := #0;
  TimeFS := DefaultFormatSettings;
  TimeFS.TimeSeparator := ':';
  
  Appointments := TObjectList<TAppointment>.Create(True);
  ProfPhotos := TDictionary<string, string>.Create;
  AppMap := TDictionary<string, TAppointment>.Create;
  Services := TStringList.Create;
  try
    MergeSep := FFieldMap.ServiceSeparator;
    if MergeSep = '' then MergeSep := ';';

    // 1. Pré-processamento dos Dados (Otimização e Overlap)
    if Assigned(FDataSet) and FDataSet.Active then
    begin
      FDataSet.DisableControls;
      try
        FDataSet.First;
        while not FDataSet.Eof do
        begin
          DateField := nil;
          if FFieldMap.FieldDate <> '' then
            DateField := FDataSet.FindField(FFieldMap.FieldDate);

          if DateField <> nil then
            AppDate := DateOf(DateField.AsDateTime)
          else
            AppDate := DateOf(FCurrentDate);

          if (DateField = nil) or (AppDate = DateOf(FCurrentDate)) then
          begin
            NewService := FDataSet.FieldByName(FFieldMap.FieldService).AsString;
            StartField := FDataSet.FieldByName(FFieldMap.FieldStartTime);
            EndField := FDataSet.FieldByName(FFieldMap.FieldEndTime);
            StartValue := StartField.AsDateTime;
            EndValue := EndField.AsDateTime;
            if StartField.DataType in [ftString, ftFixedChar, ftWideString, ftMemo, ftWideMemo] then
              if not TryStrToTime(StartField.AsString, StartValue, TimeFS) then
                StartValue := 0;
            if EndField.DataType in [ftString, ftFixedChar, ftWideString, ftMemo, ftWideMemo] then
              if not TryStrToTime(EndField.AsString, EndValue, TimeFS) then
                EndValue := 0;

            MergeGroupID := '';
            GroupField := nil;
            if FFieldMap.FieldGroupID <> '' then
              GroupField := FDataSet.FindField(FFieldMap.FieldGroupID);
            if GroupField <> nil then
              MergeGroupID := GroupField.AsString;

            MergeKey := '';
            if MergeGroupID <> '' then
              MergeKey := 'G|' + MergeGroupID
            else
              MergeKey := 'S|' +
                         FDataSet.FieldByName(FFieldMap.FieldProfessional).AsString + '|' +
                         FormatDateTime('yyyymmddhhnnss', Trunc(AppDate) + Frac(StartValue)) + '|' +
                         FormatDateTime('yyyymmddhhnnss', Trunc(AppDate) + Frac(EndValue)) + '|' +
                         FDataSet.FieldByName(FFieldMap.FieldClient).AsString;

            if AppMap.TryGetValue(MergeKey, App) then
            begin
              App.Service := AppendServiceText(App.Service, NewService, MergeSep);
            end
            else
            begin
              App := TAppointment.Create;
              if MergeGroupID <> '' then
                App.ID := MergeGroupID
              else
                App.ID := FDataSet.FieldByName(FFieldMap.FieldID).AsString;

              App.Professional := FDataSet.FieldByName(FFieldMap.FieldProfessional).AsString;
              App.Client := FDataSet.FieldByName(FFieldMap.FieldClient).AsString;
              App.Service := NewService;
              App.StartTime := Trunc(AppDate) + Frac(StartValue);
              App.EndTime := Trunc(AppDate) + Frac(EndValue);
              App.Status := FDataSet.FieldByName(FFieldMap.FieldStatus).AsString;
              App.Color := '#0d6efd';
              if (FFieldMap.FieldColor <> '') and (FDataSet.FindField(FFieldMap.FieldColor) <> nil) then
                App.Color := FDataSet.FieldByName(FFieldMap.FieldColor).AsString;

              Appointments.Add(App);
              AppMap.Add(MergeKey, App);

              if not ProfPhotos.ContainsKey(App.Professional) then
                ProfPhotos.Add(App.Professional, FDataSet.FieldByName(FFieldMap.FieldProfessionalPhoto).AsString);
            end;
          end;
          FDataSet.Next;
        end;
      finally
        FDataSet.EnableControls;
      end;
    end;

    // 2. Detecção de Overlaps por Profissional
    for p := 0 to FProfessionals.Count - 1 do
    begin
      ProfApps := TObjectList<TAppointment>.Create(False);
      try
        for App in Appointments do
          if SameText(App.Professional, FProfessionals[p]) then
            ProfApps.Add(App);
        
        // Ordenar por horário de início
        ProfApps.Sort(TAppointmentComparer.Create);

        // Algoritmo de Cluster e Lane Assignment
        i := 0;
        while i < ProfApps.Count do
        begin
          Cluster := TObjectList<TAppointment>.Create(False);
          try
            App := ProfApps[i];
            Cluster.Add(App);
            ClusterEnd := App.EndTime;
            
            // Encontrar todos os agendamentos que pertencem a este cluster
            j := i + 1;
            while (j < ProfApps.Count) and (ProfApps[j].StartTime < ClusterEnd) do
            begin
              AppNext := ProfApps[j];
              Cluster.Add(AppNext);
              if AppNext.EndTime > ClusterEnd then ClusterEnd := AppNext.EndTime;
              Inc(j);
            end;

            // Atribuir LaneIndex dentro do cluster
            for k := 0 to Cluster.Count - 1 do
            begin
              App := Cluster[k];
              App.LaneIndex := 0;
              repeat
                Found := False;
                for j := 0 to k - 1 do
                begin
                  AppCompare := Cluster[j];
                  if (AppCompare.LaneIndex = App.LaneIndex) and
                     (App.StartTime < AppCompare.EndTime) and (AppCompare.StartTime < App.EndTime) then
                  begin
                    Found := True;
                    Break;
                  end;
                end;
                if Found then Inc(App.LaneIndex);
              until not Found;
            end;

            // Encontrar o maior LaneIndex no cluster para determinar a largura
            j := 0;
            for k := 0 to Cluster.Count - 1 do
              if Cluster[k].LaneIndex > j then j := Cluster[k].LaneIndex;
            
            for k := 0 to Cluster.Count - 1 do
              Cluster[k].MaxLanes := j + 1;

            i := i + Cluster.Count;
          finally
            Cluster.Free;
          end;
        end;
      finally
        ProfApps.Free;
      end;
    end;

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
    HTML.Add('<!-- Agenda Version 1.3 - Overlap Support -->');
    if FAppearance.ShowHeader then
    begin
      if FAppearance.ShowDateText or FAppearance.ShowCalendar or FAppearance.ShowNavigation then
      begin
        HTML.Add(Format('  <div class="card-header py-3 d-flex justify-content-between align-items-center border-bottom" style="background-color: %s; color: %s;">', 
                 [ThemeHeaderBg, ThemeHeaderText]));
        
        HTML.Add('    <div class="d-flex align-items-center">');
        if FAppearance.ShowDateText then
          HTML.Add('      <h5 class="mb-0 fw-bold me-3"><i class="fa fa-calendar-alt me-2"></i>' + FormatDateTime('dd/mm/yyyy', FCurrentDate) + '</h5>');
        
        if FAppearance.ShowCalendar then
        begin
          HTML.Add('      <input type="date" class="form-control form-control-sm" style="width: 150px;" ');
          HTML.Add('             value="' + FormatDateTime('yyyy-mm-dd', FCurrentDate) + '" ');
          HTML.Add('             onchange="{{CallBack=AgendaDateSelect([this.value])}}">');
        end;
        HTML.Add('    </div>');

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
    HTML.Add('    <div class="agenda-desktop">');
    HTML.Add('      <div class="table-responsive">');
    HTML.Add('        <table class="table table-bordered mb-0 align-middle" style="color: inherit; border-color: ' + ThemeBorder + ';">');
    HTML.Add('          <thead class="text-center sticky-top" style="background-color: ' + ThemeBg + ';">');
    HTML.Add('            <tr>');
    HTML.Add('              <th style="width: 80px; background-color: inherit; z-index: 100; border-color: ' + ThemeBorder + ';">Hora</th>');
    for p := 0 to FProfessionals.Count - 1 do
    begin
      if not ProfPhotos.TryGetValue(FProfessionals[p], ProfPhoto) then
        ProfPhoto := '';

      HTML.Add('              <th style="border-color: ' + ThemeBorder + ';">');
      if ProfPhoto <> '' then
        HTML.Add('                <div class="d-flex flex-column align-items-center"><img src="' + ProfPhoto + '" class="rounded-circle mb-1" style="width: 40px; height: 40px; object-fit: cover; border: 2px solid ' + ThemeHeaderText + ';"><span>' + FProfessionals[p] + '</span></div>')
      else
        HTML.Add('                ' + FProfessionals[p]);
      HTML.Add('              </th>');
    end;
    HTML.Add('            </tr>');
    HTML.Add('          </thead>');
    HTML.Add('          <tbody>');

    for i := FStartTime * (60 div FIntervalMinutes) to (FEndTime * (60 div FIntervalMinutes)) - 1 do
    begin
      SlotTime := IncMinute(EncodeTime(0, 0, 0, 0), i * FIntervalMinutes);
      HTML.Add(Format('            <tr style="height: %dpx;">', [FAppearance.RowHeight]));
      HTML.Add('              <td class="text-center fw-bold small border-end" style="background-color: rgba(0,0,0,0.03); border-color: ' + ThemeBorder + ';">' + FormatTime(SlotTime) + '</td>');

      for p := 0 to FProfessionals.Count - 1 do
      begin
        HTML.Add(Format('              <td class="p-0 position-relative" style="border-color: %s; min-width: 200px; height: %dpx; overflow: visible;">', [ThemeBorder, FAppearance.RowHeight]));
        
        for App in Appointments do
        begin
          if SameText(App.Professional, FProfessionals[p]) then
          begin
            AppStartMinutes := (HourOf(App.StartTime) * 60) + MinuteOf(App.StartTime);
            StartSlotIndex := AppStartMinutes div FIntervalMinutes;
            if StartSlotIndex <> i then
              Continue;

            AppHeight := Round((MinutesBetween(App.EndTime, App.StartTime) / FIntervalMinutes) * FAppearance.RowHeight);
            if AppHeight < FAppearance.RowHeight then AppHeight := FAppearance.RowHeight;
            
            AppTop := Round(((AppStartMinutes mod FIntervalMinutes) / FIntervalMinutes) * FAppearance.RowHeight);
            AppWidth := FloatToStr(100 / App.MaxLanes, fs) + '%';
            AppLeft := FloatToStr((App.LaneIndex / App.MaxLanes) * 100, fs) + '%';
            
            ServiceBadges := '';
            Services.Clear;
            if FFieldMap.ServiceSeparator <> '' then
              Services.Delimiter := FFieldMap.ServiceSeparator[1]
            else
              Services.Delimiter := ';';
            Services.StrictDelimiter := True;
            Services.DelimitedText := App.Service;
            for k := 0 to Services.Count - 1 do
              ServiceBadges := ServiceBadges + '<div class="small opacity-75 mt-1"><i class="fa fa-tag me-1 opacity-50"></i>' + Services[k] + '</div>';

            HTML.Add(Format('                <div class="card border-0 shadow-sm p-2 position-absolute" ', []));
            HTML.Add(Format('                     style="top: %dpx; left: %s; width: %s; height: %dpx; z-index: 10; border-left: 5px solid %s !important; cursor: pointer; background-color: %s; color: %s; overflow: hidden;" ', 
                     [AppTop, AppLeft, AppWidth, AppHeight - 2, App.Color, ThemeBg, ThemeText]));
            HTML.Add('                     onclick="{{CallBack=AgendaEdit(' + App.ID + ')}}">');
            HTML.Add('                  <div class="d-flex justify-content-between align-items-start">');
            HTML.Add('                    <span class="fw-bold small text-truncate"><i class="fa fa-user me-1 opacity-50"></i>' + App.Client + '</span>');
            HTML.Add('                    ' + GetStatusBadge(App.Status));
            HTML.Add('                  </div>');
            HTML.Add(ServiceBadges);
            HTML.Add('                  <div class="text-end mt-auto"><span class="badge bg-light text-dark border-0 small opacity-75">' + FormatTime(App.StartTime) + ' - ' + FormatTime(App.EndTime) + '</span></div>');
            HTML.Add('                </div>');
          end;
        end;

        Found := False;
        for App in Appointments do
        begin
          if SameText(App.Professional, FProfessionals[p]) and IsTimeInAppointment(SlotTime, App.StartTime, App.EndTime) then
          begin
            Found := True;
            Break;
          end;
        end;
        if (not Found) or FAppearance.AllowNewOnBusySlot then
        begin
          HTML.Add('                <div class="slot-hover position-absolute top-0 start-0 w-100 h-100 text-center align-middle" ');
          HTML.Add('                     style="cursor: cell; z-index: 1; display: flex; align-items: center; justify-content: center;" ');
          HTML.Add('                     onclick="{{CallBack=AgendaNew(' + FProfessionals[p] + '&' + FormatTime(SlotTime) + ')}}">');
          HTML.Add('                  <i class="fa fa-plus opacity-0 text-primary"></i>');
          HTML.Add('                </div>');
        end;

        HTML.Add('              </td>');
      end;
      HTML.Add('            </tr>');
    end;

    HTML.Add('          </tbody>');
    HTML.Add('        </table>');
    HTML.Add('      </div>');
    HTML.Add('    </div>');

    HTML.Add('    <div class="agenda-mobile">');
    if FAppearance.ShowSelectProfessional then
    begin
      HTML.Add('      <div class="p-2 border-bottom" style="background-color: ' + ThemeBg + '; color: ' + ThemeText + ';">');
      HTML.Add('        <select class="form-select form-select-sm" onchange="agendaSelectProfessional(this.value)">');
      for pm := 0 to FProfessionals.Count - 1 do
        HTML.Add('          <option value="' + IntToStr(pm) + '">' + FProfessionals[pm] + '</option>');
      HTML.Add('        </select>');
      HTML.Add('      </div>');
    end;

    for pm := 0 to FProfessionals.Count - 1 do
    begin
      if not ProfPhotos.TryGetValue(FProfessionals[pm], ProfPhoto) then
        ProfPhoto := '';

      if FAppearance.ShowSelectProfessional then
      begin
        if pm = 0 then
          HTML.Add('      <div class="agenda-prof-section border-bottom" data-prof-index="' + IntToStr(pm) + '" style="display: block;">')
        else
          HTML.Add('      <div class="agenda-prof-section border-bottom" data-prof-index="' + IntToStr(pm) + '" style="display: none;">');
      end
      else
        HTML.Add('      <div class="agenda-prof-section border-bottom" data-prof-index="' + IntToStr(pm) + '">');

      HTML.Add('      <div class="px-3 py-2" style="background-color: ' + ThemeBg + '; color: ' + ThemeText + ';">');
      if ProfPhoto <> '' then
        HTML.Add('        <div class="d-flex align-items-center"><img src="' + ProfPhoto + '" class="rounded-circle me-2" style="width: 34px; height: 34px; object-fit: cover; border: 2px solid ' + ThemeHeaderText + ';"><div class="fw-bold">' + FProfessionals[pm] + '</div></div>')
      else
        HTML.Add('        <div class="fw-bold">' + FProfessionals[pm] + '</div>');
      HTML.Add('      </div>');

      HTML.Add('      <div style="overflow-x: hidden;">');
      HTML.Add('        <table class="table table-bordered mb-0 align-middle" style="table-layout: fixed; width: 100%; color: inherit; border-color: ' + ThemeBorder + ';">');
      HTML.Add('          <thead class="text-center sticky-top" style="background-color: ' + ThemeBg + ';">');
      HTML.Add('            <tr>');
      HTML.Add('              <th style="width: 72px; background-color: inherit; z-index: 100; border-color: ' + ThemeBorder + ';">Hora</th>');
      HTML.Add('              <th style="border-color: ' + ThemeBorder + ';">Agenda</th>');
      HTML.Add('            </tr>');
      HTML.Add('          </thead>');
      HTML.Add('          <tbody>');

      for i := FStartTime * (60 div FIntervalMinutes) to (FEndTime * (60 div FIntervalMinutes)) - 1 do
      begin
        SlotTime := IncMinute(EncodeTime(0, 0, 0, 0), i * FIntervalMinutes);
        HTML.Add(Format('            <tr style="height: %dpx;">', [FAppearance.RowHeight]));
        HTML.Add('              <td class="text-center fw-bold small border-end" style="background-color: rgba(0,0,0,0.03); border-color: ' + ThemeBorder + ';">' + FormatTime(SlotTime) + '</td>');
        HTML.Add(Format('              <td class="p-0 position-relative" style="border-color: %s; height: %dpx; overflow: visible;">', [ThemeBorder, FAppearance.RowHeight]));

        for App in Appointments do
        begin
          if SameText(App.Professional, FProfessionals[pm]) then
          begin
            AppStartMinutes := (HourOf(App.StartTime) * 60) + MinuteOf(App.StartTime);
            StartSlotIndex := AppStartMinutes div FIntervalMinutes;
            if StartSlotIndex <> i then
              Continue;

            AppHeight := Round((MinutesBetween(App.EndTime, App.StartTime) / FIntervalMinutes) * FAppearance.RowHeight);
            if AppHeight < FAppearance.RowHeight then AppHeight := FAppearance.RowHeight;
            
            AppTop := Round(((AppStartMinutes mod FIntervalMinutes) / FIntervalMinutes) * FAppearance.RowHeight);
            AppWidth := FloatToStr(100 / App.MaxLanes, fs) + '%';
            AppLeft := FloatToStr((App.LaneIndex / App.MaxLanes) * 100, fs) + '%';

            ServiceBadges := '';
            Services.Clear;
            if FFieldMap.ServiceSeparator <> '' then
              Services.Delimiter := FFieldMap.ServiceSeparator[1]
            else
              Services.Delimiter := ';';
            Services.StrictDelimiter := True;
            Services.DelimitedText := App.Service;
            for k := 0 to Services.Count - 1 do
              ServiceBadges := ServiceBadges + '<div class="small opacity-75 mt-1"><i class="fa fa-tag me-1 opacity-50"></i>' + Services[k] + '</div>';

            HTML.Add(Format('                <div class="card border-0 shadow-sm p-2 position-absolute" ', []));
            HTML.Add(Format('                     style="top: %dpx; left: %s; width: %s; height: %dpx; z-index: 10; border-left: 5px solid %s !important; cursor: pointer; background-color: %s; color: %s; overflow: hidden;" ',
                     [AppTop, AppLeft, AppWidth, AppHeight - 2, App.Color, ThemeBg, ThemeText]));
            HTML.Add('                     onclick="{{CallBack=AgendaEdit(' + App.ID + ')}}">');
            HTML.Add('                  <div class="d-flex justify-content-between align-items-start">');
            HTML.Add('                    <span class="fw-bold small text-truncate"><i class="fa fa-user me-1 opacity-50"></i>' + App.Client + '</span>');
            HTML.Add('                    ' + GetStatusBadge(App.Status));
            HTML.Add('                  </div>');
            HTML.Add(ServiceBadges);
            HTML.Add('                  <div class="text-end mt-auto"><span class="badge bg-light text-dark border-0 small opacity-75">' + FormatTime(App.StartTime) + ' - ' + FormatTime(App.EndTime) + '</span></div>');
            HTML.Add('                </div>');
          end;
        end;

        Found := False;
        for App in Appointments do
        begin
          if SameText(App.Professional, FProfessionals[pm]) and IsTimeInAppointment(SlotTime, App.StartTime, App.EndTime) then
          begin
            Found := True;
            Break;
          end;
        end;
        if (not Found) or FAppearance.AllowNewOnBusySlot then
        begin
          HTML.Add('                <div class="slot-hover position-absolute top-0 start-0 w-100 h-100 text-center align-middle" ');
          HTML.Add('                     style="cursor: cell; z-index: 1; display: flex; align-items: center; justify-content: center;" ');
          HTML.Add('                     onclick="{{CallBack=AgendaNew(' + FProfessionals[pm] + '&' + FormatTime(SlotTime) + ')}}">');
          HTML.Add('                  <i class="fa fa-plus opacity-0 text-primary"></i>');
          HTML.Add('                </div>');
        end;

        HTML.Add('              </td>');
        HTML.Add('            </tr>');
      end;

      HTML.Add('          </tbody>');
      HTML.Add('        </table>');
      HTML.Add('      </div>');
      HTML.Add('      </div>');
    end;
    HTML.Add('    </div>');

    HTML.Add('  </div>');
    HTML.Add('</div>');
    HTML.Add(Format('<style>.slot-hover:hover { background-color: %s !important; } .slot-hover:hover i { opacity: 0.5 !important; } .agenda-mobile { display: none; } @media (max-width: 768px) { .agenda-desktop { display: none; } .agenda-mobile { display: block; } } @media (min-width: 769px) { .agenda-desktop { display: block; } .agenda-mobile { display: none; } }</style>', [FAppearance.SlotHoverColor]));
    if FAppearance.ShowSelectProfessional then
    begin
      HTML.Add('<script>(function(){function show(idx){var els=document.querySelectorAll(".agenda-prof-section");for(var i=0;i<els.length;i++){els[i].style.display=(els[i].getAttribute("data-prof-index")==idx)?"block":"none";}}window.agendaSelectProfessional=function(idx){show(String(idx));};show("0");})();</script>');
    end;
    Result := HTML.Text;
  finally
    Services.Free;
    Appointments.Free;
    AppMap.Free;
    ProfPhotos.Free;
    HTML.Free;
  end;
end;

end.
