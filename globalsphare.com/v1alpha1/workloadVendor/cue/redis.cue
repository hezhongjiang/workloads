parameter: {}
serviceAccount: {
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
}
"redis-conf": {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(context.workload)-redis-conf"
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
				serviceAccountName: context.workloadName
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
				serviceAccountName: context.workloadName
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
