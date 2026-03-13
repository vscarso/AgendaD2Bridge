{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit AgendaD2bridge;

{$warn 5023 off : no warning about unused units}
interface

uses
  untAgendaComponentRegister, untAgendaComponent, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('untAgendaComponentRegister', 
    @untAgendaComponentRegister.Register);
end;

initialization
  RegisterPackage('AgendaD2bridge', @Register);
end.
