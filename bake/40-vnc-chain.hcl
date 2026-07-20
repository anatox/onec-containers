target "client-s6" {
  dockerfile = "s6-overlay/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client:local" = "target:client"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
  }
  tags = tags("onec-client-s6", ONEC_VERSION)
  labels = merge(labels("onec-client-s6", "s6 overlay on 1C client ${ONEC_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("onec-client-s6")
  cache_to = cache_to("onec-client-s6")
}

target "client-vnc" {
  dockerfile = "client-vnc/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-s6:local" = "target:client-s6"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-s6:local"
  }
  tags = tags("onec-client-vnc", ONEC_VERSION)
  labels = labels("onec-client-vnc", "1C:Enterprise VNC client ${ONEC_VERSION}")
  cache_from = cache_from("onec-client-vnc")
  cache_to = cache_to("onec-client-vnc")
}

target "client-vnc-oscript" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-vnc:local" = "target:client-vnc"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc:local"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
  }
  tags = tags("onec-client-vnc-oscript", ONEC_VERSION)
  labels = merge(labels("onec-client-vnc-oscript", "1C VNC client + oscript ${ONEC_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("onec-client-vnc-oscript")
  cache_to = cache_to("onec-client-vnc-oscript")
}

target "client-vnc-oscript-jdk" {
  dockerfile = "jdk/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-vnc-oscript:local" = "target:client-vnc-oscript"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript:local"
  }
  tags = tags("onec-client-vnc-oscript-jdk", ONEC_VERSION)
  labels = merge(labels("onec-client-vnc-oscript-jdk", "1C VNC client + oscript + JDK ${ONEC_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("onec-client-vnc-oscript-jdk")
  cache_to = cache_to("onec-client-vnc-oscript-jdk")
}

target "vanessa-automation" {
  dockerfile = "test-utils/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-vnc-oscript-jdk:local" = "target:client-vnc-oscript-jdk"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript-jdk:local"
    TEST_UTILS_EXTRA_PACKAGES = "${TEST_UTILS_EXTRA_PACKAGES}"
  }
  tags = tags("vanessa-automation", ONEC_VERSION)
  labels = merge(labels("vanessa-automation", "Vanessa test utils for 1C agent ${ONEC_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("vanessa-automation")
  cache_to = cache_to("vanessa-automation")
}
