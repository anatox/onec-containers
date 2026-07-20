target "executor" {
  dockerfile = "executor/Dockerfile"
  context = "."
  args = {
    EXECUTOR_VERSION = "${EXECUTOR_VERSION}"
  }
  secret = ["id=dev1c_executor_api_key,env=DEV1C_EXECUTOR_API_KEY"]
  tags = tags("executor", EXECUTOR_VERSION)
  labels = labels("executor", EXECUTOR_VERSION, "1C:Executor")
  cache_from = cache_from("executor")
  cache_to = cache_to("executor")
}
