{ inputs, ... }: {
  perSystem = { system, ... }: {
    packages.concord = inputs.concord.packages.${system}.default;
  };
}
