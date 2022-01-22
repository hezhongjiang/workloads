parameter: {
	image: *"harbor1.zlibs.com/cs/consul:1.7.1" | string
	storage?: {
		capacity: string | *"1G"
	}
}
address?ruct: "\(context.workloadName)-deployment": {
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
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
			}
			spec: {
				serviceAccountName: context.appName
				containers: [{
					name:  "main"
					image: parameter.image
					volumeMounts: [{
						name:      "storage-\(context.workloadName)"
						mountPath: "/consul/data"
					}]
				}]
				volumes: [{
					name: "storage-\(context.workloadName)"
					persistentVolumeClaim: claimName: "storage-\(context.workloadName)"
				}]
			}
		}
		if parameter.storage != _|_ {
			volumeClaimTemplates: [{
				metadata: name: "storage-\(context.workloadName)"
				spec: {
					accessModes: ["ReadWriteOnce"]
					storageClassName: "rook-ceph-block"
					resources: requests: storage: parameter.storage.capacity
				}
			}]
		}
	}
}

service: {
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
			name:       "http"
			port:       8500
			targetPort: 8500
		}, {
			name:       "https"
			port:       8443
			targetPort: 8443
		}, {
			name:       "rpc"
			port:       8400
			targetPort: 8400
		}, {
			name:       "serflan-tcp"
			port:       8301
			targetPort: 8301
		}, {
			name:       "serflan-udp"
			port:       8301
			targetPort: 8301
			protocol:   "UDP"
		}, {
			name:       "serfwan-tcp"
			port:       8302
			targetPort: 8302
		}, {
			name:       "serfwan-udp"
			port:       8302
			targetPort: 8302
			protocol:   "UDP"
		}, {
			name:       "server"
			port:       8300
			targetPort: 8300
		}, {
			name:       "consuldns"
			port:       8600
			targetPort: 8600
		}]
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
		address?: string
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
serviceAccount: {
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      context.appName
		namespace: context.namespace
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
						"workload": v.service
					}
				}
				rules: [
					{
						from: [
							{source: principals: ["cluster.local/ns/\(context.namespace)/sa/\(context.appName)"]},
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
