target "client-vnc" {
  dockerfile = "client-vnc/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client-s6:local" = "target:client-s6"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client-s6:local"
  }
  tags = tags("onec-client-vnc", ONEC_VERSION)
  labels = labels("onec-client-vnc", ONEC_VERSION, "1C:Enterprise VNC client")
  cache_from = cache_from("onec-client-vnc")
  cache_to = cache_to("onec-client-vnc")
}
