import "list"

parameter: {
	size: *"1G" | string
}
"service": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: context.workloadName
		labels: {
			app:      context.appName
			workload: context.workloadName
		}
		namespace: context.namespace
	}
	spec: {
		selector: {
			app:      context.appName
			workload: context.workloadName
		}
		ports: [{
			name: "client"
			port: 2181
		}]
	}
}
"headless-service": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "\(context.workloadName)-headless"
		labels: {
			app:      context.appName
			workload: context.workloadName
		}
		namespace: context.namespace
	}
	spec: {
		selector: {
			app:      context.appName
			workload: context.workloadName
		}
		clusterIP: "None"
		ports: [{
			name: "client"
			port: 2181
		}, {
			name: "server"
			port: 2888
		}, {
			name: "leader-election"
			port: 3888
		}]
	}
}

"StatefulSet": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		serviceName: "\(context.workloadName)-headless"
		replicas:    1
		selector: {
			matchLabels: {
				app:      context.appName
				workload: context.workloadName
			}
		}
		template: {
			metadata: {
				labels: {
					app:      context.appName
					workload: context.workloadName
				}
			}
			spec: {
				containers: [{
					name:  "main"
					image: "fastop/zookeeper:3.4.10"
					ports: [{
						containerPort: 2181
						name:          "client"
					}, {
						containerPort: 2888
						name:          "server"
					}, {
						containerPort: 3888
						name:          "leader-election"
					}]
					command: [
						"sh",
						"-c",
						"start-zookeeper --servers=1 --data_dir=/var/lib/zookeeper/data --data_log_dir=/var/lib/zookeeper/data/log --conf_dir=/opt/zookeeper/conf --client_port=2181 --election_port=3888 --server_port=2888 --tick_time=2000 --init_limit=10 --sync_limit=5 --heap=1G --max_client_cnxns=60 --snap_retain_count=3 --purge_interval=12 --max_session_timeout=40000 --min_session_timeout=4000 --log_level=INFO",
					]
					volumeMounts: [
						{
							name:      "storage-\(context.workloadName)"
							mountPath: "/var/lib/zookeeper"
						}]
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: {
				name: "storage-\(context.workloadName)"
			}
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: "rook-ceph-block"
				resources: {
					requests: {
						storage: parameter.size
					}
				}
			}
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
