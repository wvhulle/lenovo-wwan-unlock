{ lib
, fetchFromGitHub
, buildFHSEnv
, stdenv
, makeWrapper
}:

let
  pname = "lenovo-wwan-unlock";
  version = "2.1.3";
  src = fetchFromGitHub {
    owner = "lenovo";
    repo = "lenovo-wwan-unlock";
    rev = "6bc2138677cad43cd67fb23ec73869efd8beda46";
    hash = "sha256-ibclz63Nw+ivBx7jdHgAhpTesbHiYn21XpCfQTf4bnI=";
  };
in
buildFHSEnv {
  inherit pname version;

  targetPkgs =
    pkgs: with pkgs; [
      modemmanager
      libmbim
      openssl
      pciutils
      usbutils
      zlib
    ];

  extraBuildCommands = ''
    mkdir -p $out/opt/fcc_lenovo/lib
    tar -zxf ${src}/sar_config_files.tar.gz -C $out/opt/fcc_lenovo/
    cp ${src}/libmodemauth.so $out/opt/fcc_lenovo/lib/
    cp ${src}/libconfigserviceR+.so $out/opt/fcc_lenovo/lib/
    cp ${src}/libconfigservice350.so $out/opt/fcc_lenovo/lib/
    cp ${src}/libmbimtools.so $out/opt/fcc_lenovo/lib/
    cp ${src}/DPR_Fcc_unlock_service $out/opt/fcc_lenovo/
    cp ${src}/configservice_lenovo $out/opt/fcc_lenovo/

    ln -s /.host-etc/udev $out/etc/udev
  '';

  runScript = "$out/opt/fcc_lenovo/configservice_lenovo";
}
