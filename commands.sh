# 0. Setting up AKS with Calico enabled

# 1. Create development namespace with labels
kubectl create -f 1-namespace-development.yaml
# or
kubectl create namespace development
kubectl label namespace/development purpose=development

# 2. Create an nginx Pod and Service
kubectl create -f 1-pod-svc-nginx-backend.yaml
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
wget -qO- --timeout=2 http://backend

# 5. Allow inbound traffic based on a pod label
# Update the previous Network Policy to allow traffic from only pods with specific labels
kubectl apply -f 5-network-policy-allow-pod.yaml
# 5.1 test
kubectl create -f 3-pod-alpine
kubectl exec alpine -n development -- wget -qO- http://backend
# or
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace development --generator=run-pod/v1
wget -qO- http://backend

# 5.2 test
# or 
kubectl run --rm -it --image=alpine network-policy --namespace development --generator=run-pod/v1
wget -qO- --timeout=2 http://backend

# 6 Allow traffic only from within a defined namespace
# 6.1 Test without Policy and pod reaching other namespaces
kubectl create namespace production
kubectl label namespace/production purpose=production
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production --generator=run-pod/v1
wget -qO- http://backend.development

# 6.2 Create the policy
kubectl apply -f 3-network-policy

# 6.3 Test with policy and pod from same namespace
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production --generator=run-pod/v1
wget -qO- --timeout=2 http://backend.development

# 6.4 Test with policy and pod from different namespace
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace development --generator=run-pod/v1
wget -qO- http://backend

