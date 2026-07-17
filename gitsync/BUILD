# pyright: reportUndefinedVariable=false

docker_image(
    name="gitsync",
    source="Containerfile",
    repository="gitsync",
    context_root=".",
    dependencies=[f"//client:onec-client-{max(PLATFORM_VERSIONS)}", "//oscript:oscript"],
    extra_build_args=[
        f"CLIENT_IMAGE=client:onec-client-{max(PLATFORM_VERSIONS)}",
        f"gitsync_ver={GITSYNC_VERSION}",
    ],
    image_tags=[GITSYNC_VERSION]
        + ([f"{GITSYNC_VERSION}-g{git_sha_short()}"] if git_sha_short() else ["local"])
        + (["latest"] if docker_publish_latest() == "true" else []),
    image_labels=std_labels("GitSync"),
    **cache_args(docker_cache_prefix(), "gitsync"),
)
