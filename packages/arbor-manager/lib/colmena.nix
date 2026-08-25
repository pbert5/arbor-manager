{ lib }:

let
  targetFields = [
    "targetHost"
    "targetPort"
    "targetUser"
  ];

  targetValue =
    record: field:
    if builtins.hasAttr field record then
      record.${field}
    else if builtins.hasAttr "target" record && builtins.hasAttr field record.target then
      record.target.${field}
    else
      null;

  node =
    machines: name:
    let
      machine = machines.${name};
      record = machine.machine;
      deployment = lib.filterAttrs (_: value: value != null) (
        lib.genAttrs targetFields (field: targetValue record field)
      );
    in
    {
      imports = machine.modules;
      inherit deployment;
      tags = record.tags or [ ];
    };
in
{
  rawHive =
    {
      machines,
      plan,
      meta ? { },
    }:
    let
      selected = plan.names;
      missing = builtins.filter (name: !(builtins.hasAttr name machines)) selected;
    in
    assert lib.assertMsg (
      missing == [ ]
    ) "Arbor Manager: Colmena plan selected unknown machine(s): ${lib.concatStringsSep ", " missing}.";
    {
      inherit meta;
    }
    // builtins.listToAttrs (
      map (name: {
        inherit name;
        value = node machines name;
      }) selected
    );

  selection = plan: plan.names;
}
