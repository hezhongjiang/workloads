parameter: {
    size?: *"1G" | string
}
"redis-conf": {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(context.workloadName)-redis-conf"
		namespace: context.namespace
	}
	data: {
		master: """
			pidfile /var/run/redis.pid
			port 6379
			bind 0.0.0.0
			timeout 3600
			tcp-keepalive 1
			loglevel verbose
			logfile /data/redis.log
			slowlog-log-slower-than 10000
			slowlog-max-len 128
			databases 16
			protected-mode no
			save \"\"
			appendonly no
			"""

		slave: """
        pidfile /var/run/redis.pid
        port 6379
        bind 0.0.0.0
        timeout 3600
        tcp-keepalive 1
        loglevel verbose
        logfile /data/redis.log
        slowlog-log-slower-than 10000
        slowlog-max-len 128
        databases 16
        protected-mode no
        save \"\"
        appendonly no
        slaveof \(context.workloadName)-master 6379
        """
	}
}
"service-master": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-master"
		namespace: context.namespace
		labels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
	}
	spec: {
		ports: [{
			name: context.workloadName
			port: 6379
		}]
		selector: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
	}
}
"service-master-headless": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-master-headless"
		namespace: context.namespace
		labels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name: context.workloadName
			port: 6379
		}]
		selector: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
	}
}
"statefulset-master": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(context.workloadName)-master"
		namespace: context.namespace
	}
	spec: {
		selector: matchLabels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
		serviceName: context.workloadName
		replicas:    1
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
				item:     "\(context.workloadName)-master"
			}
			spec: {
				containers: [{
					name:  "main"
					image: "harbor1.zlibs.com/dockerhub/redis:6.2.4"
					ports: [{
						containerPort: 6379
						name:          "redis"
					}]
					command: [
						"redis-server",
						"/etc/redis/redis.conf",
					]
					volumeMounts: [{
						name:      "redis-conf"
						mountPath: "/etc/redis/redis.conf"
						subPath:   "master"
					}]
				}]
				volumes: [{
					name: "redis-conf"
					configMap: name: "\(context.workloadName)-redis-conf"
				}]
			}
		}
	}
}

"slave-service": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-slave"
		namespace: context.namespace
		labels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-slave"
		}
	}
	spec: {
		ports: [{
			name: context.workloadName
			port: 6379
		}]
		selector: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-slave"
		}
	}
}

"slave-service-headless": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-slave-headless"
		namespace: context.namespace
		labels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-slave"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name: "\(context.workloadName)"
			port: 6379
		}]
		selector: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-slave"
		}
	}
}

"slave-statefulset": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(context.workloadName)-slave"
		namespace: context.namespace
	}
	spec: {
		selector: matchLabels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-slave"
		}
		serviceName: context.workloadName
		replicas:    2
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
				item:     "\(context.workloadName)-slave"
			}
			spec: {
				containers: [{
					name:  "\(context.workloadName)-slave"
					image: "harbor1.zlibs.com/dockerhub/redis:6.2.4"
					ports: [{
						containerPort: 6379
						name:          "redis"
					}]
					command: [
						"bash",
						"-c",
						"""
                until [ \"$(echo 'set check_status 1'|timeout 3 redis-cli -h \(context.workloadName)-master)\" = \"OK\" ];do sleep 4s;echo \"waiting for the master ready\";done
                redis-server /etc/redis/redis.conf
                """]
					volumeMounts: [{
						name:      "redis-conf"
						mountPath: "/etc/redis/redis.conf"
						subPath:   "slave"
					}]
				}]
				volumes: [{
					name: "redis-conf"
					configMap: name: "\(context.workloadName)-redis-conf"
				}]
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
		labels: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
	}
	spec: {
		ports: [{
			name: context.workloadName
			port: 6379
		}]
		selector: {
			app:      context.appName
			workload: context.workloadName
			item:     "\(context.workloadName)-master"
		}
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
