# pyright: reportUndefinedVariable=false

files(name="context", sources=["entrypoint.sh", "logcfg.xml"])

for platform_version in PLATFORM_VERSIONS:
    docker_image(
        name=f"onec-server-{platform_version}",
        source="Containerfile",
        repository="onec-server",
        context_root=".",
        dependencies=[":context", "//distr:distr", "//scripts:installer", "//installer:onec-installer"],
        extra_build_args=[
            f"ONEC_VERSION={platform_version}",
            f"NLS_ENABLED={env('NLS_ENABLED', 'false')}",
        ],
        secrets={"secrets_env": "secrets.env"},
        image_tags=[platform_version]
            + ([f"{platform_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
            + (["latest"] if docker_publish_latest() == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise server"),
        **cache_args(docker_cache_prefix(), "onec-server"),
    )
