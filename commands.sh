# 1. Create development namespace
kubectl create -f 1-namespace
# or
kubectl create namespace development
kubectl label namespace/development purpose=development

# 2. Create an nginx Pod and Service
kubectl create -f 2-pod-svc
# or
kubectl run backend --image=nginx --labels app=webapp,role=backend --namespace development --expose --port 80 --generator=run-pod/v1

# 3. Create Alpine Pod for testing access to other pods
kubectl create -f 3-pod-alpine
kubectl exec alpine -n development -- wget -qO- http://backend
# or
kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1
wget -qO- http://backend

# 4. Create a Network Policy to deny all connections to backend Pod
kubectl apply -f 4-network-policy-deny.yaml

# 4.1 Test access to backend Pod
# We'll reuse the same Aplpine image to run the test:
kubectl exec alpine -n development -- wget -qO- --timeout=2 http://backend
# or
kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1

# 5. Allow inbound traffic based on a pod label
# Update the previous Network Policy to allow traffic from only pods with specific labels
kubectl apply -f 5-network-policy-allow-pod.yaml
