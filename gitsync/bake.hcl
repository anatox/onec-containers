target "client-oscript" {
  inherits = ["_defaults"]
  dockerfile = "oscript/Dockerfile"
  contexts = {
    "localhost/onec-client:local" = "target:client"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    ONESCRIPT_VERSION = "${ONESCRIPT_VERSION}"
    OVM_VERSION = "${OVM_VERSION}"
  }
  tags = tags("onec-client-oscript", "${ONESCRIPT_VERSION}-client${ONEC_VERSION}")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise client + OneScript"
    "org.opencontainers.image.version" = "${ONESCRIPT_VERSION}-client${ONEC_VERSION}"
  }
  description = jsonencode({"image" = "onec-client-oscript"})
  cache_from = cache_from("onec-client-oscript")
  cache_to = cache_to("onec-client-oscript")
}

target "gitsync" {
  inherits = ["_defaults"]
  dockerfile = "gitsync/Dockerfile"
  contexts = {
    "localhost/onec-client:local" = "target:client-oscript"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    GITSYNC_VERSION = "${GITSYNC_VERSION}"
  }
  tags = tags("gitsync", "${GITSYNC_VERSION}-client${ONEC_VERSION}")
  labels = {
    "org.opencontainers.image.title" = "GitSync + 1C:Enterprise client"
    "org.opencontainers.image.version" = "${GITSYNC_VERSION}-client${ONEC_VERSION}"
  }
  description = jsonencode({"image" = "gitsync"})
  cache_from = cache_from("gitsync")
  cache_to = cache_to("gitsync")
}
