prep:
	sudo sysctl fs.inotify.max_user_watches=524288
	sudo sysctl fs.inotify.max_user_instances=512

kind:
	- kind create cluster --config cluster-config.yaml
cilium:
	- helm install cilium cilium/cilium --namespace kube-system --set hubble.relay.enabled=true --set hubble.ui.enabled=true --set kubeProxyReplacement=true 

kind-kp:
	- kind create cluster --config cluster-config-2.yaml
cilium-kp:
	- helm upgrade --install --namespace kube-system --repo https://helm.cilium.io cilium cilium --values cilium-config.yaml

metallb:
	- KIND_NET_CIDR=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
	- METALLB_IP_START=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.200@")
	- METALLB_IP_END=$(echo ${KIND_NET_CIDR} | sed "s@0.0/16@255.250@")
	- METALLB_IP_RANGE="${METALLB_IP_START}-${METALLB_IP_END}"
	- helm repo add metallb https://metallb.github.io/metallb
	- kubectl create ns metallb-system
	- helm install metallb metallb/metallb --version 0.13.11 --namespace=metallb-system

metallb-conf:
	- kubectl apply -f service-ip.yaml
	- kubectl apply -f metallb_values.yaml

apps:
	- kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml

clean-not-kind:
	- kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml
	- helm uninstall cilium -n kube-system

clean-apps:
	kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml

clean:
	- helm uninstall cilium -n kube-system
	- helm uninstall metallb -n metallb-system
	- kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml
	- kind delete cluster











	




