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
  labels = labels("test-utils", "Vanessa test utils for 1C agent ${ONEC_VERSION}")
  cache_from = cache_from("test-utils")
  cache_to = cache_to("test-utils")
}
