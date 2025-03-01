parameter:{
    count: *3 |int
}
"service-consul-ui": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)"
		namespace: context.namespace
	}
	spec: {
		ports: [{
			name:       "http"
			port:       80
			targetPort: 8500
		}]
		selector: {
			app:       context.workloadName
			component: "server"
			workload:  context.workloadName
		}
	}
}
"service-consul-dns": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-dns"
		namespace: context.namespace
	}
	spec: {
		ports: [{
			name:       "dns-tcp"
			port:       53
			protocol:   "TCP"
			targetPort: "dns-tcp"
		}, {
			name:       "dns-udp"
			port:       53
			protocol:   "UDP"
			targetPort: "dns-udp"
		}]
		selector: {
			app:      context.workloadName
			workload: context.workloadName
		}
	}
}
"service-consul-server": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-server"
		namespace: context.namespace
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "http"
			port:       8500
			targetPort: 8500
		}, {
			name:       "dns-tcp"
			port:       8600
			protocol:   "TCP"
			targetPort: "dns-tcp"
		}, {
			name:       "dns-udp"
			port:       8600
			protocol:   "UDP"
			targetPort: "dns-udp"
		}, {
			name:       "serflan-tcp"
			port:       8301
			protocol:   "TCP"
			targetPort: 8301
		}, {
			name:       "serflan-udp"
			port:       8301
			protocol:   "UDP"
			targetPort: 8302
		}, {
			name:       "serfwan-tcp"
			port:       8302
			protocol:   "TCP"
			targetPort: 8302
		}, {
			name:       "serfwan-udp"
			port:       8302
			protocol:   "UDP"
			targetPort: 8302
		}, {
			name:       "server"
			port:       8300
			targetPort: 8300
		}]
		publishNotReadyAddresses: true
		selector: {
			app:       context.workloadName
			component: "server"
			workload:  context.workloadName
		}
	}
}
"statefulSet-consul-server": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(context.workloadName)-server"
		namespace: context.namespace
	}
	spec: {
		replicas: parameter.count
		selector: matchLabels: {
			app:       context.workloadName
			component: "server"
			workload:  context.workloadName
		}
		serviceName: "\(context.workloadName)-server"
		template: {
			metadata: labels: {
				app:       context.workloadName
				component: "server"
				workload:  context.workloadName
			}
			spec: {
				containers: [{
					args: [
						"agent",
						"-server",
						"-advertise=$(POD_IP)",
						"-bind=0.0.0.0",
						"-bootstrap-expect=3",
						"-datacenter=dc1",
						"-data-dir=/consul/data",
						"-disable-host-node-id",
						"-domain=cluster.local",
						"-retry-join=\(context.workloadName)-server-0.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-1.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-2.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-3.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-4.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-client=0.0.0.0",
						"-ui",
					]
					env: [{
						name: "POD_IP"
						valueFrom: fieldRef: fieldPath: "status.podIP"
					}]
					image:           "consul:latest"
					imagePullPolicy: "IfNotPresent"
					lifecycle: preStop: exec: command: [
						"/bin/sh",
						"-c",
						"consul leave",
					]
					name: "consul"
					ports: [{
						containerPort: 8500
						name:          "http"
					}, {
						containerPort: 8600
						name:          "dns-tcp"
						protocol:      "TCP"
					}, {
						containerPort: 8600
						name:          "dns-udp"
						protocol:      "UDP"
					}, {
						containerPort: 8301
						name:          "serflan"
					}, {
						containerPort: 8302
						name:          "serfwan"
					}, {
						containerPort: 8300
						name:          "server"
					}]
					//volumeMounts: [{
					// name:      "server-data"
					// mountPath: "/consul/data"
					//}]
				}]
				//volumes: [{
				// name: "server-data"
				// configMap: name: "\(context.workloadName)-server-data"
				//}]
			}
		}
		//volumeClaimTemplates: [{
		// metadata: name: "\(context.workloadName)-server-data"
		// spec: {
		//  accessModes: ["ReadWriteOnce"]
		//  storageClassName: "rook-ceph-block"
		//  resources: requests: storage: "500M"
		// }
		//}]
	}
}
"daemonSet-consul": {
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		selector: matchLabels: {
			app:       context.workloadName
			component: "client"
			workload:  context.workloadName
		}
		template: {
			metadata: labels: {
				app:       context.workloadName
				component: "client"
				workload:  context.workloadName
			}
			spec: {
				containers: [{
					args: [
						"agent",
						"-advertise=$(POD_IP)",
						"-bind=0.0.0.0",
						"-datacenter=dc1",
						"-data-dir=/consul/data",
						"-disable-host-node-id=true",
						"-domain=cluster.local",
						"-retry-join=\(context.workloadName)-server-0.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-1.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-2.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-3.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-retry-join=\(context.workloadName)-server-4.\(context.workloadName)-server.\(context.namespace).svc.cluster.local",
						"-client=0.0.0.0",
					]
					env: [{
						name: "POD_IP"
						valueFrom: fieldRef: fieldPath: "status.podIP"
					}]
					image:           "consul:latest"
					imagePullPolicy: "IfNotPresent"
					lifecycle: preStop: exec: command: [
						"/bin/sh",
						"-c",
						"consul leave",
					]
					name: "consul"
					ports: [{
						containerPort: 8500
						name:          "http"
					}, {
						containerPort: 8600
						name:          "dns-tcp"
						protocol:      "TCP"
					}, {
						containerPort: 8600
						name:          "dns-udp"
						protocol:      "UDP"
					}, {
						containerPort: 8301
						name:          "serflan"
					}, {
						containerPort: 8302
						name:          "serfwan"
					}, {
						containerPort: 8300
						name:          "server"
					}]
					//volumeMounts: [{
					// name:      "client-data"
					// mountPath: "/consul/data"
					//}]
				}]
				//volumes: [{
				// name: "client-data"
				// configMap: name: "\(context.workloadName)-client-data"
				//}]
			}
		}
		//volumeClaimTemplates: [{
		// metadata: name: "\(context.workloadName)-client-data"
		// spec: {
		//  accessModes: ["ReadWriteOnce"]
		//  storageClassName: "rook-ceph-block"
		//  resources: requests: storage: "500M"
		// }
		//}]
	}
}
context: {
	appName:      string
	workloadName: string
	namespace:    string
}
parameter: {
	authorization?: [...{
		service:   string
		namespace: string
		resources?: [...{
			uri: string
			action: [...string]
		}]
	}]
	serviceEntry?: [...{
		name:     string
		host:     string
		address:  string
		port:     int
		protocol: string
	}]
	dependencies?: [string]: host: string
	userconfigs?: string | *"{}"
	ingress?: {
		host: string
		path?: [...string]
	}
}

