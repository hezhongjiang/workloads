parameter: {
	ingress?: {
		host: string
		path?: [...string]
	}
}
if parameter.ingress != _|_ {
	ingress: "ingressgateway-http": {
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
	ingress: "ingressgateway-https": {
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

	ingress: "virtualservice-http": {
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
	ingress: "virtualservice-https": {
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
