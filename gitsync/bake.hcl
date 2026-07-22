target "client-oscript" {
  dockerfile = "oscript/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client:local" = "target:client"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("onec-client-oscript", "${ONESCRIPT_VERSION}-client${ONEC_VERSION}")
  labels = labels("onec-client-oscript", "1C client ${ONEC_VERSION} + oscript ${ONESCRIPT_VERSION}")
  cache_from = cache_from("onec-client-oscript")
  cache_to = cache_to("onec-client-oscript")
}

target "gitsync" {
  dockerfile = "gitsync/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client:local" = "target:client-oscript"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    GITSYNC_VERSION = "${GITSYNC_VERSION}"
  }
  tags = tags("gitsync", "${GITSYNC_VERSION}-client${ONEC_VERSION}")
  labels = labels("gitsync", "GitSync ${GITSYNC_VERSION} on client ${ONEC_VERSION}")
  cache_from = cache_from("gitsync")
  cache_to = cache_to("gitsync")
}
