{ lib }:

let
  sortUnique = values: lib.unique (builtins.sort builtins.lessThan values);

  namesOf = nodes: builtins.attrNames nodes;

  members = value: if builtins.isList value then value else [ ];

  declaredChildren = nodes: name: members (nodes.${name}.children or [ ]);

  declaredParents = nodes: name: members (nodes.${name}.parents or [ ]);

  validNames = nodes: values: builtins.filter (name: builtins.hasAttr name nodes) values;

  graph =
    nodes:
    let
      names = namesOf nodes;
      directChildren = name: validNames nodes (declaredChildren nodes name);
      directParents = name: validNames nodes (declaredParents nodes name);
      children =
        name:
        sortUnique (
          directChildren name
          ++ builtins.filter (candidate: builtins.elem name (directParents candidate)) names
        );
      parents =
        name:
        sortUnique (
          directParents name
          ++ builtins.filter (candidate: builtins.elem name (directChildren candidate)) names
        );
    in
    {
      inherit names children parents;
      roots = values: validNames nodes (sortUnique values);
    };

  walk =
    step: roots:
    let
      go =
        frontier: seen:
        if frontier == [ ] then
          seen
        else
          let
            next = sortUnique (lib.concatMap step frontier);
            fresh = builtins.filter (name: !(builtins.elem name seen)) next;
          in
          go fresh (sortUnique (seen ++ fresh));
    in
    go (sortUnique roots) [ ];

  relation =
    graphValue: roots: kind:
    let
      rootNames = graphValue.roots roots;
      result =
        if kind == "local" then
          rootNames
        else if kind == "children" then
          sortUnique (lib.concatMap graphValue.children rootNames)
        else if kind == "descendants" then
          sortUnique (
            builtins.filter (name: !(builtins.elem name rootNames)) (walk graphValue.children rootNames)
          )
        else if kind == "parents" then
          sortUnique (lib.concatMap graphValue.parents rootNames)
        else if kind == "ancestors" then
          sortUnique (
            builtins.filter (name: !(builtins.elem name rootNames)) (walk graphValue.parents rootNames)
          )
        else if kind == "peers" then
          sortUnique (
            builtins.filter (name: !(builtins.elem name rootNames)) (
              lib.concatMap (
                root:
                lib.concatMap graphValue.children (graphValue.parents root)
                ++ lib.concatMap graphValue.parents (graphValue.children root)
              ) rootNames
            )
          )
        else if kind == "accessible" then
          sortUnique (walk (name: graphValue.children name ++ graphValue.parents name) rootNames)
        else
          throw "Arbor Manager: unknown node selector '${kind}'.";
    in
    result;

  stateReasons =
    node: options:
    let
      state = node.state or "active";
      allowStandby = options.allowStandby or false;
      allowSuspended = options.allowSuspended or false;
    in
    (lib.optional (!(node.enabled or true)) "disabled")
    ++ (lib.optional ((node.reachable or true) == false) "unreachable")
    ++ (lib.optional ((node.compatible or true) == false) "incompatible")
    ++ (lib.optional (state == "standby" && !allowStandby) "standby-not-allowed")
    ++ (lib.optional (state == "suspended" && !allowSuspended) "suspended-not-allowed");

in
{
  inherit graph;

  selectors = {
    local = graphValue: roots: relation graphValue roots "local";
    children = graphValue: roots: relation graphValue roots "children";
    descendants = graphValue: roots: relation graphValue roots "descendants";
    parents = graphValue: roots: relation graphValue roots "parents";
    ancestors = graphValue: roots: relation graphValue roots "ancestors";
    peers = graphValue: roots: relation graphValue roots "peers";
    accessible = graphValue: roots: relation graphValue roots "accessible";
  };

  select =
    {
      nodes,
      roots,
      selector ? "local",
      allowStandby ? false,
      allowSuspended ? false,
    }:
    let
      graphValue = graph nodes;
      selectedByRelation = relation graphValue roots selector;
      options = { inherit allowStandby allowSuspended; };
      excluded =
        builtins.map
          (name: {
            inherit name;
            reasons =
              (lib.optional (!(builtins.elem name selectedByRelation)) "outside-selector")
              ++ stateReasons nodes.${name} options;
          })
          (
            builtins.filter (
              name: !(builtins.elem name selectedByRelation) || stateReasons nodes.${name} options != [ ]
            ) graphValue.names
          );
      selected = builtins.filter (name: stateReasons nodes.${name} options == [ ]) selectedByRelation;
    in
    {
      inherit
        graphValue
        selectedByRelation
        selected
        excluded
        ;
      selector = selector;
      roots = graphValue.roots roots;
    };
}
