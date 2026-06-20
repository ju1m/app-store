{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontConfigure = !config.enable;
    };
  };
}
