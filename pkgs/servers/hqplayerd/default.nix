{ stdenv
, alsa-lib
, addOpenGLRunpath
, autoPatchelfHook
, cairo
, fetchurl
, flac
, gcc11
, gnome
, gssdp
, gupnp
, lib
, libgmpris
, llvmPackages_10
, rpmextract
, wavpack
}:

stdenv.mkDerivation rec {
  pname = "hqplayerd";
  version = "4.26.2-69";

  src = fetchurl {
    url = "https://www.signalyst.eu/bins/${pname}/fc34/${pname}-${version}.fc34.x86_64.rpm";
    sha256 = "sha256-zxUVtOi4fN3EuCbzH/SEse24Qz7/0jozzDX1yW8bhCU=";
  };

  unpackPhase = ''
    ${rpmextract}/bin/rpmextract $src
  '';

  nativeBuildInputs = [ addOpenGLRunpath autoPatchelfHook rpmextract ];

  buildInputs = [
    alsa-lib
    cairo
    flac
    gcc11.cc.lib
    gnome.rygel
    gssdp
    gupnp
    libgmpris
    llvmPackages_10.openmp
    wavpack
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # main executable
    mkdir -p $out/bin
    cp ./usr/bin/hqplayerd $out/bin

    # main configuration
    mkdir -p $out/etc/hqplayer
    cp ./etc/hqplayer/hqplayerd.xml $out/etc/hqplayer/

    # udev rules
    mkdir -p $out/etc/udev/rules.d
    cp ./etc/udev/rules.d/50-taudio2.rules $out/etc/udev/rules.d/

    # kernel module cfgs
    mkdir -p $out/etc/modules-load.d
    cp ./etc/modules-load.d/taudio2.conf $out/etc/modules-load.d/

    # systemd service file
    mkdir -p $out/lib/systemd/system
    cp ./usr/lib/systemd/system/hqplayerd.service $out/lib/systemd/system/

    # documentation
    mkdir -p $out/share/doc/hqplayerd
    cp ./usr/share/doc/hqplayerd/* $out/share/doc/hqplayerd/

    # misc service support files
    mkdir -p $out/var/lib/hqplayer
    cp -r ./var/lib/hqplayer/web $out/var/lib/hqplayer

    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace $out/lib/systemd/system/hqplayerd.service \
      --replace /usr/bin/hqplayerd $out/bin/hqplayerd \
      --replace "NetworkManager-wait-online.service" ""
  '';

  # NB: addOpenGLRunpath needs to run _after_ autoPatchelfHook, which runs in
  # postFixup, so we tack it on here.
  doInstallCheck = true;
  installCheckPhase = ''
    addOpenGLRunpath $out/bin/hqplayerd
    $out/bin/hqplayerd --version
  '';

  meta = with lib; {
    homepage = "https://www.signalyst.com/custom.html";
    description = "High-end upsampling multichannel software embedded HD-audio player";
    license = licenses.unfree;
    maintainers = with maintainers; [ lovesegfault ];
  };
}
