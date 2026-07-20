target "thin-client" {
  inherits = ["_defaults"]
  dockerfile = "thin-client/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags_suffixed("onec-client", ONEC_VERSION, "thin")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise thin client"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client"})
  cache_from = cache_from("onec-client")
  cache_to = cache_to("onec-client")
}
