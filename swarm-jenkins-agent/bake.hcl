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
  labels = labels("base-jenkins-agent", ONEC_VERSION, "1C:Enterprise Jenkins agent")
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
  labels = labels("edt-agent", EDT_VERSION, "1C:Enterprise Development Tools Jenkins agent")
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
  labels = labels("oscript-agent", ONESCRIPT_VERSION, "OneScript Jenkins agent (swarm)")
  cache_from = cache_from("oscript-agent")
  cache_to = cache_to("oscript-agent")
}
