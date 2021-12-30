parameter: {
	image: string
	port:  *80 | int
	cmd?: [...string]
	args?: [...string]
	cpu?: string
	env?: [...{
		name:   string
		value?: string
		valueFrom?: {
			secretKeyRef: {
				name: string
				key:  string
			}
		}
	}]
	configs?: [...{
		path:     string
		subPath?: string
		data: [...{
			name:  string
			value: string
		}]
	}]
	storage?: {
		capacity: string
		path:     string
	}
}
if parameter.userconfigs != _|_ {
	"configMap-userconfigs": {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "userconfigs"
			namespace: context.namespace
		}
		data: userconfigs: parameter.userconfigs
	}
}
if parameter.dependencies != _|_ {
	for k, v in parameter.dependencies {
		"dependencies-\(k)": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "dependencies-\(k)"
				namespace: context.namespace
			}
			data: {
				"\(k)": v.host
			}
		}
	}
}
if parameter.configs != _|_ {
	for k, v in parameter.configs {
		"island-\(context.workloadName)-\(k)": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(context.workloadName)-\(k)"
				namespace: context.namespace
			}
			data: {
				for _, vv in v.data {
					"\(vv.name)": vv.value
				}
			}
		}
	}
}
if parameter.storage != _|_ {
	if parameter.storage.capacity != "" {
		storage: {
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: {
				name:      "storage-\(context.workloadName)"
				namespace: context.namespace
			}
			spec: {
				storageClassName: "rook-ceph-block"
				accessModes: [
					"ReadWriteOnce",
				]
				resources: requests: storage: parameter.storage.capacity
			}
		}
	}
}
"statefulSet-example": {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      context.workloadName
		namespace: context.namespace
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			app:      context.appName
			workload: context.workloadName
		}
		serviceName: "\(context.workloadName)-headless"
		template: {
			metadata: labels: {
				app:      context.appName
				workload: context.workloadName
			}
			spec: {
				containers: [{
					image: parameter.image
					name:  "main"
					if parameter.cmd != _|_ {
						command: parameter.cmd
					}
					if parameter.args != _|_ {
						args: parameter.args
					}
					if parameter.env != _|_ {
						env: parameter.env
					}
					if parameter.cpu != _|_ {
						resources: {
							limits: {
								cpu: parameter.cpu
							}
							requests: {
								cpu: parameter.cpu
							}
						}
					}
					ports: [{
						containerPort: parameter.port
					}]
					volumeMounts: [
						if parameter.configs != _|_
						for k, v in parameter.configs if v.subPath != _|_ {
							name:      "\(context.workloadName)-\(k)"
							mountPath: "\(v.path)/\(v.subPath)"
							subPath:   v.subPath
						},

						if parameter.configs != _|_
						for k, v in parameter.configs if v.subPath == _|_ {
							name:      "\(context.workloadName)-\(k)"
							mountPath: v.path
						},

						if parameter.userconfigs != _|_ {
							name:      "userconfigs"
							mountPath: "/etc/configs/userconfigs"
							subPath:   "userconfigs"
						},

						if parameter.dependencies != _|_
						for k, v in parameter.dependencies {
							name:      "dependencies-\(k)"
							mountPath: "/etc/configs/\(k)"
							subPath:   "\(k)"
						},

						if parameter.storage != _|_
						if parameter.storage.capacity != "" {
							name:      "storage-\(context.workloadName)"
							mountPath: parameter.storage.path
						},
					]
				}]
				volumes: [
					if parameter.configs != _|_
					for k, v in parameter.configs if v.subPath != _|_ {
						name: "\(context.workloadName)-\(k)"
						configMap: name: "\(context.workloadName)-\(k)"
					},

					if parameter.configs != _|_
					for k, v in parameter.configs if v.subPath == _|_ {
						name: "\(context.workloadName)-\(k)"
						configMap: name: "\(context.workloadName)-\(k)"
					},

					if parameter.userconfigs != _|_ {
						name: "userconfigs"
						configMap: name: "userconfigs"
					},

					if parameter.dependencies != _|_
					for k, v in parameter.dependencies {
						name: "dependencies-\(k)"
						configMap: name: "dependencies-\(k)"
					},

					if parameter.storage != _|_
					if parameter.storage.capacity != "" {
						name: "storage-\(context.workloadName)"
						persistentVolumeClaim: claimName: "storage-\(context.workloadName)"
					},
				]
			}
		}
	}
}
"service-headless": {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(context.workloadName)-headless"
		namespace: context.namespace
	}
	spec: {
		clusterIP: "None"
		selector: {
			app:      context.appName
			workload: context.workloadName
		}
	}
}
