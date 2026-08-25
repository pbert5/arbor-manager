{ lib }:

let
  sortUnique = values: lib.unique (builtins.sort builtins.lessThan values);

  namesOf = nodes: builtins.attrNames nodes;

  relationField =
    nodes: name: field:
    let
      value = nodes.${name}.${field} or [ ];
    in
    if !(builtins.isList value) then
      throw "Arbor Manager: node '${name}' field '${field}' must be a list of node names."
    else if !(builtins.all builtins.isString value) then
      throw "Arbor Manager: node '${name}' field '${field}' must contain only strings."
    else if !(builtins.all (target: builtins.hasAttr target nodes) value) then
      let
        unknown = builtins.filter (target: !(builtins.hasAttr target nodes)) value;
      in
      throw "Arbor Manager: node '${name}' field '${field}' references unknown node(s): ${lib.concatStringsSep ", " unknown}."
    else
      value;

  declaredChildren = nodes: name: relationField nodes name "children";

  declaredParents = nodes: name: relationField nodes name "parents";

  validNames = nodes: values: builtins.filter (name: builtins.hasAttr name nodes) values;

  graph =
    nodes:
    let
      names = namesOf nodes;
      validated = builtins.map (name: {
        inherit name;
        children = declaredChildren nodes name;
        parents = declaredParents nodes name;
        state =
          let
            state = nodes.${name}.state or "active";
          in
          if
            builtins.elem state [
              "active"
              "standby"
              "suspended"
            ]
          then
            state
          else
            throw "Arbor Manager: node '${name}' has invalid state '${toString state}'.";
      }) names;
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
    builtins.deepSeq validated {
      inherit names children parents;
      roots =
        values:
        if !(builtins.isList values) then
          throw "Arbor Manager: roots must be a list of node names."
        else if !(builtins.all builtins.isString values) then
          throw "Arbor Manager: roots must contain only strings."
        else if !(builtins.all (name: builtins.hasAttr name nodes) values) then
          let
            unknown = builtins.filter (name: !(builtins.hasAttr name nodes)) values;
          in
          throw "Arbor Manager: roots reference unknown node(s): ${lib.concatStringsSep ", " unknown}."
        else
          sortUnique values;
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
      ordered =
        let
          candidates = builtins.filter (name: stateReasons nodes.${name} options == [ ]) selectedByRelation;
          parentsInSelection =
            name: builtins.filter (parent: builtins.elem parent candidates) (graphValue.parents name);
          go =
            remaining: done:
            let
              ready = sortUnique (
                builtins.filter (
                  name:
                  !(builtins.elem name done)
                  && builtins.all (parent: builtins.elem parent done) (parentsInSelection name)
                ) remaining
              );
            in
            if ready == [ ] then { inherit done remaining; } else go remaining (done ++ ready);
          result = go candidates [ ];
        in
        {
          selected = result.done;
          blocked = result.remaining;
        };
      selected = ordered.selected;
      excluded =
        builtins.map
          (name: {
            inherit name;
            reasons =
              (lib.optional (!(builtins.elem name selectedByRelation)) "outside-selector")
              ++ (lib.optional (builtins.elem name ordered.blocked) "cycle-blocked")
              ++ stateReasons nodes.${name} options;
          })
          (
            builtins.filter (
              name:
              !(builtins.elem name selectedByRelation)
              || builtins.elem name ordered.blocked
              || stateReasons nodes.${name} options != [ ]
            ) graphValue.names
          );
    in
    {
      inherit
        graphValue
        selectedByRelation
        selected
        excluded
        ;
      blocked = ordered.blocked;
      selector = selector;
      roots = graphValue.roots roots;
    };
}
