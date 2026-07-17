# pyright: reportUndefinedVariable=false

files(name="context", sources=["1crs.conf", "repo.1ccr", "entrypoint.sh"])

for platform_version in PLATFORM_VERSIONS:
    docker_image(
        name=f"onec-crs-apache-{platform_version}",
        source="Containerfile",
        repository="onec-crs-apache",
        context_root=".",
        dependencies=[":context", f"//crs:onec-crs-{platform_version}"],
        extra_build_args=[f"BASE_IMAGE=crs:onec-crs-{platform_version}"],
        image_tags=[platform_version]
            + ([f"{platform_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
            + (["latest"] if docker_publish_latest() == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise CRS with Apache"),
        **cache_args(docker_cache_prefix(), "onec-crs-apache"),
    )
