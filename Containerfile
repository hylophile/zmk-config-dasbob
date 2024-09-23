ARG zmk_shield
FROM ${zmk_shield}_firmware_prepare

WORKDIR /app/zmk/app
COPY ./config /app/config

RUN west build --cmake

RUN cp /app/zmk/app/build/zephyr/zmk.uf2 /app/zmk.uf2

ENTRYPOINT ["bash"]
