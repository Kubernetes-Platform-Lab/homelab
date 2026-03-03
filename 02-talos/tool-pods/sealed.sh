echo -n TOKEN | kubectl create secret generic test --dry-run=client --from-file=KEY=/dev/stdin -o json | kubeseal --controller-name sealed-secrets --scope cluster-wide > mysealedsecret.json

