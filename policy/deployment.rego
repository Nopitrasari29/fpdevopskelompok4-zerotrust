package main

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsUser
  msg = "Deployment must specify a runAsUser in securityContext"
}

deny[msg] {
  input.kind == "Deployment"
  input.spec.template.spec.securityContext.runAsUser == 0
  msg = "Deployment cannot run as root (runAsUser must not be 0)"
}
