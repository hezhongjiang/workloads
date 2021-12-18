import "mod/context"

parameter: {
	storage?: {
		capacity: string
		path:     string
	}
}

if parameter.storage != _|_ {
	if parameter.storage.capacity != "" {
		construct: {
			"storage": {
				apiVersion: "v1"
				kind:       "PersistentVolumeClaim"
				metadata: {
					name:      "storage-\(context.componentName)"
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
}
