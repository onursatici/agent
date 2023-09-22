resource "kubernetes_service" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }

  spec {
    port {
      name        = "http-metrics"
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/name" = "grafana-agent"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_cluster_role" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["", "discovery.k8s.io", "networking.k8s.io"]
    resources  = ["endpoints", "endpointslices", "ingresses", "nodes", "nodes/proxy", "nodes/metrics", "pods", "services"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["pods", "pods/log", "namespaces"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["monitoring.grafana.com"]
    resources  = ["podlogs"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["monitoring.coreos.com"]
    resources  = ["prometheusrules"]
  }

  rule {
    verbs             = ["get"]
    non_resource_urls = ["/metrics"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["monitoring.coreos.com"]
    resources  = ["podmonitors", "servicemonitors", "probes"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["events"]
  }
}

resource "kubernetes_cluster_role_binding" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "grafana-agent"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "grafana-agent"
  }
}

resource "kubernetes_service_account" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }
}

resource "kubernetes_config_map" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }

  data = {
    "config.river" = "logging {\n\tlevel  = \"info\"\n\tformat = \"logfmt\"\n}\n\ndiscovery.kubernetes \"pods\" {\n\trole = \"pod\"\n}\n\ndiscovery.kubernetes \"nodes\" {\n\trole = \"node\"\n}\n\ndiscovery.kubernetes \"services\" {\n\trole = \"service\"\n}\n\ndiscovery.kubernetes \"endpoints\" {\n\trole = \"endpoints\"\n}\n\ndiscovery.kubernetes \"endpointslices\" {\n\trole = \"endpointslice\"\n}\n\ndiscovery.kubernetes \"ingresses\" {\n\trole = \"ingress\"\n}"
  }
}

resource "kubernetes_deployment" "grafana_agent" {
  metadata {
    name = "grafana-agent"

    labels = {
      "app.kubernetes.io/instance" = "grafana-agent"

      "app.kubernetes.io/managed-by" = "Helm"

      "app.kubernetes.io/name" = "grafana-agent"

      "app.kubernetes.io/version" = "vX.Y.Z"

      "helm.sh/chart" = "grafana-agent"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/instance" = "grafana-agent"

        "app.kubernetes.io/name" = "grafana-agent"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/instance" = "grafana-agent"

          "app.kubernetes.io/name" = "grafana-agent"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "grafana-agent"
          }
        }

        container {
          name  = "grafana-agent"
          image = "docker.io/grafana/agent:v0.36.1"
          args  = ["run", "/etc/agent/config.river", "--storage.path=/tmp/agent", "--server.http.listen-addr=0.0.0.0:80"]

          port {
            name           = "http-metrics"
            container_port = 80
          }

          env {
            name  = "AGENT_MODE"
            value = "flow"
          }

          env {
            name = "HOSTNAME"

            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/agent"
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = "80"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 1
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name  = "config-reloader"
          image = "docker.io/jimmidyson/configmap-reload:v0.8.0"
          args  = ["--volume-dir=/etc/agent", "--webhook-url=http://localhost:80/-/reload"]

          resources {
            requests = {
              cpu = "1m"

              memory = "5Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/agent"
          }
        }

        dns_policy           = "ClusterFirst"
        service_account_name = "grafana-agent"
      }
    }

    min_ready_seconds = 10
  }
}

