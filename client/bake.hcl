target "client" {
  inherits = ["_defaults"]
  target = "client"
  dockerfile = "client/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-client", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise thick client"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client"})
  cache_from = cache_from("onec-client")
  cache_to = cache_to("onec-client")
}

target "client-toolbox" {
  inherits = ["_defaults"]
  target = "toolbox"
  dockerfile = "client/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    BASE_IMAGE = "quay.io/toolbx/ubuntu-toolbox:26.04"
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-client-toolbox", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise client toolbox"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client-toolbox", "extra-srcs" = ["scripts/distrobox-shims.sh", "client/configs"]})
  cache_from = cache_from("onec-client-toolbox")
  cache_to = cache_to("onec-client-toolbox")
}

target "client-s6" {
  inherits = ["_defaults"]
  dockerfile = "s6-overlay/Dockerfile"
  contexts = {
    "localhost/onec-client:local" = "target:client"
  }
  args = {
    BASE_IMAGE = "localhost/onec-client:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("onec-client-s6", ONEC_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise client + s6 overlay"
    "org.opencontainers.image.version" = ONEC_VERSION
  }
  description = jsonencode({"image" = "onec-client-s6"})
  cache_from = cache_from("onec-client-s6")
  cache_to = cache_to("onec-client-s6")
}
