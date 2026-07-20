target "thin-client" {
  dockerfile = "thin-client/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("thin-client", ONEC_VERSION)
  labels = labels("thin-client", ONEC_VERSION, "1C:Enterprise thin client")
  cache_from = cache_from("thin-client")
  cache_to = cache_to("thin-client")
}
