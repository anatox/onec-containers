target "oscript" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  args = {
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("oscript", ONESCRIPT_VERSION)
  labels = labels("oscript", "OneScript ${ONESCRIPT_VERSION} runtime")
  cache_from = cache_from("oscript")
  cache_to = cache_to("oscript")
}

target "installer" {
  dockerfile = "installer/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    YARD_VERSION = "${YARD_VERSION}"
  }
  tags = tags("onec-installer", YARD_VERSION)
  labels = labels("onec-installer", "1C installer toolchain ${YARD_VERSION}")
  cache_from = cache_from("onec-installer")
  cache_to = cache_to("onec-installer")
}

target "oscript-jdk" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  contexts = {
    "eclipse-temurin:17-jdk-resolute" = "eclipse-temurin:17-jdk-resolute"
  }
  args = {
    BASE_IMAGE = "eclipse-temurin:${OPENJDK_VERSION}-jdk-resolute"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
  }
  tags = tags("oscript-jdk", ONESCRIPT_VERSION)
  labels = merge(labels("oscript-jdk", "OneScript ${ONESCRIPT_VERSION} on OpenJDK ${OPENJDK_VERSION}"), {
    "onec.skip-publish" = "true"
  })
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
  }
  tags = tags("oscript-jdk-s6", ONESCRIPT_VERSION)
  labels = merge(labels("oscript-jdk-s6", "s6 overlay on oscript-jdk ${ONESCRIPT_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("oscript-jdk-s6")
  cache_to = cache_to("oscript-jdk-s6")
}