namespace: {
	apiVersion: "v1"
	kind:       "Namespace"
	metadata: {
		name: context.namespace
		labels: {
			"istio-injection": "enabled"
		}
	}
}
"default-authorizationPolicy": {
	apiVersion: "security.istio.io/v1beta1"
	kind:       "AuthorizationPolicy"
	metadata: {
		name:      context.namespace
		namespace: context.namespace
	}
	spec: {}
}
if parameter.serviceEntry != _|_ {
	for k, v in parameter.serviceEntry {
		"serviceEntry-\(context.workloadName)-to-\(v.name)": {
			apiVersion: "networking.istio.io/v1alpha3"
			kind:       "ServiceEntry"
			metadata: {
				name:      "\(context.workloadName)-to-\(v.name)"
				namespace: context.namespace
			}
			spec: {
				exportTo: ["."]
				hosts: [
					v.host,
				]
				if v.address != _|_ {
					addresses: [
						v.address,
					]
				}
				location: "MESH_EXTERNAL"
				ports: [
					{
						number:   v.port
						name:     "port-name"
						protocol: v.protocol
					},
				]
			}
		}
	}
}
if parameter.authorization != _|_ {
	for k, v in parameter.authorization {
		"island-allow-\(context.namespace)-to-\(v.namespace)-\(v.service)": {
			apiVersion: "security.istio.io/v1beta1"
			kind:       "AuthorizationPolicy"
			metadata: {
				name:      "\(context.namespace)-to-\(v.namespace)-\(v.service)"
				namespace: v.namespace
			}
			spec: {
				action: "ALLOW"
				selector: {
					matchLabels: {
						workload: v.service
					}
				}
				rules: [
					{
						from: [
							{source: namespaces: [context.namespace]},
						]
						if v.resources != _|_ {
							to: [
								for resource in v.resources {
									operation: {
										methods: resource.actions
										paths: [resource.uri]
									}
								},
							]
						}
					},
				]
			}
		}
	}
}

