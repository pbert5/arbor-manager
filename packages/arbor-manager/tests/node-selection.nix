{ lib }:

let
  manager = import ../lib { inherit lib; };
  nodes = {
    api = {
      children = [ "worker" ];
      criticalRoute = true;
    };
    worker = {
      parents = [ "api" ];
      children = [ "db" ];
    };
    db = {
      parents = [ "worker" ];
      reachable = false;
    };
    standby = {
      parents = [ "api" ];
      state = "standby";
    };
    suspended = {
      parents = [ "api" ];
      state = "suspended";
    };
    isolated = {
      compatible = false;
    };
    cycle-a = {
      children = [ "cycle-b" ];
    };
    cycle-b = {
      children = [ "cycle-a" ];
    };
  };
  g = manager.graph nodes;
  plan = manager.plan {
    inherit nodes;
    roots = [ "api" ];
    selector = "accessible";
    batchSize = 1;
  };
in
assert manager.selectors.local g [ "api" ] == [ "api" ];
assert
  manager.selectors.children g [ "api" ] == [
    "standby"
    "suspended"
    "worker"
  ];
assert
  manager.selectors.descendants g [ "api" ] == [
    "db"
    "standby"
    "suspended"
    "worker"
  ];
assert manager.selectors.parents g [ "db" ] == [ "worker" ];
assert
  manager.selectors.ancestors g [ "db" ] == [
    "api"
    "worker"
  ];
assert
  manager.selectors.accessible g [ "cycle-a" ] == [
    "cycle-a"
    "cycle-b"
  ];
assert
  (manager.select {
    inherit nodes;
    roots = [ "api" ];
    selector = "descendants";
  }).selected == [ "worker" ];
assert
  (builtins.head (builtins.filter (entry: entry.name == "db") plan.selection.excluded)).reasons
  == [ "unreachable" ];
assert
  (builtins.head (builtins.filter (entry: entry.name == "standby") plan.selection.excluded)).reasons
  == [ "standby-not-allowed" ];
assert
  (builtins.head (builtins.filter (entry: entry.name == "suspended") plan.selection.excluded)).reasons
  == [ "suspended-not-allowed" ];
assert
  plan.names == [
    "api"
    "worker"
  ];
assert plan.backend.backend == "direct";
assert (builtins.filter (risk: risk.kind == "critical-route") plan.risks) != [ ];
assert
  plan.phases == [
    {
      name = "canary";
      names = [ "api" ];
      commands = [ "nixos-rebuild switch --flake .#api" ];
    }
    {
      name = "batches";
      names = [ [ "worker" ] ];
      commands = [ [ "nixos-rebuild switch --flake .#worker" ] ];
    }
  ];
assert
  plan.snapshotDigest == (manager.plan {
    inherit nodes;
    roots = [ "api" ];
    selector = "accessible";
    batchSize = 1;
  }).snapshotDigest;
assert plan.acknowledgement.digest != "";
assert builtins.match ".*api.*" plan.inspect.names != null;
assert builtins.match ".*worker.*" (builtins.head plan.inspect.commands) == null;
true
