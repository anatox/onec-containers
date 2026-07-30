target "coverage-jenkins-agent-k8s" {
  inherits = ["_defaults"]
  dockerfile = "coverage41C/Dockerfile"
  contexts = {
    "localhost/edt:local" = "target:edt"
    "localhost/onec-jenkins-agent:local-k8s" = "target:base-jenkins-agent-k8s"
  }
  args = {
    BASE_IMAGE = "localhost/onec-jenkins-agent:local-k8s"
    COVERAGE41C_VERSION = "${COVERAGE41C_VERSION}"
  }
  tags = tags_suffixed("onec-coverage-jenkins-agent", COVERAGE41C_VERSION, "k8s")
  labels = {
    "org.opencontainers.image.title" = "Coverage41C Jenkins agent"
    "org.opencontainers.image.version" = COVERAGE41C_VERSION
  }
  description = jsonencode({"image" = "onec-coverage-jenkins-agent"})
  cache_from = cache_from("onec-coverage-jenkins-agent")
  cache_to = cache_to("onec-coverage-jenkins-agent")
}

target "coverage-jenkins-agent-swarm" {
  inherits = ["_defaults"]
  dockerfile = "coverage41C/Dockerfile"
  contexts = {
    "localhost/edt:local" = "target:edt"
    "localhost/onec-jenkins-agent:local-swarm" = "target:base-jenkins-agent-swarm"
  }
  args = {
    BASE_IMAGE = "localhost/onec-jenkins-agent:local-swarm"
    COVERAGE41C_VERSION = "${COVERAGE41C_VERSION}"
  }
  tags = tags_suffixed("onec-coverage-jenkins-agent", COVERAGE41C_VERSION, "swarm")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise code coverage agent"
    "org.opencontainers.image.version" = COVERAGE41C_VERSION
  }
  description = jsonencode({"image" = "onec-coverage-jenkins-agent"})
  cache_from = cache_from("onec-coverage-jenkins-agent")
  cache_to = cache_to("onec-coverage-jenkins-agent")
}
