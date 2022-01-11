parameter: {
	image:    *"rabbitmq:3-management" | string
	vhost:    *"my_vhost" | string
	user:     *"admin" | string
	password: *"123456" | string
	size:     *"1G" | string
}
"configmap": {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	data: {
		"enabled_plugins": """
			[rabbitmq_federation_management,rabbitmq_management,rabbitmq_mqtt,rabbitmq_stomp].
			"""
	}
}

"statefulset": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		selector: matchLabels: {
			app:      context.appName
			workload: context.workloadName
		}
		serviceName: context.workloadName
		volumeClaimTemplates: [{
			metadata: name: "storage"
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: "rook-cephfs"
				resources: requests: storage: parameter.size
			}
		}]
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
			}
			spec: {
				containers: [{
					name:  "main"
					image: parameter.image
					env: [{
						name:  "RABBITMQ_DEFAULT_VHOST"
						value: parameter.vhost
					}, {
						name:  "RABBITMQ_DEFAULT_USER"
						value: parameter.user
					}, {
						name:  "RABBITMQ_DEFAULT_PASS"
						value: parameter.password
					}]
					volumeMounts: [{
						mountPath: "/etc/rabbitmq/enabled_plugins"
						name:      "conf"
						subPath:   "enabled_plugins"
					}, {
						mountPath: "/var/lib/rabbitmq"
						name:      "storage"
					}]
				}]
				restartPolicy: "Always"
				volumes: [{
					name: "conf"
					configMap: name: context.workloadName
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