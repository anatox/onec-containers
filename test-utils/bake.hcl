target "client-vnc-oscript-jdk" {
  inherits = ["_defaults"]
  dockerfile = "jdk/Dockerfile"
  contexts = {
    "localhost/onec-client-vnc-oscript:local" = "target:client-vnc-oscript"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript:local"
    OPENJDK_VERSION = "${OPENJDK_VERSION}"
  }
  tags = tags("onec-client-vnc-oscript-jdk", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise VNC client + OneScript + JDK"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client-vnc-oscript-jdk", "extra-srcs" = ["scripts/remove-dst-root-ca-x3.sh"]})
  cache_from = cache_from("onec-client-vnc-oscript-jdk")
  cache_to = cache_to("onec-client-vnc-oscript-jdk")
}

target "test-utils" {
  inherits = ["_defaults"]
  dockerfile = "test-utils/Dockerfile"
  contexts = {
    "localhost/onec-client-vnc-oscript-jdk:local" = "target:client-vnc-oscript-jdk"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript-jdk:local"
    TEST_UTILS_EXTRA_PACKAGES = "${TEST_UTILS_EXTRA_PACKAGES}"
  }
  tags = tags("test-utils", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "Vanessa test utils"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "test-utils"})
  cache_from = cache_from("test-utils")
  cache_to = cache_to("test-utils")
}
