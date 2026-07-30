target "client-vnc" {
  inherits = ["_defaults"]
  dockerfile = "client-vnc/Dockerfile"
  contexts = {
    "localhost/onec-client-s6:local" = "target:client-s6"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-s6:local"
  }
  tags = tags("onec-client-vnc", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise VNC client"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client-vnc"})
  cache_from = cache_from("onec-client-vnc")
  cache_to = cache_to("onec-client-vnc")
}
