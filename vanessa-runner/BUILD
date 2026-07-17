# pyright: reportUndefinedVariable=false

docker_image(
    name="runner",
    source="Containerfile",
    repository="vanessa-runner",
    context_root=".",
    dependencies=["//oscript:oscript"],
    extra_build_args=[f"runner_ver={VANESSA_RUNNER_VERSION}"],
    image_tags=[VANESSA_RUNNER_VERSION]
        + ([f"{VANESSA_RUNNER_VERSION}-g{git_sha_short()}"] if git_sha_short() else ["local"])
        + (["latest"] if docker_publish_latest() == "true" else []),
    image_labels=std_labels("Vanessa Runner"),
    **cache_args(docker_cache_prefix(), "vanessa-runner"),
)
