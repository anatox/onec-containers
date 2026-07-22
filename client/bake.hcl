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
  labels = labels("onec-client", "1C:Enterprise thick client ${ONEC_VERSION}")
  cache_from = cache_from("onec-client")
  cache_to = cache_to("onec-client")
}

target "client-toolbox" {
  target = "toolbox"
  dockerfile = "client/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    BASE_IMAGE = "quay.io/toolbx/ubuntu-toolbox:26.04"
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("client-toolbox", ONEC_VERSION)
  labels = labels("client-toolbox", "1C:Enterprise client toolbox ${ONEC_VERSION}")
  description = jsonencode({"extra-srcs" = ["scripts/distrobox-shims.sh", "client/configs"]})
  cache_from = cache_from("client-toolbox")
  cache_to = cache_to("client-toolbox")
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
  labels = labels("onec-client-s6", "s6 overlay on 1C client ${ONEC_VERSION}")
  cache_from = cache_from("onec-client-s6")
  cache_to = cache_to("onec-client-s6")
}
