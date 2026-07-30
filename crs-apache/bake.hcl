target "crs-apache" {
  inherits = ["_defaults"]
  dockerfile = "crs-apache/Dockerfile"
  contexts = {
    "localhost/onec-crs:local" = "target:crs"
  }
  tags = tags("onec-crs-apache", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise CRS+Apache"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-crs-apache"})
  cache_from = cache_from("onec-crs-apache")
  cache_to = cache_to("onec-crs-apache")
}
