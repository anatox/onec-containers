target "installer" {
  inherits = ["_defaults"]
  dockerfile = "installer/Dockerfile"
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    YARD_VERSION = "${YARD_VERSION}"
  }
  tags = tags("onec-installer", YARD_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise installer toolchain"
    "org.opencontainers.image.version" = YARD_VERSION
  }
  description = jsonencode({"image" = "onec-installer", "extra-srcs" = ["scripts/installer"]})
  cache_from = cache_from("onec-installer")
  cache_to = cache_to("onec-installer")
}
