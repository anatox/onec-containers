target "server" {
  dockerfile = "server/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    GOSU_VERSION = "${GOSU_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-server", ONEC_VERSION)
  labels = labels("onec-server", ONEC_VERSION, "1C:Enterprise server")
  cache_from = cache_from("onec-server")
  cache_to = cache_to("onec-server")
}
