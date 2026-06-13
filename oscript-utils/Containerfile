FROM oscript:2.0.2
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

RUN <<EOF
  set -eux
  opm install vanessa-runner
  opm install packman
  opm install gitsync
  opm install deployka
  opm install add
  opm install vanessa-automation
  # https://github.com/silverbulleters/vanessa-runner/pull/301
  sed -i 's/#Использовать JSON/#Использовать json/g' \
    /usr/share/oscript/lib/vanessa-runner/src/Модули/ГенерацияОтчетов.os
EOF
