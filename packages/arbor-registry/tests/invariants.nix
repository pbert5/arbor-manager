{ registry, pkgs }:
let
  inherit (pkgs.lib) length elem;
  signer = registry.testSigner "root" "fixture-key";
  childSigner = registry.testSigner "child" "child-key";
  record =
    fields:
    registry.makeEnvelope signer (
      {
        protocolEpoch = 1;
        wireVersion = 1;
        schemaVersion = 1;
        recordVersion = 1;
        recordId =
          fields.schema
          + ":"
          + (if fields.payload ? id then fields.payload.id else fields.payload.relationshipId);
        generation = 1;
        issuer = "root";
        subject = if fields.payload ? id then fields.payload.id else fields.payload.relationshipId;
        createdAt = "2026-01-01T00:00:00Z";
        schema = fields.schema;
        payload = fields.payload;
      }
      // fields
    );
  identity =
    id:
    record {
      schema = "node-identity";
      payload = {
        inherit id;
        aliases = [ ];
      };
    };
  relationship =
    id: from: to: kind: status:
    record {
      schema = "relationship";
      payload = {
        relationshipId = id;
        inherit
          from
          to
          kind
          status
          ;
        scope = [ "observe" ];
        autonomy = "dependent";
      };
    };
  raw = [
    (identity "root-node")
    (identity "child-node")
    (relationship "r-parent" "root-node" "child-node" "parent" "active")
  ];
  checked = registry.reconcile {
    inherit raw;
    signers = {
      root = signer;
      child = childSigner;
    };
    authorizedIssuers = [ "root" ];
  };
  unauthorized = record {
    schema = "node-identity";
    payload = {
      id = "intruder";
    };
    issuer = "child";
  };
  unknown = registry.makeEnvelope signer {
    protocolEpoch = 1;
    wireVersion = 1;
    schemaVersion = 1;
    recordVersion = 1;
    recordId = "mystery";
    generation = 1;
    issuer = "root";
    subject = "mystery";
    createdAt = "2026-01-01T00:00:00Z";
    schema = "future-record";
    payload = {
      id = "mystery";
    };
  };
  cycle = [
    (relationship "a" "one" "two" "parent" "active")
    (relationship "b" "two" "one" "parent" "active")
  ];
  standby = registry.relationshipRecords [
    (relationship "standby" "root-node" "standby-node" "standby-parent" "active")
  ];
  suspended = registry.relationshipRecords [
    (relationship "suspended" "root-node" "child-node" "parent" "suspended")
  ];
  multipleParents = registry.relationshipRecords [
    (relationship "p1" "root-node" "child-node" "parent" "active")
    (relationship "p2" "standby-node" "child-node" "parent" "active")
  ];
  compatibility = registry.validateEnvelope {
    record = registry.makeEnvelope signer {
      protocolEpoch = 1;
      wireVersion = 1;
      schemaVersion = 1;
      recordVersion = 1;
      recordId = "compatibility";
      generation = 1;
      issuer = "root";
      subject = "root-node";
      createdAt = "2026-01-01T00:00:00Z";
      schema = "compatibility";
      requiredFeatures = [ "future-feature" ];
      payload = {
        protocolEpoch = 1;
      };
    };
    signers = {
      root = signer;
    };
  };
  capability = registry.validateCapabilities {
    relationships = registry.relationshipRecords checked.accepted;
    grants = [
      {
        subject = "root-node";
        authorityRoot = "root";
        capabilities = [ "observe" ];
      }
      {
        subject = "child-node";
        authorityRoot = "root";
        capabilities = [
          "observe"
          "admin"
        ];
      }
    ];
  };
  graph = registry.validateGraph { relationships = registry.relationshipRecords checked.accepted; };
  transport = registry.makeTransport [
    (identity "b")
    (identity "a")
  ];
in
assert checked.quarantined == [ ];
assert length checked.accepted == 3;
assert
  checked.materialized.identities == [
    {
      id = "root-node";
      aliases = [ ];
    }
    {
      id = "child-node";
      aliases = [ ];
    }
  ];
assert
  (registry.validateEnvelope {
    record = unauthorized;
    signers = {
      root = signer;
      child = childSigner;
    };
    authorizedIssuers = [ "root" ];
  }).quarantine.code == "unauthorized-issuer";
assert
  (registry.validateEnvelope {
    record = unknown;
    signers = {
      root = signer;
    };
  }).quarantine.code == "unknown-schema";
assert graph.valid;
assert elem "child-node" (
  registry.graphQuery {
    relationships = registry.relationshipRecords checked.accepted;
    from = "root-node";
    selector = "descendants";
  }
);
assert
  length (registry.validateGraph { relationships = registry.relationshipRecords cycle; }).cycles == 2;
assert
  registry.graphQuery {
    relationships = standby;
    from = "root-node";
    selector = "children";
  } == [ ];
assert
  suspended == [
    {
      relationshipId = "suspended";
      from = "root-node";
      to = "child-node";
      kind = "parent";
      status = "suspended";
      scope = [ "observe" ];
      autonomy = "dependent";
    }
  ];
assert length (registry.validateGraph { relationships = multipleParents; }).multipleParents == 1;
assert compatibility.quarantine.code == "unsupported-required-feature";
assert !capability.valid;
assert
  transport.fetch == [
    (identity "a")
    (identity "b")
  ];
pkgs.emptyFile
