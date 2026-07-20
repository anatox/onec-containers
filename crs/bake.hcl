target "crs" {
  dockerfile = "crs/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    GOSU_VERSION = "${GOSU_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("crs", ONEC_VERSION)
  labels = labels("crs", "1C:Enterprise CRS ${ONEC_VERSION}")
  cache_from = cache_from("crs")
  cache_to = cache_to("crs")
}
