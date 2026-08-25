{ lib, nodeSelection }:

let
  sortUnique = values: lib.unique (builtins.sort builtins.lessThan values);

  chunks =
    size: values:
    if values == [ ] then [ ] else [ (lib.take size values) ] ++ chunks size (lib.drop size values);

  jsonDigest = value: builtins.hashString "sha256" (builtins.toJSON value);

  riskFor =
    nodes: selected:
    let
      critical = builtins.filter (
        name: (nodes.${name}.criticalRoute or false) || (nodes.${name}.critical or false)
      ) selected;
      standby = builtins.filter (name: (nodes.${name}.state or "active") == "standby") selected;
      suspended = builtins.filter (name: (nodes.${name}.state or "active") == "suspended") selected;
    in
    (lib.optional (critical != [ ]) {
      kind = "critical-route";
      severity = "high";
      nodes = critical;
      message = "Selection includes nodes on a critical route.";
    })
    ++ (lib.optional (standby != [ ]) {
      kind = "standby";
      severity = "medium";
      nodes = standby;
      message = "Selection includes standby nodes.";
    })
    ++ (lib.optional (suspended != [ ]) {
      kind = "suspended";
      severity = "high";
      nodes = suspended;
      message = "Selection includes suspended nodes.";
    });

  backendRecommendation =
    nodes: selected: requested:
    if requested != null then
      {
        backend = requested;
        reason = "Explicit backend choice.";
      }
    else if selected == [ ] then
      {
        backend = "direct";
        reason = "Empty selection has no backend fan-out.";
      }
    else if builtins.all (name: (nodes.${name}.backend or null) == "colmena") selected then
      {
        backend = "colmena";
        reason = "Every selected node declares the Colmena interface.";
      }
    else
      {
        backend = "direct";
        reason = "Direct is the conservative default for mixed or unspecified interfaces.";
      };

  commandFor =
    backend: name:
    if backend == "colmena" then
      "colmena apply --on ${name}"
    else
      "nixos-rebuild switch --flake .#${name}";

in
{
  plan =
    {
      nodes,
      roots,
      selector ? "local",
      backend ? null,
      canary ? null,
      batchSize ? 1,
      allowStandby ? false,
      allowSuspended ? false,
    }:
    let
      selection = nodeSelection.select {
        inherit
          nodes
          roots
          selector
          allowStandby
          allowSuspended
          ;
      };
      selected = selection.selected;
      chosenCanary =
        if canary != null && builtins.elem canary selected then
          [ canary ]
        else if selected != [ ] then
          [ (builtins.head selected) ]
        else
          [ ];
      remaining = builtins.filter (name: !(builtins.elem name chosenCanary)) selected;
      batches = chunks (if batchSize > 0 then batchSize else 1) remaining;
      recommendation = backendRecommendation nodes selected backend;
      phases =
        (lib.optional (chosenCanary != [ ]) {
          name = "canary";
          names = chosenCanary;
          commands = map (commandFor recommendation.backend) chosenCanary;
        })
        ++ (lib.optional (batches != [ ]) {
          name = "batches";
          names = batches;
          commands = map (batch: map (commandFor recommendation.backend) batch) batches;
        });
      snapshot = {
        inherit roots selector selected;
        excluded = selection.excluded;
        nodes = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = nodes.${name};
          }) (sortUnique (selection.selectedByRelation ++ selected))
        );
      };
      snapshotDigest = jsonDigest snapshot;
      acknowledgement = {
        digest = jsonDigest {
          inherit snapshotDigest phases;
          backend = recommendation.backend;
        };
        names = lib.concatStringsSep "\n" selected;
        commands = lib.concatMap (phase: phase.commands) phases;
      };
    in
    {
      inherit
        selection
        snapshot
        snapshotDigest
        phases
        acknowledgement
        ;
      backend = recommendation;
      risks = riskFor nodes selected;
      names = selected;
      commands = acknowledgement.commands;
      inspect = {
        snapshotDigest = snapshotDigest;
        acknowledgementDigest = acknowledgement.digest;
        names = acknowledgement.names;
        commands = acknowledgement.commands;
      };
    };
}
