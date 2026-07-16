# pyright: reportUndefinedVariable=false

files(name="context", sources=["entrypoint.sh"])

docker_image(
    name="oscript",
    source="Containerfile",
    dependencies=[":context"],
    extra_build_args=[
        f"ONESCRIPT_VERSION={ONESCRIPT_VERSION}",
    ],
    image_tags=[ONESCRIPT_VERSION, "local"],
    image_labels=std_labels("OneScript runtime"),
    skip_push=True,
)
