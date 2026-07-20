target "base-jenkins-agent-k8s" {
  inherits = ["_defaults"]
  dockerfile = "k8s-jenkins-agent/Dockerfile"
  contexts = {
    "localhost/test-utils:local" = "target:test-utils"
  }
  args = {
    BASE_IMAGE = "localhost/test-utils:local"
    JENKINS_REMOTING_VERSION = "${JENKINS_REMOTING_VERSION}"
  }
  tags = tags_suffixed("onec-jenkins-agent", ONEC_VERSION, "k8s")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Jenkins agent"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-jenkins-agent"})
  cache_from = cache_from("onec-jenkins-agent")
  cache_to = cache_to("onec-jenkins-agent")
}

target "edt-agent-k8s" {
  inherits = ["_defaults"]
  dockerfile = "k8s-jenkins-agent/Dockerfile"
  contexts = {
    "localhost/edt-s6:local" = "target:edt-s6"
  }
  args = {
    BASE_IMAGE = "localhost/edt-s6:local"
    JENKINS_REMOTING_VERSION = "${JENKINS_REMOTING_VERSION}"
  }
  tags = tags_suffixed("edt-agent", EDT_VERSION, "k8s")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Development Tools Jenkins agent"
    "org.opencontainers.image.version" = EDT_VERSION
  }
  description = jsonencode({"image" = "edt-agent"})
  cache_from = cache_from("edt-agent")
  cache_to = cache_to("edt-agent")
}

target "oscript-jenkins-agent-k8s" {
  inherits = ["_defaults"]
  dockerfile = "k8s-jenkins-agent/Dockerfile"
  contexts = {
    "localhost/oscript-jdk-s6:local" = "target:oscript-jdk-s6"
  }
  args = {
    BASE_IMAGE = "localhost/oscript-jdk-s6:local"
    JENKINS_REMOTING_VERSION = "${JENKINS_REMOTING_VERSION}"
  }
  tags = tags_suffixed("oscript-jenkins-agent", ONESCRIPT_VERSION, "k8s")
  labels = {
    "org.opencontainers.image.title" = "OneScript Jenkins agent (k8s)"
    "org.opencontainers.image.version" = ONESCRIPT_VERSION
  }
  description = jsonencode({"image" = "oscript-jenkins-agent"})
  cache_from = cache_from("oscript-jenkins-agent")
  cache_to = cache_to("oscript-jenkins-agent")
}
