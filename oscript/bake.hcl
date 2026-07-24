target "oscript" {
  inherits = ["_defaults"]
  dockerfile = "oscript/Dockerfile"
  args = {
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("oscript", ONESCRIPT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "OneScript runtime"
    "org.opencontainers.image.version" = ONESCRIPT_VERSION
  }
  description = jsonencode({"image" = "oscript"})
  cache_from = cache_from("oscript")
  cache_to = cache_to("oscript")
}

target "oscript-jdk" {
  inherits = ["_defaults"]
  dockerfile = "oscript/Dockerfile"
  contexts = {
    "eclipse-temurin:17-jdk-resolute" = "docker-image://eclipse-temurin:17-jdk-resolute"
  }
  args = {
    BASE_IMAGE = "eclipse-temurin:${OPENJDK_VERSION}-jdk-resolute"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("oscript-jdk", ONESCRIPT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "OneScript + OpenJDK"
    "org.opencontainers.image.version" = ONESCRIPT_VERSION
  }
  description = jsonencode({"image" = "oscript-jdk"})
  cache_from = cache_from("oscript-jdk")
  cache_to = cache_to("oscript-jdk")
}

target "oscript-jdk-s6" {
  inherits = ["_defaults"]
  dockerfile = "s6-overlay/Dockerfile"
  contexts = {
    "localhost/oscript-jdk:local" = "target:oscript-jdk"
  }
  args = {
    BASE_IMAGE = "localhost/oscript-jdk:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("oscript-jdk-s6", ONESCRIPT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "OneScript + OpenJDK + s6 overlay"
    "org.opencontainers.image.version" = ONESCRIPT_VERSION
  }
  description = jsonencode({"image" = "oscript-jdk-s6"})
  cache_from = cache_from("oscript-jdk-s6")
  cache_to = cache_to("oscript-jdk-s6")
}

target "client-vnc-oscript" {
  inherits = ["_defaults"]
  dockerfile = "oscript/Dockerfile"
  contexts = {
    "localhost/onec-client-vnc:local" = "target:client-vnc"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc:local"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("onec-client-vnc-oscript", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise client + OneScript"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client-vnc-oscript"})
  cache_from = cache_from("onec-client-vnc-oscript")
  cache_to = cache_to("onec-client-vnc-oscript")
}
