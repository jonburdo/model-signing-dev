# model-signing-dev

## model signing

You can test: https://github.com/kubeflow/model-registry/pull/2168

With the [`./run`](./run) script which uses [`./model-sign`](./model-sign) to test `model_registry.signing.model_signer`

Check out the branch and do something like:
```
uv pip install -e ~/src/model-registry/clients/python
```

See [testing/](./testing) for TAS setup.

With `oc` logged in, modify setup-env.sh and simply:
```
./run
```

## token utils

`tokens/get-token-from-pod.sh`
Attempts to retrieve a token from a pod from the token file: /var/run/secrets/kubernetes.io/serviceaccount/token

`tokens/decode-token.sh`
Decodes a token value into json objects:
```
$ ./tokens/decode-token.sh /tmp/tmp.G9lh5Zd5QU
=== JWT Header ===
{
  "alg": "RS256",
  "kid": "Kx3mPqR5nY9-Lw7tHaBfGvUcJdEiNxZsWoMpAjK8Vqr"
}

=== JWT Payload ===
{
  "aud": [
    "https://tk-xmdc.s3.us-west-2.amazonaws.com/5k8f2h9p1x4n6v3c7m2q9t8r5w1y4z7b"
  ],
  "exp": 1801684868,
  "iat": 1770148868,
  "iss": "https://tk-xmdc.s3.us-west-2.amazonaws.com/5k8f2h9p1x4n6v3c7m2q9t8r5w1y4z7b",
  "jti": "a7f5c2b9-8d3e-4a1f-b6c9-3e8d7f2a5c1b",
  "kubernetes.io": {
    "namespace": "demo-ns",
    "node": {
      "name": "ip-172-31-45-123.ec2.internal",
      "uid": "f3d8e7c2-4b9a-4f1e-8c3d-5a9b7e2f1c4d"
    },
    "pod": {
      "name": "app-0",
      "uid": "c9b8a7f6-5e4d-4c3b-9a2e-1f8d7c6b5a4e"
    },
    "serviceaccount": {
      "name": "app",
      "uid": "e5d4c3b2-9a8f-4e7d-b6c5-a4f3e2d1c9b8"
    },
    "warnafter": 1770152475
  },
  "nbf": 1770148868,
  "sub": "system:serviceaccount:demo-ns:app"
}
```
