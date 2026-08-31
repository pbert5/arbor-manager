#!/usr/bin/env bash
set -euo pipefail
cli=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat >"$work/adapter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
op=$(jq -r .operation)
case "$op" in
  identity/inspect) jq -n '{nodeId:"node-a",initialized:false,privateKey:"secret"}' ;;
  identity/init-self) jq -n '{status:"accepted",nodeId:"node-a",localGenesis:true,privateKey:"secret"}' ;;
  registry/summary) jq -n '{records:{total:219,accepted:1,quarantined:218},localIdentity:{nodeId:"node-a",conflict:false},privateKey:"secret"}' ;;
esac
EOF
chmod 700 "$work/adapter"
"$cli" identity inspect --runtime-executable "$work/adapter" | jq -e '.nodeId == "node-a" and .privateKey == null' >/dev/null
"$cli" identity init-self --node-id node-a --domain example.invalid --runtime-executable "$work/adapter" | jq -e '.localGenesis == true and .privateKey == null' >/dev/null
"$cli" registry summary --node-id node-a --runtime-executable "$work/adapter" | jq -e '.records.total == 219 and .privateKey == null' >/dev/null
