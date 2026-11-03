services:
  pcloud:
    build: .
    restart: always
    ports:
      - "8080:8080"
    environment:
      CLOUD_USER: admin
      CLOUD_PASSWORD: "${CLOUD_PASSWORD}"
    volumes:
      - /mnt/bigdisk/pcloud:/data   # katta diskni shu yerga ulang
