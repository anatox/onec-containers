target "coverage-agent-k8s" {
  dockerfile = "coverage41C/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt:local" = "target:edt"
    "localhost/base-jenkins-agent:local-k8s" = "target:base-jenkins-agent-k8s"
  }
  args = {
    BASE_IMAGE = "localhost/base-jenkins-agent:local-k8s"
    COVERAGE41C_VERSION = "${COVERAGE41C_VERSION}"
  }
  tags = agent_tags("base-jenkins-coverage-agent", COVERAGE41C_VERSION, "k8s")
  labels = labels("base-jenkins-coverage-agent", "1C code coverage agent ${COVERAGE41C_VERSION} (k8s)")
  cache_from = cache_from("base-jenkins-coverage-agent")
  cache_to = cache_to("base-jenkins-coverage-agent")
}

target "coverage-agent-swarm" {
  dockerfile = "coverage41C/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt:local" = "target:edt"
    "localhost/base-jenkins-agent:local-swarm" = "target:base-jenkins-agent-swarm"
  }
  args = {
    BASE_IMAGE = "localhost/base-jenkins-agent:local-swarm"
    COVERAGE41C_VERSION = "${COVERAGE41C_VERSION}"
  }
  tags = agent_tags("base-jenkins-coverage-agent", COVERAGE41C_VERSION, "swarm")
  labels = labels("base-jenkins-coverage-agent", "1C code coverage agent ${COVERAGE41C_VERSION} (swarm)")
  cache_from = cache_from("base-jenkins-coverage-agent")
  cache_to = cache_to("base-jenkins-coverage-agent")
}
