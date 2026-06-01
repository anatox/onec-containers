FROM oscript:2.0.2
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

ARG runner_ver=1.7.0

RUN <<EOF
  set -eux
  opm install vanessa-runner@$runner_ver
  sed -i 's/#Использовать JSON/#Использовать json/g' \
    /usr/share/oscript/lib/vanessa-runner/src/Модули/ГенерацияОтчетов.os
EOF

ENTRYPOINT ["runner"]
CMD ["help"]
