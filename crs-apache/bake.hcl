target "crs-apache" {
  dockerfile = "crs-apache/Dockerfile"
  context = "."
  contexts = {
    "localhost/crs:local" = "target:crs"
  }
  tags = tags("crs-apache", ONEC_VERSION)
  labels = labels("crs-apache", ONEC_VERSION, "1C:Enterprise CRS+Apache")
  cache_from = cache_from("crs-apache")
  cache_to = cache_to("crs-apache")
}
