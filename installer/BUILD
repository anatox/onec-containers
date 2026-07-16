# pyright: reportUndefinedVariable=false

files(name="context", sources=["entrypoint.sh"])

docker_image(
    name="onec-installer",
    source="Containerfile",
    dependencies=[":context", "//scripts:installer", "//oscript:oscript"],
    extra_build_args=[
        f"YARD_VERSION={YARD_VERSION}",
    ],
    image_tags=[YARD_VERSION, "local"],
    image_labels=std_labels("1C installer helper"),
    skip_push=True,
)
