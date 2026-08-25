{ lib }:
let
  inherit (builtins)
    attrNames
    concatLists
    elem
    filter
    foldl'
    hasAttr
    head
    length
    map
    match
    stringLength
    toJSON
    typeOf
    tryEval
    ;
  optional = condition: value: if condition then [ value ] else [ ];
  unique = values: foldl' (out: value: if elem value out then out else out ++ [ value ]) [ ] values;
  findFirst =
    predicate: fallback: values:
    let
      hits = filter predicate values;
    in
    if hits == [ ] then fallback else head hits;
  get =
    name: fallback: attrs:
    if hasAttr name attrs then attrs.${name} else fallback;

  familyNames = [
    "node-identity"
    "identity-generation"
    "relationship"
    "capability"
    "machine-facts"
    "hardware-snapshot"
    "configuration-intent"
    "endpoint"
    "service"
    "compatibility"
    "recovery-authorization"
    "revocation"
    "receipt"
  ];
  familySchemas = lib.genAttrs familyNames (_: 1);

  unsigned = envelope: removeAttrs envelope [ "signature" ];
  canonical = value: toJSON value;
  recordKey = record: "${record.recordId}:${toString record.recordVersion}";
  issuerOf = record: get "issuer" null record;

  signerFor =
    signers: issuer: if issuer != null && signers ? ${issuer} then signers.${issuer} else null;

  makeEnvelope =
    signer: fields:
    let
      base = fields // {
        protocolEpoch = get "protocolEpoch" 1 fields;
        wireVersion = get "wireVersion" 1 fields;
        schemaVersion = get "schemaVersion" 1 fields;
        recordVersion = get "recordVersion" 1 fields;
        generation = get "generation" 0 fields;
        predecessor = get "predecessor" null fields;
        requiredFeatures = get "requiredFeatures" [ ] fields;
        optionalFeatures = get "optionalFeatures" [ ] fields;
        expiresAt = get "expiresAt" null fields;
      };
    in
    base // { signature = signer.sign (canonical (unsigned base)); };

  reason = code: detail: { inherit code detail; };

  validateEnvelope =
    {
      supportedEpoch ? 1,
      supportedWireVersions ? [ 1 ],
      supportedSchemas ? familySchemas,
      supportedFeatures ? [ ],
      signers ? { },
      authorizedIssuers ? null,
      maxBytes ? 131072,
      record,
    }:
    let
      framing = tryEval (stringLength (canonical record));
      issuer = issuerOf record;
      signer = signerFor signers issuer;
      knownFamily = typeOf record == "set" && record ? schema && hasAttr record.schema supportedSchemas;
      epochOK = get "protocolEpoch" null record == supportedEpoch;
      wireOK = elem (get "wireVersion" null record) supportedWireVersions;
      required = get "requiredFeatures" [ ] record;
      featuresOK = lib.all (feature: elem feature supportedFeatures) required;
      authorityOK = authorizedIssuers == null || (issuer != null && elem issuer authorizedIssuers);
      signatureOK =
        signer != null && signer.verify (canonical (unsigned record)) (get "signature" null record);
      basic =
        framing.success && framing.value <= maxBytes && knownFamily && epochOK && wireOK && featuresOK;
      accepted = basic && authorityOK && signatureOK;
      quarantineCode =
        if !framing.success || framing.value > maxBytes then
          "framing-limit"
        else if !knownFamily then
          "unknown-schema"
        else if !epochOK then
          "unknown-epoch"
        else if !wireOK then
          "unsupported-wire-version"
        else if !featuresOK then
          "unsupported-required-feature"
        else if !authorityOK then
          "unauthorized-issuer"
        else if !signatureOK then
          "invalid-signature"
        else
          null;
    in
    {
      inherit record accepted;
      status = if accepted then "accepted" else "quarantined";
      quarantine = if accepted then null else reason quarantineCode "record failed envelope validation";
      canonical = if framing.success then canonical (unsigned record) else null;
    };

  validateHistory =
    records:
    let
      byId = foldl' (
        out: record: out // { "${record.recordId}" = (out.${record.recordId} or [ ]) ++ [ record ]; }
      ) { } records;
      checkOne =
        record:
        let
          peers = byId.${record.recordId};
          generations = map (x: x.generation) peers;
          maxGeneration = lib.foldl' lib.max 0 generations;
          predecessorOK = record.predecessor == null || elem record.predecessor (map (x: x.recordId) records);
          current = record.generation == maxGeneration;
        in
        if !predecessorOK then
          {
            inherit record;
            accepted = false;
            quarantine = reason "missing-predecessor" "predecessor is not accepted";
          }
        else if !current then
          {
            inherit record;
            accepted = false;
            quarantine = reason "anti-rollback" "an equal record id has a newer generation";
          }
        else
          {
            inherit record;
            accepted = true;
            quarantine = null;
          };
    in
    map checkOne records;

  materialize =
    accepted:
    let
      byFamily = family: filter (record: record.schema == family) accepted;
      identities = map (record: record.payload) (byFamily "node-identity");
      relationships = map (record: record.payload) (byFamily "relationship");
      latest =
        records:
        map (id: unique (map (x: x.recordId) records)) (
          id:
          findFirst (
            x:
            x.recordId == id
            &&
              x.generation == lib.foldl' lib.max 0 (map (y: y.generation) (filter (y: y.recordId == id) records))
          ) null records
        );
    in
    {
      inherit identities relationships;
      records = latest accepted;
      provenance = map (record: {
        recordId = record.recordId;
        issuer = record.issuer;
      }) accepted;
    };

  reconcile =
    {
      raw,
      supportedEpoch ? 1,
      supportedWireVersions ? [ 1 ],
      supportedSchemas ? familySchemas,
      supportedFeatures ? [ ],
      signers ? { },
      authorizedIssuers ? null,
    }:
    let
      envelopeResults = map (
        record:
        validateEnvelope {
          inherit
            supportedEpoch
            supportedWireVersions
            supportedSchemas
            supportedFeatures
            signers
            authorizedIssuers
            record
            ;
        }
      ) raw;
      envelopeAccepted = map (result: result.record) (filter (result: result.accepted) envelopeResults);
      historyResults = validateHistory envelopeAccepted;
      accepted = map (result: result.record) (filter (result: result.accepted) historyResults);
      rejectedHistory = filter (result: !result.accepted) historyResults;
      quarantined =
        (map (result: result.record // { quarantine = result.quarantine; }) (
          filter (result: !result.accepted) envelopeResults
        ))
        ++ (map (result: result.record // { quarantine = result.quarantine; }) rejectedHistory);
    in
    {
      inherit raw accepted quarantined;
      materialized = materialize accepted;
    };

  relationshipRecords =
    records: map (record: record.payload) (filter (record: record.schema == "relationship") records);
  edgeActive = edge: get "status" "active" edge == "active";
  edgeKind = edge: get "kind" null edge;
  edgesBetween =
    {
      relationships,
      from ? null,
      to ? null,
    }:
    filter (edge: (from == null || edge.from == from) && (to == null || edge.to == to)) relationships;
  parentEdges =
    relationships: filter (edge: edgeActive edge && edgeKind edge == "parent") relationships;
  parentGraph =
    relationships:
    foldl' (out: edge: out // { "${edge.from}" = (out.${edge.from} or [ ]) ++ [ edge.to ]; }) { } (
      parentEdges relationships
    );
  reachable =
    graph: starts:
    let
      go =
        seen: queue:
        if queue == [ ] then
          seen
        else
          let
            node = head queue;
            next = get node [ ] graph;
            fresh = filter (x: !elem x seen) next;
          in
          go (unique (seen ++ [ node ])) ((builtins.tail queue) ++ fresh);
    in
    builtins.tail (go [ ] starts);
  hasParentCycle =
    relationships:
    let
      graph = parentGraph relationships;
      reaches =
        from: _to:
        elem from (concatLists (map (neighbor: reachable graph [ neighbor ]) (get from [ ] graph)));
      nodes = unique (
        concatLists (
          map (edge: [
            edge.from
            edge.to
          ]) (parentEdges relationships)
        )
      );
    in
    filter (node: reaches node node) nodes;
  graphQuery =
    {
      relationships,
      from,
      selector,
    }:
    let
      graph = parentGraph relationships;
      parent = reachable graph [ from ];
      reverse = foldl' (
        out: edge: out // { "${edge.to}" = (out.${edge.to} or [ ]) ++ [ edge.from ]; }
      ) { } (parentEdges relationships);
      peer = unique (
        concatLists (
          map (
            edge:
            optional (edgeActive edge && edgeKind edge == "peer" && (edge.from == from || edge.to == from)) (
              if edge.from == from then edge.to else edge.from
            )
          ) relationships
        )
      );
    in
    if selector == "local" then
      [ from ]
    else if selector == "children" then
      get from [ ] graph
    else if selector == "descendants" then
      parent
    else if selector == "parents" then
      get from [ ] reverse
    else if selector == "ancestors" then
      reachable reverse [ from ]
    else if selector == "peers" then
      peer
    else if selector == "accessible" then
      unique ([ from ] ++ parent ++ peer)
    else
      throw "unknown graph selector";

  validateGraph =
    { relationships }:
    let
      cycles = hasParentCycle relationships;
      incoming = foldl' (
        out: edge: out // { "${edge.to}" = (out.${edge.to} or [ ]) ++ [ edge.from ]; }
      ) { } (parentEdges relationships);
      multipleParents = filter (node: length (get node [ ] incoming) > 1) (attrNames incoming);
    in
    {
      inherit cycles multipleParents;
      valid = cycles == [ ];
    };

  validateCapabilities =
    { relationships, grants }:
    let
      activeParents = parentEdges relationships;
      parentOf = node: map (edge: edge.from) (filter (edge: edge.to == node) activeParents);
      rootOf = grant: get "authorityRoot" (get "issuer" null grant) grant;
      capabilitiesOf = grant: get "capabilities" [ ] grant;
      violations = filter (
        grant:
        let
          inherited = unique (
            concatLists (
              map capabilitiesOf (
                filter (other: elem other.subject (parentOf grant.subject) && rootOf other == rootOf grant) grants
              )
            )
          );
        in
        !(lib.all (capability: elem capability inherited) (capabilitiesOf grant))
      ) grants;
    in
    {
      inherit violations;
      valid = violations == [ ];
    };

  makeTransport =
    records:
    let
      ordered = lib.sortOn (
        record: "${record.createdAt}:${record.recordId}:${toString record.recordVersion}"
      ) records;
    in
    {
      append = record: makeTransport (ordered ++ [ record ]);
      fetch = ordered;
      snapshot = ordered;
    };
in
{
  inherit
    familyNames
    familySchemas
    canonical
    unsigned
    makeEnvelope
    validateEnvelope
    reconcile
    materialize
    makeTransport
    relationshipRecords
    graphQuery
    validateGraph
    validateCapabilities
    parentGraph
    hasParentCycle
    ;
  testSigner = issuer: token: {
    inherit issuer;
    sign = bytes: "${token}:${bytes}";
    verify = bytes: signature: signature == "${token}:${bytes}";
  };
}