if parameter.ingress != _|_ {
	"ingressgateway-http": {
		apiVersion: "networking.istio.io/v1alpha3"
		kind:       "Gateway"
		metadata: {
			name:      "\(context.namespace)-http"
			namespace: "island-system"
		}
		spec: {
			selector: istio: "ingressgateway"
			servers: [
				{
					port: {
						number:   80
						name:     "http"
						protocol: "HTTP"
					}
					hosts: [
						parameter.ingress.host,
					]
				},
			]
		}
	}
	"gateway-https": {
		apiVersion: "networking.istio.io/v1alpha3"
		kind:       "Gateway"
		metadata: {
			name:      "\(context.namespace)-https"
			namespace: "island-system"
		}
		spec: {
			selector: istio: "ingressgateway"
			servers: [
				{
					port: {
						number:   443
						name:     "https"
						protocol: "HTTPS"
					}
					tls: {
						mode:              "SIMPLE"
						serverCertificate: "/etc/istio/ingressgateway-certs/tls.crt"
						privateKey:        "/etc/istio/ingressgateway-certs/tls.key"
					}
					hosts: [
						parameter.ingress.host,
					]
				},
			]
		}
	}
	"virtualservice-http": {
		apiVersion: "networking.istio.io/v1alpha3"
		kind:       "VirtualService"
		metadata: {
			name:      "\(context.appName)-http"
			namespace: context.namespace
		}
		spec: {
			hosts: ["*"]
			gateways: ["island-system/\(context.namespace)-http"]
			http: [
				{
					name: context.workloadName
					if parameter.ingress.http != _|_ {
						match: []
					}
					route: [{
						destination: {
							port: number: 80
							host: context.workloadName
						}
						headers: {
							request: {
								add: {
									"X-Forwarded-Host": parameter.ingress.host
								}
							}
						}
					}]
				},
			]
		}
	}
	"virtualservice-https": {
		apiVersion: "networking.istio.io/v1alpha3"
		kind:       "VirtualService"
		metadata: {
			name:      "\(context.appName)-https"
			namespace: context.namespace
		}
		spec: {
			hosts: ["*"]
			gateways: ["island-system/\(context.namespace)-https"]
			http: [
				{
					match: []
					route: [
						{
							destination: {
								host: context.workloadName
								port: {
									number: 80
								}
							}
							headers: {
								request: {
									add: {
										"X-Forwarded-Host": parameter.ingress.host
									}
								}
							}
						},
					]
				},
			]
		}
	}
}
"viewer": {
	apiVersion: "security.istio.io/v1beta1"
	kind:       "AuthorizationPolicy"
	"metadata": {
		name:      "\(context.workloadName)-viewer"
		namespace: context.namespace
	}
	spec: {
		selector: {
			matchLabels: {
				workload: context.workloadName
			}
		}
		rules: [{
			from: [
				{source: namespaces: ["istio-system"]},
			]
			to: [{
				operation: {
					methods: ["GET", "POST", "DELETE", "PUT", "HEAD", "OPTIONS", "PATCH"]
				}
			}]
		}]
	}
}
