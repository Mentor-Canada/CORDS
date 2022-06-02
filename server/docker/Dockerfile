# https://github.com/FNNDSC/ubuntu-python3/blob/master/Dockerfile
FROM ubuntu:latest

WORKDIR /srv
ADD . .

RUN apt-get update \
  && apt-get install -y python3-pip python3-dev libpq-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 --no-cache-dir install --upgrade pip \
  && rm -rf /var/lib/apt/lists/*

RUN apt update && apt install gunicorn -y
RUN pip3 install -r docker/requirements.txt

EXPOSE 8080:8080
CMD ["bash", "START.sh"]
