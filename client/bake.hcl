target "client" {
  target = "client"
  dockerfile = "client/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-client", ONEC_VERSION)
  labels = labels("onec-client", ONEC_VERSION, "1C:Enterprise thick client")
  cache_from = cache_from("onec-client")
  cache_to = cache_to("onec-client")
}

target "client-s6" {
  dockerfile = "s6-overlay/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client:local" = "target:client"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("onec-client-s6", ONEC_VERSION)
  labels = labels("onec-client-s6", ONEC_VERSION, "1C:Enterprise client + s6 overlay")
  cache_from = cache_from("onec-client-s6")
  cache_to = cache_to("onec-client-s6")
}
