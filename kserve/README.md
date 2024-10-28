### Install ServiceMesh operator
```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  name: servicemeshoperator
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

#### Install Jaeger Operator
```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

### Create an Istio instance.
```
oc create ns istio-system
oc apply -f ./smcp.yaml
sleep 30
oc wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s
oc wait --for=condition=ready pod -l app=istio-ingressgateway -n istio-system --timeout=300s
oc wait --for=condition=ready pod -l app=istio-egressgateway -n istio-system --timeout=300s
oc wait --for=condition=ready pod -l app=jaeger -n istio-system --timeout=300s
```

### Install Serverless Operator
```
oc apply -f serverless-operators.yaml
sleep 30
oc wait --for=condition=ready pod -l name=knative-openshift -n openshift-serverless --timeout=300s
oc wait --for=condition=ready pod -l name=knative-openshift-ingress -n openshift-serverless --timeout=300s
oc wait --for=condition=ready pod -l name=knative-operator -n openshift-serverless --timeout=300s
```

### Install Knative Serving
```
oc create ns knative-serving
oc create ns opendatahub
```

#### Setup Peer Authentication
```
oc apply -f peer-authentication.yaml
oc apply -f smmr.yaml
```

### Create a KnativeServing Instance.
```
oc apply -f knativeserving-istio.yaml
sleep 15
oc wait --for=condition=ready pod -l app=controller -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=net-istio-controller -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=net-istio-webhook -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=autoscaler-hpa -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=domain-mapping -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=webhook -n knative-serving --timeout=300s
oc delete pod -n knative-serving -l app=activator --force --grace-period=0
oc delete pod -n knative-serving -l app=autoscaler --force --grace-period=0
oc wait --for=condition=ready pod -l app=activator -n knative-serving --timeout=300s
oc wait --for=condition=ready pod -l app=autoscaler -n knative-serving --timeout=300s
```

### Generate a wildcard certification for a gateway using OpenSSL.
```
export BASE_DIR=/tmp/kserve
export BASE_CERT_DIR=${BASE_DIR}/certs
export DOMAIN_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | awk -F'.' '{print $(NF-1)"."$NF}')
export COMMON_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'|sed 's/apps.//')

mkdir ${BASE_DIR}
mkdir ${BASE_CERT_DIR}

./generate-wildcard-certs.sh ${BASE_CERT_DIR} ${DOMAIN_NAME} ${COMMON_NAME}
```

### Create the Knative gateway.
```
oc create secret tls wildcard-certs --cert=${BASE_CERT_DIR}/wildcard.crt --key=${BASE_CERT_DIR}/wildcard.key -n istio-system
oc apply -f gateways.yaml
```

### Install OpenDataHub operator
```
oc create -f odh-operator-subscription.yaml
oc new-project kserve-demo
oc create -f dataScienceCluster.yaml
```

### Deploy Minio
```
oc new-project minio
oc create -f minio.yaml
```

### Deploy Model
```
export test_mm_ns=kserve-demo
oc new-project ${test_mm_ns} --skip-config-write=true
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