FROM python:3-slim

# built with help from this thread:
# https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container/46220104#46220104
LABEL maintainer="stuart.james@esrf.fr"

RUN mkdir -p /etc/hdb
RUN mkdir -p /usr/src/service
WORKDIR /usr/src/service

# copy the various parts of the server across, including a basic config file
COPY build-files/requirements.txt build-files/hdbpp_reorder_chunks.py ./ 
COPY build-files/setup/hdbpp_reorder_chunks.conf /etc/hdb/hdbpp_reorder_chunks.conf
COPY build-files/setup/hdbpp_reorder_chunks_docker /etc/cron.d/hdbpp_reorder_chunks
     
RUN chmod 0644 /etc/cron.d/hdbpp_reorder_chunks

# python requirements setup
RUN pip install --no-cache-dir -r requirements.txt
ENV PYTHONPATH="$PYTHONPATH:/usr/src/service"

# setup cron
RUN apt-get update && \
    apt-get -y install cron && \
    rm -rf /var/lib/apt/lists/*

# Run cron in the foreground
CMD ["cron", "-f"]
