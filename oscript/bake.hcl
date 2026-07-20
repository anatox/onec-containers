target "oscript" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  args = {
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("oscript", ONESCRIPT_VERSION)
  labels = labels("oscript", ONESCRIPT_VERSION, "OneScript runtime")
  cache_from = cache_from("oscript")
  cache_to = cache_to("oscript")
}

target "oscript-jdk" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  contexts = {
    "eclipse-temurin:17-jdk-resolute" = "docker-image://eclipse-temurin:17-jdk-resolute"
  }
  args = {
    BASE_IMAGE = "eclipse-temurin:${OPENJDK_VERSION}-jdk-resolute"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("oscript-jdk", ONESCRIPT_VERSION)
  labels = labels("oscript-jdk", ONESCRIPT_VERSION, "OneScript + OpenJDK")
  cache_from = cache_from("oscript-jdk")
  cache_to = cache_to("oscript-jdk")
}

target "oscript-jdk-s6" {
  dockerfile = "s6-overlay/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript-jdk:local" = "target:oscript-jdk"
  }
  args = {
    BASE_IMAGE = "localhost/oscript-jdk:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("oscript-jdk-s6", ONESCRIPT_VERSION)
  labels = labels("oscript-jdk-s6", ONESCRIPT_VERSION, "OneScript + OpenJDK + s6 overlay")
  cache_from = cache_from("oscript-jdk-s6")
  cache_to = cache_to("oscript-jdk-s6")
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
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("onec-client-vnc-oscript", ONEC_VERSION)
  labels = labels("onec-client-vnc-oscript", ONEC_VERSION, "1C:Enterprise client + OneScript")
  cache_from = cache_from("onec-client-vnc-oscript")
  cache_to = cache_to("onec-client-vnc-oscript")
}
