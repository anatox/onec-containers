# pyright: reportUndefinedVariable=false

docker_image(
    name=f"executor-{EXECUTOR_VERSION}",
    source="Containerfile",
    repository="executor",
    context_root=".",
    extra_build_args=[f"EXECUTOR_VERSION={EXECUTOR_VERSION}"],
    secrets={"secrets_env": "secrets.env"},
    image_tags=[EXECUTOR_VERSION]
        + ([f"{EXECUTOR_VERSION}-g{git_sha_short()}"] if git_sha_short() else ["local"])
        + (["latest"] if docker_publish_latest() == "true" else []),
    image_labels=std_labels("1C:Executor"),
    **cache_args(docker_cache_prefix(), "executor"),
)
