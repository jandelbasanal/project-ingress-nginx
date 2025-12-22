resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
    labels = {
      name = "demo"
    }
  }
}

resource "kubernetes_deployment" "hello" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = { app = "hello-world" }
  }

  spec {
    replicas = 2
    selector {
      match_labels = { app = "hello-world" }
    }

    template {
      metadata { labels = { app = "hello-world" } }
      spec {
        container {
          name  = "app"
          image = "public.ecr.aws/docker/library/nginx:1.25-alpine"
          port { container_port = 80 }
          readiness_probe {
            http_get { path = "/"; port = 80 }
            initial_delay_seconds = 3
            period_seconds = 5
          }
          liveness_probe {
            http_get { path = "/"; port = 80 }
            initial_delay_seconds = 10
            period_seconds = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = { app = "hello-world" }
  }

  spec {
    selector = { app = "hello-world" }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "hello" {
  metadata {
    name      = "hello-world"
    namespace = kubernetes_namespace.demo.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}]"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
      "alb.ingress.kubernetes.io/load-balancer-name" = "hello-world-alb"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.hello.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}
