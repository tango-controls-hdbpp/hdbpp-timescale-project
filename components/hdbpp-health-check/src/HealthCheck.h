// Copyright (C) : 2014-2017
// European Synchrotron Radiation Facility
// BP 220, Grenoble 38043, FRANCE
//
// This file is part of HdbppHealthCheck
//
// HdbppHealthCheck is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// HdbppHealthCheck is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser
// GNU General Public License for more details.
//
// You should have received a copy of the Lesser GNU General Public License
// along with HdbppHealthCheck.  If not, see <http://www.gnu.org/licenses/>.

#ifndef _HEALTH_CHECK_H
#define _HEALTH_CHECK_H

#include <vector>
#include <string>
#include <tuple>

namespace HdbppHealthCheck_ns
{
// Error/Warning messages for issues relating to contacting the rest server
const std::string invalid_response = "Invalid response when contacting the reporting server. "
    "Ensure RestAPI configuration is correct.";

const std::string no_reponse = "Unable to contact database cluster reporting server, "
    "please check reporting server is running.";

// Host/software state responses
const std::string server_no_errors = "No database cluster server/software errors reported.";

const std::string server_warning = "The database cluster is reporting a warning for the physical servers "
    "and/or the server software. Please check all servers and related software is running and configured correctly.";

const std::string server_error = "The database cluster is reporting an error in either the physical servers or the "
    "operating software. The error may signal crashed servers or failed operating software that needs a rapid "
    "diagnosis or investigation";

const std::string server_bad_response = "Unable to understand database cluster host state, please fix so state "
    "can be reported correctly.";

// This class wraps up all the requests to the RestAPI server and returns
// some simple responses for reporting into the Tango system. This class
// can only raise awareness of a problem, not diagnose it. On seeing a 
// warning the users are required to investigate the cluster.
class HealthCheck
{
public:

    // enum to simplify the return status
    enum HealthCheckResult
    {
        // no error reported for the given check
        Ok, 

        // a possible problem or something that needs to be looked at
        // has been detected
        Warning, 

        // an error case has been raised and must be looked at immediately
        Error,

        // occurs when the HealthCheck class can not connect to the reporting
        // server
        ConnectionProblem
    };

    // this function attempts to configure the connect to the rest server and
    // test its valid
    bool configure_rest_server_address(const std::string &host, int port, const std::string &root_url);

    // Database host checks. These checks are basically to detect
    // if a server is down or in an unusual state
    void enable_host_checks(bool enable) { _hosts_check_enabled = enable; }
    std::tuple<HealthCheck::HealthCheckResult, std::string> check_hosts() const;

private:

    // check flags
    bool _hosts_check_enabled = false;

    // Rest server to source data from
    std::string _root_url;
    std::string _host;
    int _port;
};

} // namespace HdbppHealthCheck_ns

#endif // _TTS_RUNNER_HPP
