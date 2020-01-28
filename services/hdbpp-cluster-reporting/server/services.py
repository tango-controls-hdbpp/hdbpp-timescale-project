# -----------------------------------------------------------------------------
# This file is part of the hdbpp-timescale-project
#
# Copyright (C) : 2014-2019
#   European Synchrotron Radiation Facility
#   BP 220, Grenoble 38043, FRANCE
#
# hdbpp-timescale-project is free software: you can redistribute it and/or modify
# it under the terms of the Lesser GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# hdbpp-timescale-project is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser
# GNU General Public License for more details.
#
# You should have received a copy of the Lesser GNU General Public License
# along with hdbpp-timescale-project.  If not, see <http://www.gnu.org/licenses/>.
# -----------------------------------------------------------------------------

import copy
import requests
import logging
import atexit

import server.config as config

from server import db as db
from server.models import Servers
from threading import Lock
from requests.exceptions import HTTPError
from apscheduler.schedulers.background import BackgroundScheduler

logger = logging.getLogger(config.LOGGER_NAME)

scheduler = None

def update_cluster_status(configuration):
    """
    Update the status of each server in the cluster, and store it in
    the database. Any server that  can not be contacted is given an error
    or unknown status.

    Arguments:
        configuration : dict -- Server configuration
    """

    for host in configuration["cluster"]["hosts"]:
        role = config.SERVER_ROLE_UNKNOWN
        state = config.CONNECTION_STATE_UNKNOWN

        try:
            # attempt to contact the server and gets it config
            response = requests.get("http://{}:{}/patroni".format(host, configuration["cluster"]["patroni_port"]))

            # If the response was successful, no Exception will be raised
            response.raise_for_status()

            # valid response received
            if response.status_code == 200:
                if "role" in response.json():
                    role = response.json()["role"]
                else:
                    logger.error(
                        "Response did not contain a role for the host, please check the cluster")

                if "state" in response.json():
                    state = response.json()["state"]
                else:
                    logger.error(
                        "Response did not contain a state for the host, please check the cluster")

        except HTTPError as http_err:
            logger.error(
                "HTTP error occurred contacting: {}. Error: {}".format(host, http_err))

            state = config.CONNECTION_STATE_ERROR

        except Exception as err:
            logger.error(
                "An error occurred contacting: {}. Error: {}".format(host, err))

            state = config.CONNECTION_STATE_ERROR

        db.session.query(Servers).filter(
            Servers.hostname == host).update({"role": role, "state": state})

        db.session.commit()

    logger.debug("Updated cluster server status with data from the cluster")


def create_scheduler():
    global scheduler

    # create a simple background scheduler
    scheduler = BackgroundScheduler()
    scheduler.start()
    return scheduler


def init_services(configuration):
    from server.models import Servers

    # clear the cluster status and reset with defaults
    db.session.query(Servers).delete()
    db.session.commit()

    # add the defaults
    for host in configuration["cluster"]["hosts"]:
        server = Servers(host, "unknown", "unknown")
        db.session.add(server)
        db.session.commit()

    global scheduler
    scheduler = create_scheduler()

    # shut down the scheduler when exiting the app
    atexit.register(lambda: scheduler.shutdown())

    # now schedule a job to update it at intervals
    scheduler.add_job(
        update_cluster_status,
        'interval',
        args=[configuration],
        id='servers',
        replace_existing=True,
        seconds=int(configuration["cluster"]["status_update"]))
