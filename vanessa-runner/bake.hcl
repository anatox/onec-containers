target "vanessa-runner" {
  inherits = ["_defaults"]
  dockerfile = "vanessa-runner/Dockerfile"
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    VANESSA_RUNNER_VERSION = "${VANESSA_RUNNER_VERSION}"
  }
  tags = tags("vanessa-runner", VANESSA_RUNNER_VERSION)
  labels = {
    "org.opencontainers.image.title" = "Vanessa Runner"
    "org.opencontainers.image.version" = VANESSA_RUNNER_VERSION
  }
  description = jsonencode({"image" = "vanessa-runner"})
  cache_from = cache_from("vanessa-runner")
  cache_to = cache_to("vanessa-runner")
}
