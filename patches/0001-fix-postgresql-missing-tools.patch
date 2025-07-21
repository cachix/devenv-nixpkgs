From fd039474a4e9388f1599e8c7e41f5c0e72a1a06c Mon Sep 17 00:00:00 2001
From: Wolfgang Walther <walther@technowledgy.de>
Date: Sat, 19 Jul 2025 18:13:16 +0200
Subject: [PATCH] postgresql.pg_config: make overrideable

This allows `postgresql.withPackages` to easily override the paths to
the default and man outputs for `pg_config`. It avoids all
`buildEnv`-dev-output hackery, which it didn't properly support, and
separates the logic cleanly.
---
 pkgs/servers/sql/postgresql/generic.nix   | 143 +++++++++++-----------
 pkgs/servers/sql/postgresql/libpq.nix     |   6 +
 pkgs/servers/sql/postgresql/pg_config.nix |  11 +-
 pkgs/servers/sql/postgresql/pg_config.sh  |   2 +-
 4 files changed, 88 insertions(+), 74 deletions(-)

diff --git a/pkgs/servers/sql/postgresql/generic.nix b/pkgs/servers/sql/postgresql/generic.nix
index 3f8c4f893f2491..487a8d8a3d2375 100644
--- a/pkgs/servers/sql/postgresql/generic.nix
+++ b/pkgs/servers/sql/postgresql/generic.nix
@@ -459,6 +459,9 @@ let
         + ''
           rm "$out/bin/pg_config"
           make -C src/common pg_config.env
+          substituteInPlace src/common/pg_config.env \
+            --replace-fail "$out" "@out@" \
+            --replace-fail "$man" "@man@"
           install -D src/common/pg_config.env "$dev/nix-support/pg_config.env"
 
           # postgres exposes external symbols get_pkginclude_path and similar. Those
@@ -586,7 +589,13 @@ let
             postgresql = this;
           };
 
