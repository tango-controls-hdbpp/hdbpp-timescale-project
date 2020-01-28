FROM python:3-slim

LABEL maintainer="stuart.james@esrf.fr"

RUN mkdir -p /etc/hdb
RUN mkdir -p /usr/src/app
RUN mkdir -p /var/lib/hdbpp-cluster-reporting
WORKDIR /usr/src/app

# copy the various parts of the server across, including a basic config file
COPY build-files/requirements.txt ./
COPY build-files/setup/hdbpp_cluster_reporting.conf /etc/hdb/hdbpp_cluster_reporting.conf
COPY build-files/app/ ./

RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="$PYTHONPATH:/usr/src/app"
ENV DATABASE_URL="sqlite:////var/lib/hdbpp-cluster-reporting/reporting.db"

# the config file should be mounted if the user wants to customise it
CMD [ "/usr/src/app/run_server.py", "-c", "/etc/hdb/hdbpp_cluster_reporting.conf" ]
