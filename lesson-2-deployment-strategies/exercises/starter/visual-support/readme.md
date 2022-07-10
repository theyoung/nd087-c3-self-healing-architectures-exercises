kubectl create serviceaccount ops-view -n udacity
kubectl create clusterrolebinding ops-view-binding --clusterrole=cluster-admin --serviceaccount udacity:ops-view -n udacity
kubectl describe clusterrolebinding ops-view-binding