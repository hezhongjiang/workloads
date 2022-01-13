parameter: {
	image:    *"rabbitmq:3-management" | string
	vhost:    *"my_vhost" | string
	user:     *"admin" | string
	password: *"123456" | string
	size:     *"1G" | string
}
"deployment": {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		selector: matchLabels: {
			app:      context.appName
			workload: context.workloadName
		}
		replicas: 1
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
			}
			spec: {
				containers: [{
					name:  "main"
					image: parameter["image"]
					env: [{
						name:  "RABBITMQ_DEFAULT_VHOST"
						value: parameter["vhost"]
					}, {
						name:  "RABBITMQ_DEFAULT_USER"
						value: parameter["user"]
					}, {
						name:  "RABBITMQ_DEFAULT_PASS"
						value: parameter["password"]
					}]
				}]
				restartPolicy: "Always"
			}
		}
	}
}

"service": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		selector: {
			app:      context.appName
			workload: context.workloadName
		}
		ports: [{
			port: 1883
			name: "port-1833"
		}, {
			port: 4369
			name: "port-4369"
		}, {
			port: 5671
			name: "port-5671"
		}, {
			port: 5672
			name: "port-5672"
		}, {
			port: 8883
			name: "port-8883"
		}, {
			port: 15672
			name: "port-15672"
		}, {
			port: 25672
			name: "port-25672"
		}, {
			port: 61613
			name: "port-61613"
		}, {
			port: 61614
			name: "port-61614"
		}]
		type: "ClusterIP"
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
							{source: namespaces: [context.namespace]}
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
				{source: namespaces: ["istio-system"]}
			]
			to: [{
				operation: {
					methods: ["GET", "POST", "DELETE", "PUT", "HEAD", "OPTIONS", "PATCH"]
				}
			}]
		}]
	}
}