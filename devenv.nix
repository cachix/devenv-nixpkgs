{ pkgs, lib, config, inputs, ... }:

{
  languages.python = {
    enable = true;
    venv.enable= true;
    uv.enable = true;
    uv.sync.enable = true;
  };
}
