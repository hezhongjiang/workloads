import "mod/context"

parameter: {
	entry?: {
		host: string
		path?: [...string]
	}
}
if parameter["entry"] != _|_ {
	if parameter["entry"]["host"] != "" {
		outputs: "ingressgateway-http": {
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
							parameter["entry"]["host"],
						]
					},
				]
			}
		}
		construct: "ingressgateway-https": {
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
							parameter["entry"]["host"],
						]
					},
				]
			}
		}

		construct: "virtualservice-http": {
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
						if parameter.entry.path != _|_ {
							match: [
								for k, v in parameter.entry.path {
									{uri: regex: v}
								},
							]
						}
						route: [{
							destination: {
								port: number: 80
								host: context.workloadName
							}
						}]
					},
				]
			}
		}

		construct: "virtualservice-https": {
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
						match: [
							{
								uri: {
									regex: "/.*"
								}
							},
						]
						route: [
							{
								destination: {
									host: context.workloadName
									port: {
										number: 80
									}
								}
							},
						]
					},
				]
			}
		}
	}
}
