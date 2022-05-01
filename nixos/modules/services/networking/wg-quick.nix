{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.networking.wg-quick;

  kernel = config.boot.kernelPackages;

  # interface options

  interfaceOpts = { ... }: {
    options = {

      configFile = mkOption {
        example = "/secret/wg0.conf";
        default = null;
        type = with types; nullOr str;
        description = ''
          wg-quick .conf file, describing the interface.
          This overrides any other configuration interface configuration options.
          See wg-quick manpage for more details.
        '';
      };

      address = mkOption {
        example = [ "192.168.2.1/24" ];
        default = [];
        type = with types; listOf str;
        description = "The IP addresses of the interface.";
      };

      autostart = mkOption {
        description = "Whether to bring up this interface automatically during boot.";
        default = true;
        example = false;
        type = types.bool;
      };

      dns = mkOption {
        example = [ "192.168.2.2" ];
        default = [];
        type = with types; listOf str;
        description = "The IP addresses of DNS servers to configure.";
      };

      privateKey = mkOption {
        example = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=";
        type = with types; nullOr str;
        default = null;
        description = ''
          Base64 private key generated by <command>wg genkey</command>.

          Warning: Consider using privateKeyFile instead if you do not
          want to store the key in the world-readable Nix store.
        '';
      };

      privateKeyFile = mkOption {
        example = "/private/wireguard_key";
        type = with types; nullOr str;
        default = null;
        description = ''
          Private key file as generated by <command>wg genkey</command>.
        '';
      };

      listenPort = mkOption {
        default = null;
        type = with types; nullOr int;
        example = 51820;
        description = ''
          16-bit port for listening. Optional; if not specified,
          automatically generated based on interface name.
        '';
      };

      preUp = mkOption {
        example = literalExpression ''"''${pkgs.iproute2}/bin/ip netns add foo"'';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = ''
          Commands called at the start of the interface setup.
        '';
      };

      preDown = mkOption {
        example = literalExpression ''"''${pkgs.iproute2}/bin/ip netns del foo"'';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = ''
          Command called before the interface is taken down.
        '';
      };

      postUp = mkOption {
        example = literalExpression ''"''${pkgs.iproute2}/bin/ip netns add foo"'';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = ''
          Commands called after the interface setup.
        '';
      };

      postDown = mkOption {
        example = literalExpression ''"''${pkgs.iproute2}/bin/ip netns del foo"'';
        default = "";
        type = with types; coercedTo (listOf str) (concatStringsSep "\n") lines;
        description = ''
          Command called after the interface is taken down.
        '';
      };

      table = mkOption {
        example = "main";
        default = null;
        type = with types; nullOr str;
        description = ''
          The kernel routing table to add this interface's
          associated routes to. Setting this is useful for e.g. policy routing
          ("ip rule") or virtual routing and forwarding ("ip vrf"). Both
          numeric table IDs and table names (/etc/rt_tables) can be used.
          Defaults to "main".
        '';
      };

      mtu = mkOption {
        example = 1248;
        default = null;
        type = with types; nullOr int;
        description = ''
          If not specified, the MTU is automatically determined
          from the endpoint addresses or the system default route, which is usually
          a sane choice. However, to manually specify an MTU to override this
          automatic discovery, this value may be specified explicitly.
        '';
      };

      peers = mkOption {
        default = [];
        description = "Peers linked to the interface.";
        type = with types; listOf (submodule peerOpts);
      };
    };
  };

  # peer options

  peerOpts = {
    options = {
      publicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.str;
        description = "The base64 public key to the peer.";
      };

      presharedKey = mkOption {
        default = null;
        example = "rVXs/Ni9tu3oDBLS4hOyAUAa1qTWVA3loR8eL20os3I=";
        type = with types; nullOr str;
        description = ''
          Base64 preshared key generated by <command>wg genpsk</command>.
          Optional, and may be omitted. This option adds an additional layer of
          symmetric-key cryptography to be mixed into the already existing
          public-key cryptography, for post-quantum resistance.

          Warning: Consider using presharedKeyFile instead if you do not
          want to store the key in the world-readable Nix store.
        '';
      };

      presharedKeyFile = mkOption {
        default = null;
        example = "/private/wireguard_psk";
        type = with types; nullOr str;
        description = ''
          File pointing to preshared key as generated by <command>wg genpsk</command>.
          Optional, and may be omitted. This option adds an additional layer of
          symmetric-key cryptography to be mixed into the already existing
          public-key cryptography, for post-quantum resistance.
        '';
      };

      allowedIPs = mkOption {
        example = [ "10.192.122.3/32" "10.192.124.1/24" ];
        type = with types; listOf str;
        description = ''List of IP (v4 or v6) addresses with CIDR masks from
        which this peer is allowed to send incoming traffic and to which
        outgoing traffic for this peer is directed. The catch-all 0.0.0.0/0 may
        be specified for matching all IPv4 addresses, and ::/0 may be specified
        for matching all IPv6 addresses.'';
      };

      endpoint = mkOption {
        default = null;
        example = "demo.wireguard.io:12913";
        type = with types; nullOr str;
        description = ''Endpoint IP or hostname of the peer, followed by a colon,
        and then a port number of the peer.'';
      };

      persistentKeepalive = mkOption {
        default = null;
        type = with types; nullOr int;
        example = 25;
        description = ''This is optional and is by default off, because most
        users will not need it. It represents, in seconds, between 1 and 65535
        inclusive, how often to send an authenticated empty packet to the peer,
        for the purpose of keeping a stateful firewall or NAT mapping valid
        persistently. For example, if the interface very rarely sends traffic,
        but it might at anytime receive traffic from a peer, and it is behind
        NAT, the interface might benefit from having a persistent keepalive
        interval of 25 seconds; however, most users will not need this.'';
      };
    };
  };

  writeScriptFile = name: text: ((pkgs.writeShellScriptBin name text) + "/bin/${name}");

  generateUnit = name: values:
    assert assertMsg (values.configFile != null || ((values.privateKey != null) != (values.privateKeyFile != null))) "Only one of privateKey, configFile or privateKeyFile may be set";
    let
      preUpFile = if values.preUp != "" then writeScriptFile "preUp.sh" values.preUp else null;
      postUp =
            optional (values.privateKeyFile != null) "wg set ${name} private-key <(cat ${values.privateKeyFile})" ++
            (concatMap (peer: optional (peer.presharedKeyFile != null) "wg set ${name} peer ${peer.publicKey} preshared-key <(cat ${peer.presharedKeyFile})") values.peers) ++
            optional (values.postUp != null) values.postUp;
      postUpFile = if postUp != [] then writeScriptFile "postUp.sh" (concatMapStringsSep "\n" (line: line) postUp) else null;
      preDownFile = if values.preDown != "" then writeScriptFile "preDown.sh" values.preDown else null;
      postDownFile = if values.postDown != "" then writeScriptFile "postDown.sh" values.postDown else null;
      configDir = pkgs.writeTextFile {
        name = "config-${name}";
        executable = false;
        destination = "/${name}.conf";
        text =
        ''
        [interface]
        ${concatMapStringsSep "\n" (address:
          "Address = ${address}"
        ) values.address}
        ${concatMapStringsSep "\n" (dns:
          "DNS = ${dns}"
        ) values.dns}
        '' +
        optionalString (values.table != null) "Table = ${values.table}\n" +
        optionalString (values.mtu != null) "MTU = ${toString values.mtu}\n" +
        optionalString (values.privateKey != null) "PrivateKey = ${values.privateKey}\n" +
        optionalString (values.listenPort != null) "ListenPort = ${toString values.listenPort}\n" +
        optionalString (preUpFile != null) "PreUp = ${preUpFile}\n" +
        optionalString (postUpFile != null) "PostUp = ${postUpFile}\n" +
        optionalString (preDownFile != null) "PreDown = ${preDownFile}\n" +
        optionalString (postDownFile != null) "PostDown = ${postDownFile}\n" +
        concatMapStringsSep "\n" (peer:
          assert assertMsg (!((peer.presharedKeyFile != null) && (peer.presharedKey != null))) "Only one of presharedKey or presharedKeyFile may be set";
          "[Peer]\n" +
          "PublicKey = ${peer.publicKey}\n" +
          optionalString (peer.presharedKey != null) "PresharedKey = ${peer.presharedKey}\n" +
          optionalString (peer.endpoint != null) "Endpoint = ${peer.endpoint}\n" +
          optionalString (peer.persistentKeepalive != null) "PersistentKeepalive = ${toString peer.persistentKeepalive}\n" +
          optionalString (peer.allowedIPs != []) "AllowedIPs = ${concatStringsSep "," peer.allowedIPs}\n"
        ) values.peers;
      };
      configPath =
        if values.configFile != null then
          # This uses bind-mounted private tmp folder (/tmp/systemd-private-***)
          "/tmp/${name}.conf"
        else
          "${configDir}/${name}.conf";
    in
    nameValuePair "wg-quick-${name}"
      {
        description = "wg-quick WireGuard Tunnel - ${name}";
        requires = [ "network-online.target" ];
        after = [ "network.target" "network-online.target" ];
        wantedBy = optional values.autostart "multi-user.target";
        environment.DEVICE = name;
        path = [ pkgs.kmod pkgs.wireguard-tools ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          ${optionalString (!config.boot.isContainer) "modprobe wireguard"}
          ${optionalString (values.configFile != null) ''
            cp ${values.configFile} ${configPath}
          ''}
          wg-quick up ${configPath}
        '';

        serviceConfig = {
          # Used to privately store renamed copies of external config files during activation
          PrivateTmp = true;
        };

        preStop = ''
          wg-quick down ${configPath}
        '';
      };
in {

  ###### interface

  options = {
    networking.wg-quick = {
      interfaces = mkOption {
        description = "Wireguard interfaces.";
        default = {};
        example = {
          wg0 = {
            address = [ "192.168.20.4/24" ];
            privateKey = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=";
            peers = [
              { allowedIPs = [ "192.168.20.1/32" ];
                publicKey  = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
                endpoint   = "demo.wireguard.io:12913"; }
            ];
          };
        };
        type = with types; attrsOf (submodule interfaceOpts);
      };
    };
  };


  ###### implementation

  config = mkIf (cfg.interfaces != {}) {
    boot.extraModulePackages = optional (versionOlder kernel.kernel.version "5.6") kernel.wireguard;
    environment.systemPackages = [ pkgs.wireguard-tools ];
    # This is forced to false for now because the default "--validmark" rpfilter we apply on reverse path filtering
    # breaks the wg-quick routing because wireguard packets leave with a fwmark from wireguard.
    networking.firewall.checkReversePath = false;
    systemd.services = mapAttrs' generateUnit cfg.interfaces;
  };
}
