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
					//	name:      "server-data"
					//	mountPath: "/consul/data"
					//}]
				}]
				//volumes: [{
				//	name: "server-data"
				//	configMap: name: "\(context.workloadName)-server-data"
				//}]
			}
		}
		//volumeClaimTemplates: [{
		//	metadata: name: "\(context.workloadName)-server-data"
		//	spec: {
		//		accessModes: ["ReadWriteOnce"]
		//		storageClassName: "rook-ceph-block"
		//		resources: requests: storage: "500M"
		//	}
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
					//	name:      "client-data"
					//	mountPath: "/consul/data"
					//}]
				}]
				//volumes: [{
				//	name: "client-data"
				//	configMap: name: "\(context.workloadName)-client-data"
				//}]
			}
		}
		//volumeClaimTemplates: [{
		//	metadata: name: "\(context.workloadName)-client-data"
		//	spec: {
		//		accessModes: ["ReadWriteOnce"]
		//		storageClassName: "rook-ceph-block"
		//		resources: requests: storage: "500M"
		//	}
		//}]
	}
}
