ARG BASE_IMAGE=localhost/oscript:local

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu), \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG VANESSA_RUNNER_VERSION

RUN <<'EOF'
  set -eux
  opm install vanessa-runner@$VANESSA_RUNNER_VERSION
  # https://github.com/silverbulleters/vanessa-runner/pull/301
  sed -i 's/#Использовать JSON/#Использовать json/g' \
    "${OSCRIPT_HOME}/lib/vanessa-runner/src/Модули/ГенерацияОтчетов.os"
EOF

ENTRYPOINT ["runner"]
CMD ["help"]
