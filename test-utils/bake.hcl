target "client-vnc-oscript-jdk" {
  dockerfile = "jdk/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-vnc-oscript:local" = "target:client-vnc-oscript"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript:local"
    OPENJDK_VERSION = "${OPENJDK_VERSION}"
  }
  tags = tags("onec-client-vnc-oscript-jdk", ONEC_VERSION)
  labels = labels("onec-client-vnc-oscript-jdk", ONEC_VERSION, "1C:Enterprise VNC client + OneScript + JDK")
  description = jsonencode({"extra-srcs" = ["scripts/remove-dst-root-ca-x3.sh"]})
  cache_from = cache_from("onec-client-vnc-oscript-jdk")
  cache_to = cache_to("onec-client-vnc-oscript-jdk")
}

target "test-utils" {
  dockerfile = "test-utils/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-vnc-oscript-jdk:local" = "target:client-vnc-oscript-jdk"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-vnc-oscript-jdk:local"
    TEST_UTILS_EXTRA_PACKAGES = "${TEST_UTILS_EXTRA_PACKAGES}"
  }
  tags = tags("test-utils", ONEC_VERSION)
  labels = labels("test-utils", ONEC_VERSION, "Vanessa test utils")
  cache_from = cache_from("test-utils")
  cache_to = cache_to("test-utils")
}
