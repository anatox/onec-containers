target "base-jenkins-agent" {
  name = "base-jenkins-agent-${flavor}"
  matrix = { flavor = ["k8s", "swarm"] }
  dockerfile = "${flavor}-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/vanessa-automation:local" = "target:vanessa-automation"
  }
  args = {
    BASE_IMAGE = "localhost/vanessa-automation:local"
  }
  tags = tags("base-jenkins-agent-${flavor}", ONEC_VERSION)
  labels = labels("base-jenkins-agent-${flavor}", "1C base Jenkins agent (${flavor}) ${ONEC_VERSION}")
  cache_from = cache_from("base-jenkins-agent-${flavor}")
  cache_to = cache_to("base-jenkins-agent-${flavor}")
}

target "edt-agent" {
  name = "edt-agent-${flavor}"
  matrix = { flavor = ["k8s", "swarm"] }
  dockerfile = "${flavor}-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt-s6:local" = "target:edt-s6"
  }
  args = {
    BASE_IMAGE = "localhost/edt-s6:local"
  }
  tags = tags("edt-agent-${flavor}", EDT_VERSION)
  labels = labels("edt-agent-${flavor}", "EDT Jenkins agent (${flavor}) ${EDT_VERSION}")
  cache_from = cache_from("edt-agent-${flavor}")
  cache_to = cache_to("edt-agent-${flavor}")
}

target "oscript-agent" {
  name = "oscript-agent-${flavor}"
  matrix = { flavor = ["k8s", "swarm"] }
  dockerfile = "${flavor}-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript-jdk-s6:local" = "target:oscript-jdk-s6"
  }
  args = {
    BASE_IMAGE = "localhost/oscript-jdk-s6:local"
  }
  tags = tags("oscript-agent-${flavor}", ONESCRIPT_VERSION)
  labels = labels("oscript-agent-${flavor}", "OneScript Jenkins agent (${flavor}) ${ONESCRIPT_VERSION}")
  cache_from = cache_from("oscript-agent-${flavor}")
  cache_to = cache_to("oscript-agent-${flavor}")
}

target "coverage-agent" {
  name = "coverage-agent-${flavor}"
  matrix = { flavor = ["k8s", "swarm"] }
  dockerfile = "coverage41C/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt:local" = "target:edt"
    "localhost/base-jenkins-agent-${flavor}:local" = "target:base-jenkins-agent-${flavor}"
  }
  args = {
    BASE_IMAGE = "localhost/base-jenkins-agent-${flavor}:local"
    COVERAGE41C_VERSION = "${COVERAGE41C_VERSION}"
  }
  tags = tags("base-jenkins-coverage-agent-${flavor}", COVERAGE41C_VERSION)
  labels = labels("base-jenkins-coverage-agent-${flavor}", "1C code coverage agent (${flavor}) ${COVERAGE41C_VERSION}")
  cache_from = cache_from("base-jenkins-coverage-agent-${flavor}")
  cache_to = cache_to("base-jenkins-coverage-agent-${flavor}")
}
