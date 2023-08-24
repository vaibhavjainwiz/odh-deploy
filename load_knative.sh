#!/bin/sh
arr=(configurations.serving.knative.dev domainmappings.serving.knative.dev revisions.serving.knative.dev routes.serving.knative.dev services.serving.knative.dev)
for i in "${arr[@]}"
do
  echo "starting cycle - "${i}
  oc get ${i}
done
