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
  labels = labels("onec-client-vnc-oscript-jdk", "1C VNC client + oscript + JDK ${ONEC_VERSION}")
  description = jsonencode({"extra-srcs" = ["scripts/remove-dst-root-ca-x3.sh"]})
  cache_from = cache_from("onec-client-vnc-oscript-jdk")
  cache_to = cache_to("onec-client-vnc-oscript-jdk")
}
