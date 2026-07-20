target "base-jenkins-agent-swarm" {
  dockerfile = "swarm-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/test-utils:local" = "target:test-utils"
  }
  args = {
    BASE_IMAGE = "localhost/test-utils:local"
  }
  tags = agent_tags("base-jenkins-agent", ONEC_VERSION, "swarm")
  labels = labels("base-jenkins-agent", "1C base Jenkins agent ${ONEC_VERSION} (swarm)")
  cache_from = cache_from("base-jenkins-agent")
  cache_to = cache_to("base-jenkins-agent")
}

target "edt-agent-swarm" {
  dockerfile = "swarm-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt-s6:local" = "target:edt-s6"
  }
  args = {
    BASE_IMAGE = "localhost/edt-s6:local"
  }
  tags = agent_tags("edt-agent", EDT_VERSION, "swarm")
  labels = labels("edt-agent", "EDT Jenkins agent ${EDT_VERSION} (swarm)")
  cache_from = cache_from("edt-agent")
  cache_to = cache_to("edt-agent")
}

target "oscript-agent-swarm" {
  dockerfile = "swarm-jenkins-agent/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript-jdk-s6:local" = "target:oscript-jdk-s6"
  }
  args = {
    BASE_IMAGE = "localhost/oscript-jdk-s6:local"
  }
  tags = agent_tags("oscript-agent", ONESCRIPT_VERSION, "swarm")
  labels = labels("oscript-agent", "OneScript Jenkins agent ${ONESCRIPT_VERSION} (swarm)")
  cache_from = cache_from("oscript-agent")
  cache_to = cache_to("oscript-agent")
}
