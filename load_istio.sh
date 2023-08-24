#!/bin/sh
arr=(authorizationpolicies.security.istio.io destinationrules.networking.istio.io envoyfilters.networking.istio.io gateways.networking.istio.io peerauthentications.security.istio.io proxyconfigs.networking.istio.io requestauthentications.security.istio.io serviceentries.networking.istio.io sidecars.networking.istio.io telemetries.telemetry.istio.io virtualservices.networking.istio.io wasmplugins.extensions.istio.io workloadentries.networking.istio.io workloadgroups.networking.istio.io
)
for i in "${arr[@]}"
do
  echo "starting cycle - "${i}
  oc get ${i}
done
