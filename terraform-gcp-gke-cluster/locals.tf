locals {
  gke_cluster_name = "gke-${var.name}"

  istio_version = "1.22.1"

  internal_subnet_cidr   = "10.0.0.0/24"
  master_ipv4_cidr_block = "172.16.0.16/28"
  proxy_only_ipv4_cidr   = "11.129.0.0/23"

  cluster_ipv4_cidr_block  = "5.0.0.0/16"
  services_ipv4_cidr_block = "5.1.0.0/16"

  istio_ingress_gateway_values = <<EOF
---
service:
  type: ClusterIP
  ports:
    - name: status-port
      port: 15021
      protocol: TCP
      targetPort: 15021
    - name: http2
      port: 80
      protocol: TCP
      targetPort: 80
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
  annotations:
    cloud.google.com/neg: '{"exposed_ports": {"80":{"name": "private-istio-ingress-gateway"}}}'
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  externalTrafficPolicy: ""
  externalIPs: []
labels:
  istio: private-ingressgateway
EOF
}
