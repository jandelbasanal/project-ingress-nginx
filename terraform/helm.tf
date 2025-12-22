resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  create_namespace = false
  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
    })
  ]
  depends_on = [aws_iam_role_policy_attachment.alb_attach]
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
  values = [file("${path.module}/helm_ingress_values.yaml")]
}
