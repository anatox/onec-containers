target "executor" {
  inherits = ["_defaults"]
  dockerfile = "executor/Dockerfile"
  args = {
    EXECUTOR_VERSION = "${EXECUTOR_VERSION}"
  }
  secret = ["id=dev1c_executor_api_key,env=DEV1C_EXECUTOR_API_KEY"]
  tags = tags("executor", EXECUTOR_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Executor"
    "org.opencontainers.image.version" = EXECUTOR_VERSION
  }
  description = jsonencode({"image" = "executor"})
  cache_from = cache_from("executor")
  cache_to = cache_to("executor")
}
