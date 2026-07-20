target "installer" {
  dockerfile = "installer/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    YARD_VERSION = "${YARD_VERSION}"
  }
  tags = tags("onec-installer", YARD_VERSION)
  labels = labels("onec-installer", "1C installer toolchain ${YARD_VERSION}")
  description = jsonencode({"extra-srcs" = ["scripts/installer"]})
  cache_from = cache_from("onec-installer")
  cache_to = cache_to("onec-installer")
}
