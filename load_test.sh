#!/bin/sh

create_a_namespace()
{
    test_mm_ns_local=$1
    oc new-project ${test_mm_ns_local} --skip-config-write=true
    oc label namespace ${test_mm_ns_local} modelmesh-enabled=true --overwrite=true
}

delete_a_namespace()
{
    test_mm_ns_local=$1
    oc delete project ${test_mm_ns_local}
}

for i in {1..20}
do
  echo "starting cycle - "${i}
  for j in {1..100}
  do
    test_mm_ns=$(echo "opendatahub-mm-"${i}"-"${j})
    #echo ${test_mm_ns}
    #create_a_namespace ${test_mm_ns} &
    delete_a_namespace ${test_mm_ns} &
  done
  wait
done
