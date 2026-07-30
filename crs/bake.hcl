target "crs" {
  inherits = ["_defaults"]
  dockerfile = "crs/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    GOSU_VERSION = "${GOSU_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-crs", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise CRS"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-crs"})
  cache_from = cache_from("onec-crs")
  cache_to = cache_to("onec-crs")
}
