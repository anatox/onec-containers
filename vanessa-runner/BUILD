# pyright: reportUndefinedVariable=false

docker_image(
    name="runner",
    source="Containerfile",
    repository="vanessa-runner",
    context_root=".",
    dependencies=["//oscript:oscript"],
    extra_build_args=[f"runner_ver={VANESSA_RUNNER_VERSION}"],
    image_tags=[VANESSA_RUNNER_VERSION]
        + ([f"{VANESSA_RUNNER_VERSION}-g{GIT_SHA_SHORT}"] if GIT_SHA_SHORT else ["local"])
        + (["latest"] if PUBLISH_LATEST == "true" else []),
    image_labels=std_labels("Vanessa Runner"),
    **cache_args(CACHE_PREFIX, "vanessa-runner"),
)
