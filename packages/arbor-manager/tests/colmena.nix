{ lib }:

let
  manager = import ../lib { inherit lib; };
  machines = {
    api = {
      machine = {
        targetHost = "api.example";
        targetPort = 2222;
        targetUser = "deploy";
        tags = [
          "web"
          "blue"
        ];
      };
      modules = [ ];
    };
    worker = {
      machine = {
        target = {
          targetHost = "worker.example";
          targetUser = "worker";
        };
        tags = [ "jobs" ];
      };
      modules = [ ];
    };
  };
  plan = manager.plan {
    nodes = {
      api = { };
      worker = { };
      excluded = {
        reachable = false;
      };
    };
    roots = [ "api" ];
    selector = "local";
    backend = "colmena";
  };
  hive = manager.rawHive { inherit machines plan; };
  directPlan = manager.plan {
    nodes = {
      api = { };
    };
    roots = [ "api" ];
    backend = "direct";
  };
in
assert plan.names == [ "api" ];
assert !(builtins.hasAttr "worker" hive);
assert !(builtins.hasAttr "excluded" hive);
assert
  hive.api.deployment == {
    targetHost = "api.example";
    targetPort = 2222;
    targetUser = "deploy";
  };
assert
  hive.api.tags == [
    "web"
    "blue"
  ];
assert hive.meta == { };
assert directPlan.backend.backend == "direct";
assert plan.backend.backend == "colmena";
true
