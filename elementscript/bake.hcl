target "elementscript" {
  inherits = ["_defaults"]
  dockerfile = "elementscript/Dockerfile"
  args = {
    ELEMENTSCRIPT_VERSION = "${ELEMENTSCRIPT_VERSION}"
  }
  secret = ["id=elementscript_download_token,env=ELEMENTSCRIPT_DOWNLOAD_TOKEN"]
  tags = tags("onec-elementscript", ELEMENTSCRIPT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Element.Script"
    "org.opencontainers.image.version" = ELEMENTSCRIPT_VERSION
  }
  description = jsonencode({"image" = "onec-elementscript"})
  cache_from = cache_from("onec-elementscript")
  cache_to = cache_to("onec-elementscript")
}
