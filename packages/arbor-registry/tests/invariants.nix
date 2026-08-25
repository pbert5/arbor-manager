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
  selfCycle = [ (relationship "self" "one" "one" "parent" "active") ];
  oldIdentity = record {
    schema = "node-identity";
    generation = 1;
    payload = {
      id = "versioned";
      aliases = [ "old" ];
    };
  };
  newIdentity = record {
    schema = "node-identity";
    generation = 2;
    payload = {
      id = "versioned";
      aliases = [ "new" ];
    };
  };
  conflictA = record {
    schema = "node-identity";
    payload = {
      id = "conflict";
      aliases = [ "a" ];
    };
  };
  conflictB = record {
    schema = "node-identity";
    payload = {
      id = "conflict";
      aliases = [ "b" ];
    };
  };
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
  provider = registry.makeDummyProvider [
    (identity "b")
    (identity "a")
  ];
  projected = registry.reconcile {
    raw = [
      (record {
        schema = "endpoint";
        payload = {
          id = "endpoint-b";
          node = "b";
          protocol = "https";
        };
      })
      (record {
        schema = "service";
        payload = {
          id = "service-a";
          endpoint = "endpoint-b";
        };
      })
      (record {
        schema = "name";
        payload = {
          id = "b";
          name = "worker";
        };
      })
      (record {
        schema = "trusted-peer";
        payload = {
          id = "peer-a";
          node = "b";
        };
      })
      (record {
        schema = "reachability";
        payload = {
          id = "reach-a";
          subject = "endpoint-b";
          state = "reachable";
        };
      })
    ];
    signers.root = signer;
  };
  unsafe = record {
    schema = "service";
    payload = {
      id = "unsafe";
      accessToken = "must-not-enter-state";
    };
  };
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
  (registry.validateGraph { relationships = registry.relationshipRecords selfCycle; }).cycles
  == [ "one" ];
assert
  (registry.reconcile {
    raw = [
      oldIdentity
      newIdentity
    ];
    signers.root = signer;
  }).materialized.records == [ newIdentity ];
assert
  (registry.reconcile {
    raw = [
      conflictA
      conflictB
    ];
    signers.root = signer;
  }).quarantined == [
    (
      conflictA
      // {
        quarantine = {
          code = "conflicting-generation";
          detail = "multiple records share an id and generation";
        };
      }
    )
    (
      conflictB
      // {
        quarantine = {
          code = "conflicting-generation";
          detail = "multiple records share an id and generation";
        };
      }
    )
  ];
assert
  (registry.validateEnvelope {
    record = {
      schema = "endpoint";
    };
    signers = { };
  }).quarantine.code == "malformed-record";
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
assert provider.fetch { } == transport.fetch;
assert (provider.append (identity "c")).fetch { } == transport.fetch ++ [ (identity "c") ];
assert
  projected.materialized.endpoints == [
    {
      id = "endpoint-b";
      node = "b";
      protocol = "https";
    }
  ];
assert
  projected.materialized.names == [
    {
      id = "b";
      name = "worker";
    }
  ];
assert
  projected.materialized.services == [
    {
      id = "service-a";
      endpoint = "endpoint-b";
    }
  ];
assert
  projected.materialized.trustedPeers == [
    {
      id = "peer-a";
      node = "b";
    }
  ];
assert
  projected.materialized.reachability == [
    {
      id = "reach-a";
      state = "reachable";
      subject = "endpoint-b";
    }
  ];
assert
  (registry.validateEnvelope {
    record = registry.makeEnvelope signer unsafe;
    signers.root = signer;
  }).quarantine.code == "unsafe-value";
pkgs.emptyFile