-          pg_config = buildPackages.callPackage ./pg_config.nix { inherit (finalAttrs) finalPackage; };
+          pg_config = buildPackages.callPackage ./pg_config.nix {
+            inherit (finalAttrs) finalPackage;
+            outputs = {
+              out = lib.getOutput "out" finalAttrs.finalPackage;
+              man = lib.getOutput "man" finalAttrs.finalPackage;
+            };
+          };
 
           tests =
             {
@@ -641,84 +650,76 @@ let
     f:
     let
       installedExtensions = f postgresql.pkgs;
-      finalPackage =
-        (buildEnv {
-          name = "${postgresql.pname}-and-plugins-${postgresql.version}";
-          paths = installedExtensions ++ [
-            # consider keeping in-sync with `postBuild` below
-            postgresql
-            postgresql.man # in case user installs this into environment
-          ];
-
-          pathsToLink = [
-            "/"
-            "/bin"
-            "/share/postgresql/extension"
-            # Unbreaks Omnigres' build system
-            "/share/postgresql/timezonesets"
-            "/share/postgresql/tsearch_data"
-          ];
-
-          nativeBuildInputs = [ makeBinaryWrapper ];
-          postBuild =
-            let
-              args = lib.concatMap (ext: ext.wrapperArgs or [ ]) installedExtensions;
-            in
-            ''
-              wrapProgram "$out/bin/postgres" ${lib.concatStringsSep " " args}
-
-              mkdir -p "$dev/nix-support"
-              substitute "${lib.getDev postgresql}/nix-support/pg_config.env" "$dev/nix-support/pg_config.env" \
-                --replace-fail "${postgresql}" "$out" \
-                --replace-fail "${postgresql.man}" "$out"
-            '';
-
-          passthru = {
-            inherit installedExtensions;
-            inherit (postgresql)
-              pkgs
-              psqlSchema
-              version
-              ;
+      finalPackage = buildEnv {
+        name = "${postgresql.pname}-and-plugins-${postgresql.version}";
+        paths = installedExtensions ++ [
+          # consider keeping in-sync with `postBuild` below
+          postgresql
+          postgresql.man # in case user installs this into environment
+        ];
 
-            pg_config = postgresql.pg_config.override { inherit finalPackage; };
+        pathsToLink = [
+          "/"
+          "/bin"
+          "/share/postgresql/extension"
+          # Unbreaks Omnigres' build system
+          "/share/postgresql/timezonesets"
+          "/share/postgresql/tsearch_data"
+        ];
 
-            withJIT = postgresqlWithPackages {
-              inherit
-                buildEnv
-                lib
-                makeBinaryWrapper
-                postgresql
-                ;
-            } (_: installedExtensions ++ [ postgresql.jit ]);
-            withoutJIT = postgresqlWithPackages {
+        nativeBuildInputs = [ makeBinaryWrapper ];
+        postBuild =
+          let
+            args = lib.concatMap (ext: ext.wrapperArgs or [ ]) installedExtensions;
+          in
+          ''
+            wrapProgram "$out/bin/postgres" ${lib.concatStringsSep " " args}
+          '';
+
+        passthru = {
+          inherit installedExtensions;
+          inherit (postgresql)
+            pkgs
+            psqlSchema
+            version
+            ;
+
+          pg_config = postgresql.pg_config.override {
+            outputs = {
+              out = finalPackage;
+              man = finalPackage;
+            };
+          };
+
+          withJIT = postgresqlWithPackages {
+            inherit
+              buildEnv
+              lib
+              makeBinaryWrapper
+              postgresql
+              ;
+          } (_: installedExtensions ++ [ postgresql.jit ]);
+          withoutJIT = postgresqlWithPackages {
+            inherit
+              buildEnv
+              lib
+              makeBinaryWrapper
+              postgresql
+              ;
+          } (_: lib.remove postgresql.jit installedExtensions);
+
+          withPackages =
+            f':
+            postgresqlWithPackages {
               inherit
                 buildEnv
                 lib
                 makeBinaryWrapper
                 postgresql
                 ;
-            } (_: lib.remove postgresql.jit installedExtensions);
-
-            withPackages =
-              f':
-              postgresqlWithPackages {
-                inherit
-                  buildEnv
-                  lib
-                  makeBinaryWrapper
-                  postgresql
-                  ;
-              } (ps: installedExtensions ++ f' ps);
-          };
-        }).overrideAttrs
-          {
-            # buildEnv doesn't support passing `outputs`, so going via overrideAttrs.
-            outputs = [
-              "out"
-              "dev"
-            ];
-          };
+            } (ps: installedExtensions ++ f' ps);
+        };
+      };
     in
     finalPackage;
 
diff --git a/pkgs/servers/sql/postgresql/libpq.nix b/pkgs/servers/sql/postgresql/libpq.nix
index 6af21fba86b752..e205c76a58fc43 100644
--- a/pkgs/servers/sql/postgresql/libpq.nix
+++ b/pkgs/servers/sql/postgresql/libpq.nix
@@ -129,6 +129,9 @@ stdenv.mkDerivation (finalAttrs: {
     make -C src/interfaces/libpq install
     make -C src/port install
 
+    substituteInPlace src/common/pg_config.env \
+      --replace-fail "$out" "@out@"
+
     install -D src/common/pg_config.env "$dev/nix-support/pg_config.env"
     moveToOutput "lib/*.a" "$dev"
 
@@ -152,6 +155,9 @@ stdenv.mkDerivation (finalAttrs: {
 
   passthru.pg_config = buildPackages.callPackage ./pg_config.nix {
     inherit (finalAttrs) finalPackage;
+    outputs = {
+      out = lib.getOutput "out" finalAttrs.finalPackage;
+    };
   };
 
   meta = {
diff --git a/pkgs/servers/sql/postgresql/pg_config.nix b/pkgs/servers/sql/postgresql/pg_config.nix
index 20544cdb06141d..c4cc1cee06cd07 100644
--- a/pkgs/servers/sql/postgresql/pg_config.nix
+++ b/pkgs/servers/sql/postgresql/pg_config.nix
@@ -6,6 +6,8 @@
   stdenv,
   # PostgreSQL package
   finalPackage,
+  # PostgreSQL package's outputs
+  outputs,
 }:
 
 replaceVarsWith {
@@ -15,12 +17,17 @@ replaceVarsWith {
   isExecutable = true;
   replacements = {
     inherit runtimeShell;
-    postgresql-dev = lib.getDev finalPackage;
+    "pg_config.env" = replaceVarsWith {
+      name = "pg_config.env";
+      src = "${lib.getDev finalPackage}/nix-support/pg_config.env";
+      replacements = outputs;
+    };
   };
   nativeCheckInputs = [
     diffutils
   ];
-  postCheck = ''
+  # The expected output only matches when outputs have *not* been altered by postgresql.withPackages.
+  postCheck = lib.optionalString (outputs.out == lib.getOutput "out" finalPackage) ''
     if [ -e ${lib.getDev finalPackage}/nix-support/pg_config.expected ]; then
         diff ${lib.getDev finalPackage}/nix-support/pg_config.expected <($out/bin/pg_config)
     fi
diff --git a/pkgs/servers/sql/postgresql/pg_config.sh b/pkgs/servers/sql/postgresql/pg_config.sh
index 3f0aa08eb70cc8..ff18e3a4752bfb 100644
--- a/pkgs/servers/sql/postgresql/pg_config.sh
+++ b/pkgs/servers/sql/postgresql/pg_config.sh
@@ -13,7 +13,7 @@ set -euo pipefail
 #   https://github.com/postgres/postgres/blob/7510ac6203bc8e3c56eae95466feaeebfc1b4f31/src/bin/pg_config/pg_config.sh
 #   https://github.com/postgres/postgres/blob/master/src/bin/pg_config/pg_config.c
 
-source @postgresql-dev@/nix-support/pg_config.env
+source @pg_config.env@
 
 help="
 pg_config provides information about the installed version of PostgreSQL.
