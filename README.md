### Install OpenDataHub operator
```
oc create -f odh-operator-subscription.yaml
oc new-project model-serving
oc create -f kfdef-odh-modelmesh.yaml
```

### Deploy Minio
```
oc new-project minio
oc create -f minio.yaml
```

### Deploy Model
```
export test_mm_ns=opendatahub-mm
oc new-project ${test_mm_ns} --skip-config-write=true
oc label namespace ${test_mm_ns} modelmesh-enabled=true --overwrite=true
oc create -f minio-secret.yaml -n ${test_mm_ns}
oc apply -f openvino-serving-runtime.yaml -n ${test_mm_ns}
oc apply -f openvino-inference-service.yaml -n ${test_mm_ns}
```

#### Curl Test
```
export HOST_URL=$(oc get route example-onnx-mnist -ojsonpath='{.spec.host}' -n ${test_mm_ns})
export HOST_PATH=$(oc get route example-onnx-mnist  -ojsonpath='{.spec.path}' -n ${test_mm_ns})

curl   --silent --location --fail --show-error --insecure https://${HOST_URL}${HOST_PATH}/infer -d  @input-onnx.json
```