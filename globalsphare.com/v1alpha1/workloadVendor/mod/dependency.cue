import "mod/context"

parameter: {
  authorization?: [...{
    service: string
    namespace: string
    resources?: [...{
      uri: string
      action: [...string]
    }]
  }]
  serviceentry?: [...{
    host: string
    port: int
    protocol: string
  }]
}
  if parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"] != _|_ {
    if parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"]["serviceentry"] != _|_ {
      for k, v in parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"]["serviceentry"] {
        dependency: "serviceentry-\(context.componentName)-\(v.host)": {
          apiVersion: "networking.istio.io/v1alpha3"
          kind: "ServiceEntry"
          metadata: {
            name: "\(context.componentName)-\(v.host)"
            namespace: context.namespace
          }
          spec: {
            exportTo: ["."]
            hosts: [
              v.host,
            ]
            location: "MESH_EXTERNAL"
            ports: [
              {
                number: v.port
                name: "port-name"
                protocol: v.protocol
              },
            ]
          }
        }
      }
    }
  if parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"] != _|_ {
  if parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"]["authorization"] != _|_ {
    for k, v in parameter["traits"]["globalsphare.com/v1alpha1/trait/dependency"]["authorization"] {
      dependency: "island-allow-\(context.namespace)-to-\(v.namespace)-\(v.service)": {
        apiVersion: "security.istio.io/v1beta1"
        kind: "AuthorizationPolicy"
        metadata: {
          name: "\(context.namespace)-to-\(v.namespace)-\(v.service)"
          namespace: v.namespace
        }
        spec: {
          action: "ALLOW"
          selector: {
            matchLabels: {
              "component": v.service
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
            }
          ]
        }
      }
    }
  }
  }
}

